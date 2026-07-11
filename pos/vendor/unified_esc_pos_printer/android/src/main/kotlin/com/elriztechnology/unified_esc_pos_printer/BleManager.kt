package com.elriztechnology.unified_esc_pos_printer

import android.bluetooth.*
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class BleManager(private val context: Context) {

    companion object {
        private val ESC_POS_SERVICE_UUID =
            UUID.fromString("000018f0-0000-1000-8000-00805f9b34fb")
        private val ESC_POS_TX_CHAR_UUID =
            UUID.fromString("00002af1-0000-1000-8000-00805f9b34fb")
    }

    private val bluetoothAdapter: BluetoothAdapter? =
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    private val scanner: BluetoothLeScanner?
        get() = bluetoothAdapter?.bluetoothLeScanner

    private val mainHandler = Handler(Looper.getMainLooper())

    // Scan state
    private var scanEventSink: EventChannel.EventSink? = null
    private val discoveredDevices = mutableListOf<Map<String, String>>()
    private var scanCallback: ScanCallback? = null
    private var scanTimeoutRunnable: Runnable? = null

    // Connection state
    private var gatt: BluetoothGatt? = null
    private var txCharacteristic: BluetoothGattCharacteristic? = null
    private var negotiatedMtu: Int = 20 // safe default (will be updated after MTU negotiation)
    private var writeWithoutResponse: Boolean = false
    private var connectResult: MethodChannel.Result? = null
    private var writeResult: MethodChannel.Result? = null
    private var targetServiceUuid: UUID? = null
    private var targetCharUuid: UUID? = null

    var connectionStateCallback: ((String) -> Unit)? = null

    val scanStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            scanEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            scanEventSink = null
        }
    }

    fun getBondedBleDevices(result: MethodChannel.Result) {
        val adapter = bluetoothAdapter
        if (adapter == null) {
            result.success(emptyList<Map<String, String>>())
            return
        }

        try {
            val bonded = adapter.bondedDevices?.filter { device ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                    device.type == BluetoothDevice.DEVICE_TYPE_LE ||
                            device.type == BluetoothDevice.DEVICE_TYPE_DUAL
                } else {
                    true // Include all if we can't check type
                }
            }?.map { device ->
                mapOf(
                    "deviceId" to device.address,
                    "name" to (device.name ?: device.address)
                )
            } ?: emptyList()
            result.success(bonded)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Cannot access bonded devices", e.message)
        }
    }

    fun startScan(timeoutMs: Long, result: MethodChannel.Result) {
        val s = scanner
        if (s == null) {
            result.error("UNAVAILABLE", "Bluetooth LE scanner not available", null)
            return
        }

        discoveredDevices.clear()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                val device = scanResult.device
                val id = device.address
                if (discoveredDevices.none { it["deviceId"] == id }) {
                    val name = try { device.name } catch (_: SecurityException) { null }
                    
                    discoveredDevices.add(
                        mapOf(
                            "deviceId" to id,
                            "name" to (name ?: id)
                        )
                    )

                    mainHandler.post {
                        scanEventSink?.success(discoveredDevices.toList())
                    }
                }
            }

            override fun onScanFailed(errorCode: Int) {
                mainHandler.post {
                    scanEventSink?.error("SCAN_FAILED", "BLE scan failed with code $errorCode", null)
                }
            }
        }

        try {
            s.startScan(scanCallback)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Bluetooth scan permission denied", e.message)
            return
        }

        // Auto-stop after timeout
        scanTimeoutRunnable = Runnable {
            stopScanInternal()
        }

        mainHandler.postDelayed(scanTimeoutRunnable!!, timeoutMs)

        result.success(null)
    }

    fun stopScan(result: MethodChannel.Result) {
        stopScanInternal()
        result.success(null)
    }

    private fun stopScanInternal() {
        scanTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        scanTimeoutRunnable = null
        scanCallback?.let { cb ->
            try {
                scanner?.stopScan(cb)
            } catch (_: SecurityException) {
                // Already lost permission — ignore
            }
        }
        scanCallback = null
    }

    fun connect(
        deviceId: String,
        timeoutMs: Long,
        serviceUuid: String?,
        characteristicUuid: String?,
        result: MethodChannel.Result
    ) {
        val adapter = bluetoothAdapter
        if (adapter == null) {
            result.error("UNAVAILABLE", "Bluetooth adapter not available", null)
            return
        }

        targetServiceUuid = serviceUuid?.let { UUID.fromString(it) } ?: ESC_POS_SERVICE_UUID
        targetCharUuid = characteristicUuid?.let { UUID.fromString(it) } ?: ESC_POS_TX_CHAR_UUID

        val device: BluetoothDevice
        try {
            device = adapter.getRemoteDevice(deviceId)
        } catch (e: Exception) {
            result.error("INVALID_DEVICE", "Invalid device ID: $deviceId", e.message)
            return
        }

        connectResult = result

        // Timeout handler
        val timeoutRunnable = Runnable {
            if (connectResult != null) {
                connectResult?.error("TIMEOUT", "BLE connection timed out", null)
                connectResult = null
                
                try { gatt?.disconnect(); gatt?.close() } catch (_: SecurityException) {
                    // Ignore — we're disconnecting anyway
                }

                gatt = null
            }
        }
        mainHandler.postDelayed(timeoutRunnable, timeoutMs)

        val gattCallback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    gatt = g
                    try {
                        g.requestMtu(512)
                    } catch (e: SecurityException) {
                        mainHandler.post {
                            mainHandler.removeCallbacks(timeoutRunnable)
                            connectResult?.error("PERMISSION_DENIED", "MTU request denied", e.message)
                            connectResult = null
                        }
                    }
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    mainHandler.post {
                        mainHandler.removeCallbacks(timeoutRunnable)

                        if (connectResult != null) {
                            connectResult?.error("DISCONNECTED", "BLE device disconnected during setup", null)
                            connectResult = null
                        } else {
                            // Remote disconnection after fully connected
                            connectionStateCallback?.invoke("disconnected")
                        }

                        try { g.close() } catch (_: SecurityException) {
                            // Ignore — we're disconnecting anyway
                        }
                        
                        gatt = null
                        txCharacteristic = null
                    }
                }
            }

            override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
                negotiatedMtu = if (status == BluetoothGatt.GATT_SUCCESS) mtu - 3 else 20
                try {
                    g.discoverServices()
                } catch (e: SecurityException) {
                    mainHandler.post {
                        mainHandler.removeCallbacks(timeoutRunnable)
                        connectResult?.error("PERMISSION_DENIED", "Service discovery denied", e.message)
                        connectResult = null
                    }
                }
            }

            override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    mainHandler.post {
                        mainHandler.removeCallbacks(timeoutRunnable)
                        connectResult?.error("SERVICE_DISCOVERY_FAILED", "GATT service discovery failed with status $status", null)
                        connectResult = null
                        try { g.disconnect(); g.close() } catch (_: SecurityException) {}
                        gatt = null
                    }
                    return
                }

                var foundChar: BluetoothGattCharacteristic? = null

                // 1. Try target service/characteristic UUIDs
                val targetService = g.getService(targetServiceUuid)
                if (targetService != null) {
                    val c = targetService.getCharacteristic(targetCharUuid)
                    if (c != null && isWritable(c)) {
                        foundChar = c
                    }
                }

                // 2. Fallback: any writable characteristic
                if (foundChar == null) {
                    for (service in g.services) {
                        for (c in service.characteristics) {
                            if (isWritable(c)) {
                                foundChar = c
                                break
                            }
                        }
                        if (foundChar != null) break
                    }
                }

                mainHandler.post {
                    mainHandler.removeCallbacks(timeoutRunnable)
                    if (foundChar == null) {
                        connectResult?.error("NO_CHARACTERISTIC", "No writable characteristic found", null)
                        connectResult = null
                        try { g.disconnect(); g.close() } catch (_: SecurityException) {}
                        gatt = null
                    } else {
                        txCharacteristic = foundChar
                        // Prefer write-with-response for reliable backpressure; the printer
                        // ACKs each chunk before we send the next, preventing buffer overflow.
                        // Fall back to write-without-response only if that is the sole option.
                        writeWithoutResponse =
                            (foundChar.properties and BluetoothGattCharacteristic.PROPERTY_WRITE) == 0 &&
                            (foundChar.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
                        connectResult?.success(null)
                        connectResult = null
                        connectionStateCallback?.invoke("connected")
                    }
                }
            }

            override fun onCharacteristicWrite(
                g: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                status: Int
            ) {
                mainHandler.post {
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        writeResult?.success(null)
                    } else {
                        writeResult?.error("WRITE_FAILED", "BLE write failed with status $status", null)
                    }
                    writeResult = null
                }
            }
        }

        // Check if device is bonded — use autoConnect=true for bonded devices
        // as they may not be advertising, but the system can connect when they
        // become available.
        val isBonded = try {
            device.bondState == BluetoothDevice.BOND_BONDED
        } catch (_: SecurityException) {
            false
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(context, isBonded, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(context, isBonded, gattCallback)
            }
        } catch (e: SecurityException) {
            mainHandler.removeCallbacks(timeoutRunnable)
            connectResult = null
            result.error("PERMISSION_DENIED", "Bluetooth connect permission denied", e.message)
        }
    }

    fun getMtu(result: MethodChannel.Result) {
        result.success(negotiatedMtu)
    }

    fun supportsWriteWithoutResponse(result: MethodChannel.Result) {
        result.success(writeWithoutResponse)
    }

    fun write(data: ByteArray, withoutResponse: Boolean, result: MethodChannel.Result) {
        val g = gatt
        val char = txCharacteristic
        if (g == null || char == null) {
            result.error("NOT_CONNECTED", "BLE device not connected", null)
            return
        }

        writeResult = result

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Android 13+ uses new writeCharacteristic API
                val writeType = if (withoutResponse)
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                else
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                
                    val writeResult = g.writeCharacteristic(char, data, writeType)
                if (writeResult != BluetoothStatusCodes.SUCCESS) {
                    this.writeResult?.error("WRITE_FAILED", "writeCharacteristic returned $writeResult", null)
                    this.writeResult = null
                }
            } else {
                @Suppress("DEPRECATION")
                char.writeType = if (withoutResponse)
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                else
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                
                @Suppress("DEPRECATION")
                char.value = data
                
                @Suppress("DEPRECATION")
                val success = g.writeCharacteristic(char)
                if (!success) {
                    this.writeResult?.error("WRITE_FAILED", "writeCharacteristic returned false", null)
                    this.writeResult = null
                }
            }
        } catch (e: SecurityException) {
            writeResult?.error("PERMISSION_DENIED", "Bluetooth write permission denied", e.message)
            writeResult = null
        }
    }

    fun disconnect(result: MethodChannel.Result) {
        try {
            gatt?.disconnect()
            gatt?.close()
        } catch (_: SecurityException) {
            // Ignore — we're disconnecting anyway
        }
        
        gatt = null
        txCharacteristic = null
        connectionStateCallback?.invoke("disconnected")
        result.success(null)
    }

    fun dispose() {
        stopScanInternal()

        try {
            gatt?.disconnect()
            gatt?.close()
        } catch (_: SecurityException) {
            // Ignore — we're disposing anyway
        }
        
        gatt = null
        txCharacteristic = null
    }

    private fun isWritable(c: BluetoothGattCharacteristic): Boolean {
        val props = c.properties
        return (props and BluetoothGattCharacteristic.PROPERTY_WRITE) != 0 ||
                (props and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
    }
}

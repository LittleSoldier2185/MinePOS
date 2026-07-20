import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// hide Row: sqlite3 exports its own Row (a query result row), which clashes
// with Flutter's Row widget — this file never needs to name sqlite3's Row
// type directly (query results are indexed by column name, e.g. r['name']).
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../../core/services/app_settings_service.dart';
import '../../core/services/local_server_launcher.dart';
import '../../core/services/mobile_server_launcher.dart';
import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/window/platform_window.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/services/auth_service.dart';
import '../connect/services/connection_service.dart';
import '../manager/services/backup_service.dart';
import '../role_select/role_selection_screen.dart';

enum _RestoreDestination { local, server }

/// A parsed, not-yet-applied backup — either picked as a file or pulled live
/// from another server — along with whatever shop name could be read out of
/// it, shown to the user as a sanity check before actually restoring it.
class _PendingRestore {
  const _PendingRestore({required this.bytes, required this.shopName});
  final List<int> bytes;
  final String? shopName;
}

/// Reached from [ShopSetupChoiceScreen]'s "Restore from Backup" card. Gets a
/// backup ready (from a file or a live pull from another server) via the two
/// tabs below, then — once ready — asks *where* to send it: onto this
/// device (self-hosting, same as the normal Create Shop wizard) or onto a
/// separate server elsewhere on the network by address.
///
/// The local destination is only offered when [_hasLocalShop] is confirmed
/// false (re-checked again, defensively, inside the launchers'
/// `writeRestoredDatabase` itself) — restoring over an existing local shop
/// is deliberately not supported; use Settings' Remove Shop first. The
/// server destination has no such restriction on *this* device — it's
/// gated instead on the *target* server having no shop of its own yet
/// (`GET /health`'s `hasShop`, re-checked server-side too by
/// `POST /admin/restore`), so it can never overwrite a live shop anywhere.
class RestoreShopScreen extends StatefulWidget {
  const RestoreShopScreen({super.key});

  @override
  State<RestoreShopScreen> createState() => _RestoreShopScreenState();
}

class _RestoreShopScreenState extends State<RestoreShopScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);
  bool _checkingShop = true;
  bool _hasLocalShop = false;

  @override
  void initState() {
    super.initState();
    _checkLocalShop();
  }

  Future<void> _checkLocalShop() async {
    final hasShop = isWindowsDesktop
        ? LocalServerLauncher.instance.hasLocalShop()
        : isMobile
            ? await MobileServerLauncher.instance.hasLocalShop()
            : false;
    if (mounted) {
      setState(() {
        _hasLocalShop = hasShop;
        _checkingShop = false;
      });
    }
  }

  bool get _canUseLocal => (isWindowsDesktop || isMobile) && !_hasLocalShop;

  /// Asks where to send [restore], then applies it there. Does nothing
  /// (and doesn't throw) if the user cancels either dialog — the calling
  /// tab just stays on its confirm step, ready to try again.
  Future<void> _applyRestore(_PendingRestore restore) async {
    final destination = await showDialog<_RestoreDestination>(
      context: context,
      builder: (_) => _DestinationPickerDialog(canUseLocal: _canUseLocal),
    );
    if (destination == null || !mounted) return;

    if (destination == _RestoreDestination.local) {
      await _applyLocalRestore(restore);
      return;
    }

    final address = await showDialog<String>(
      context: context,
      builder: (_) => const _RemoteAddressDialog(),
    );
    if (address == null || address.trim().isEmpty || !mounted) return;
    await _applyRemoteRestore(restore, address.trim());
  }

  Future<void> _applyLocalRestore(_PendingRestore restore) async {
    final bool ready;
    if (isWindowsDesktop) {
      await LocalServerLauncher.instance.writeRestoredDatabase(restore.bytes);
      ready = await LocalServerLauncher.instance.ensureRunning();
    } else {
      await MobileServerLauncher.instance.writeRestoredDatabase(restore.bytes);
      ready = await MobileServerLauncher.instance.ensureRunning();
    }
    if (!ready) {
      throw StateError('Server failed to start with the restored data.');
    }
    ServerClient.instance.baseUrl = '127.0.0.1:8080';
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(serverAddress: l10n.welcomeOpenRegisterDescription),
      ),
    );
  }

  /// Pushes [restore] onto the *target* server at [address] over
  /// `POST /admin/restore` — that route is safe to call unauthenticated
  /// because it only ever accepts a restore onto a server with no shop of
  /// its own yet, checked both here (via the same `/health` check
  /// `ConnectScreen` uses) and again, authoritatively, by the server itself.
  Future<void> _applyRemoteRestore(_PendingRestore restore, String address) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await ConnectionService().checkStatus(address);
    if (!status.reachable) throw Exception(l10n.connectFailureError);
    if (status.hasShop) throw Exception(l10n.restoreDestinationServerHasShopError);

    final res = await http
        .post(
          Uri.parse('http://$address/admin/restore'),
          headers: {'Content-Type': 'application/octet-stream'},
          body: restore.bytes,
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('${res.statusCode}: ${res.body}');
    }

    ServerClient.instance.baseUrl = address;
    await AppSettingsService.instance.setLastServerAddress(address);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_checkingShop) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.restoreShopAppBarTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.restoreShopFileTab),
            Tab(text: l10n.restoreShopTransferTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FileRestoreTab(onRestore: _applyRestore),
          _TransferRestoreTab(onRestore: _applyRestore),
        ],
      ),
    );
  }
}

class _DestinationPickerDialog extends StatelessWidget {
  const _DestinationPickerDialog({required this.canUseLocal});
  final bool canUseLocal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SimpleDialog(
      title: Text(l10n.restoreDestinationTitle),
      children: [
        SimpleDialogOption(
          onPressed: canUseLocal ? () => Navigator.pop(context, _RestoreDestination.local) : null,
          child: Row(
            children: [
              Icon(Icons.storage_outlined, size: 18, color: canUseLocal ? AppColors.primary : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.restoreDestinationLocalOption)),
            ],
          ),
        ),
        if (!canUseLocal)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.restoreDestinationLocalUnavailableNote,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _RestoreDestination.server),
          child: Row(
            children: [
              const Icon(Icons.dns_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.restoreDestinationServerOption)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemoteAddressDialog extends StatefulWidget {
  const _RemoteAddressDialog();

  @override
  State<_RemoteAddressDialog> createState() => _RemoteAddressDialogState();
}

class _RemoteAddressDialogState extends State<_RemoteAddressDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.restoreDestinationServerOption),
      content: AppTextField(
        label: l10n.connectServerAddressLabel,
        controller: _controller,
        hintText: l10n.connectServerAddressHint,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.connectButton),
        ),
      ],
    );
  }
}

class _FileRestoreTab extends StatefulWidget {
  const _FileRestoreTab({required this.onRestore});
  final Future<void> Function(_PendingRestore restore) onRestore;

  @override
  State<_FileRestoreTab> createState() => _FileRestoreTabState();
}

class _FileRestoreTabState extends State<_FileRestoreTab> {
  bool _busy = false;
  String? _error;
  String? _pickedPath;
  _PendingRestore? _pending;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _pending = null;
      _pickedPath = null;
    });
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final pending = await _validate(path);
      if (!mounted) return;
      setState(() {
        _pickedPath = path;
        _pending = pending;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.restoreShopInvalidFileError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the picked file read-only and checks it actually looks like a
  /// MinePOS backup (has the tables every real snapshot has) before this
  /// screen lets the user act on it at all — guards against picking an
  /// unrelated file and corrupting this device's fresh setup with garbage.
  Future<_PendingRestore> _validate(String path) async {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'] as String)
          .toSet();
      if (!tables.contains('shop_config') || !tables.contains('users')) {
        throw const FormatException('Not a MinePOS backup');
      }
      String? shopName;
      final rows = db.select('SELECT shop_name FROM shop_config WHERE id = 1');
      if (rows.isNotEmpty) shopName = rows.first['shop_name'] as String?;
      final bytes = await File(path).readAsBytes();
      return _PendingRestore(bytes: bytes, shopName: shopName);
    } finally {
      db.dispose();
    }
  }

  Future<void> _confirm() async {
    final pending = _pending;
    if (pending == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // onRestore itself navigates away on success (it knows the chosen
      // destination and picks the right next screen) — cancelling the
      // destination/address dialogs just returns here with nothing changed,
      // in which case we fall through and reset _busy below.
      await widget.onRestore(pending);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.restoreShopFileTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.restoreShopFileInstructions,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: Text(l10n.restoreShopChooseFileButton),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
          ],
          if (_pending != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.terracottaLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.restoreShopFoundShopLabel(_pending!.shopName ?? l10n.emDash),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pickedPath ?? '',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _confirm,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      )
                    : Text(l10n.restoreShopConfirmButton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferRestoreTab extends StatefulWidget {
  const _TransferRestoreTab({required this.onRestore});
  final Future<void> Function(_PendingRestore restore) onRestore;

  @override
  State<_TransferRestoreTab> createState() => _TransferRestoreTabState();
}

class _TransferRestoreTabState extends State<_TransferRestoreTab> {
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _connectionService = ConnectionService();
  final _authService = AuthService();

  bool _addressConfirmed = false;
  bool _busy = false;
  String? _error;

  // True once this tab has successfully logged into the OLD server (so
  // ServerClient.instance is temporarily pointed there) but the restore
  // hasn't completed yet — used so leaving the screen mid-flow doesn't
  // strand the app pointed at someone else's server.
  bool _loggedIntoOldServer = false;

  @override
  void initState() {
    super.initState();
    AppSettingsService.instance.getDeviceName().then((name) {
      if (mounted && name != null) _deviceNameController.text = name;
    });
  }

  @override
  void dispose() {
    if (_loggedIntoOldServer) ServerClient.instance.clear();
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _checkAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = l10n.connectEmptyAddressError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final status = await _connectionService.checkStatus(address);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!status.reachable) {
      setState(() => _error = l10n.connectFailureError);
      return;
    }
    if (!status.hasShop) {
      setState(() => _error = l10n.connectNoShopError);
      return;
    }
    setState(() => _addressConfirmed = true);
  }

  Future<void> _signInAndTransfer() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final deviceName = _deviceNameController.text.trim();
    if (username.isEmpty || password.isEmpty || deviceName.isEmpty) {
      setState(() => _error = l10n.restoreShopTransferFieldsRequiredError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    // Point this device's connection at the OLD server just long enough to
    // authenticate and pull the backup — cleared (see dispose/below) the
    // moment either step finishes, one way or the other.
    ServerClient.instance.baseUrl = _addressController.text.trim();
    final auth = await _authService.login(username, password, deviceName);
    if (!auth.success) {
      if (!mounted) return;
      ServerClient.instance.clear();
      setState(() {
        _busy = false;
        _error = l10n.restoreShopTransferLoginError;
      });
      return;
    }
    _loggedIntoOldServer = true;

    try {
      final bytes = await BackupService().fetchBackupBytes();
      // Done talking to the old server — never leave this device pointed at
      // it, whether or not the restore that follows succeeds.
      ServerClient.instance.clear();
      _loggedIntoOldServer = false;

      // onRestore asks where to send it and navigates away on success —
      // cancelling that dialog just returns here with nothing changed.
      await widget.onRestore(_PendingRestore(bytes: bytes, shopName: null));
    } catch (e) {
      if (_loggedIntoOldServer) {
        ServerClient.instance.clear();
        _loggedIntoOldServer = false;
      }
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.restoreShopTransferTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.restoreShopTransferInstructions,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: l10n.connectServerAddressLabel,
            controller: _addressController,
            hintText: l10n.connectServerAddressHint,
            enabled: !_addressConfirmed,
          ),
          if (!_addressConfirmed) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _checkAddress,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.connectButton),
              ),
            ),
          ],
          if (_addressConfirmed) ...[
            const SizedBox(height: 20),
            Text(l10n.restoreShopOldOwnerLoginLabel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 12),
            AppTextField(
              label: l10n.deviceNameLabel,
              controller: _deviceNameController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.usernameLabel,
              controller: _usernameController,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.passwordLabel,
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _signInAndTransfer,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      )
                    : Text(l10n.restoreShopTransferButton),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.terracottaDark, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

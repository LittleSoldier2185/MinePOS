// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'MinePOS';

  @override
  String get appTagline => 'ระบบขายหน้าร้านร้านกาแฟ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get delete => 'ลบ';

  @override
  String get remove => 'นำออก';

  @override
  String get total => 'ยอดรวม';

  @override
  String get change => 'เงินทอน';

  @override
  String get cash => 'เงินสด';

  @override
  String get promptpay => 'พร้อมเพย์';

  @override
  String get bluetooth => 'บลูทูธ';

  @override
  String get usb => 'USB';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get next => 'ถัดไป';

  @override
  String get newOrderButton => 'ออร์เดอร์ใหม่';

  @override
  String get reportsLabel => 'รายงาน';

  @override
  String get staffLabel => 'พนักงาน';

  @override
  String get settingsLabel => 'ตั้งค่า';

  @override
  String get menuLabel => 'เมนู';

  @override
  String get orderHistoryLabel => 'ประวัติออร์เดอร์';

  @override
  String get revenueLabel => 'รายได้';

  @override
  String get avgOrderLabel => 'เฉลี่ยต่อออร์เดอร์';

  @override
  String get usernameLabel => 'ชื่อผู้ใช้';

  @override
  String get usernameRequiredValidator => 'กรุณากรอกชื่อผู้ใช้';

  @override
  String get passwordLabel => 'รหัสผ่าน';

  @override
  String get passwordRequiredValidator => 'กรุณากรอกรหัสผ่าน';

  @override
  String get confirmPasswordLabel => 'ยืนยันรหัสผ่าน';

  @override
  String get passwordMismatchValidator => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get roleLabel => 'บทบาท';

  @override
  String get employeeRoleDisplay => 'พนักงาน';

  @override
  String get managerRoleDisplay => 'ผู้จัดการ';

  @override
  String get ownerRoleDisplay => 'เจ้าของร้าน';

  @override
  String get connectionModeLocalLabel => 'โหมดออฟไลน์ (เครื่องนี้)';

  @override
  String get connectionModeCloudLabel => 'โหมดออนไลน์';

  @override
  String get optionalHint => 'ไม่บังคับ';

  @override
  String get emDash => '—';

  @override
  String get addItemLabel => 'เพิ่มเมนู';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get welcomeAppTitle => 'MINEPOS';

  @override
  String get welcomeOpenRegisterButton => 'เปิดเครื่องขาย';

  @override
  String get welcomeOpenRegisterDescription => 'เครื่องนี้ — โหมดออฟไลน์';

  @override
  String get welcomeOpenRegisterFailedMessage =>
      'ไม่สามารถเริ่มเซิร์ฟเวอร์ภายในเครื่องได้ กรุณาใช้ \"เชื่อมต่อเซิร์ฟเวอร์\" แทน หรือตรวจสอบว่าติดตั้ง MinePOS ครบถ้วนแล้ว';

  @override
  String get localServerLaunchFailedError =>
      'ไม่สามารถเริ่มเซิร์ฟเวอร์ภายในเครื่องได้';

  @override
  String get welcomeOpenRegisterUnavailableNote =>
      'ใช้ได้เฉพาะบางแพลตฟอร์มเท่านั้น กรุณาใช้ \"เชื่อมต่อเซิร์ฟเวอร์\" แทน';

  @override
  String get welcomeOrDivider => 'หรือ';

  @override
  String get welcomeConnectServerButton => 'เชื่อมต่อเซิร์ฟเวอร์';

  @override
  String get welcomeCreateShopButton => 'สร้างร้านใหม่';

  @override
  String get welcomeCreateShopUnavailableNote =>
      'อุปกรณ์นี้ตั้งค่าร้านไว้แล้ว กรุณาใช้ \"เปิดเครื่องขาย\" เพื่อเข้าสู่ระบบ';

  @override
  String get shopAlreadyExistsLocalError =>
      'อุปกรณ์นี้ตั้งค่าร้านไว้แล้ว กรุณาใช้ \"เปิดเครื่องขาย\" เพื่อเข้าสู่ระบบแทน';

  @override
  String get shopAlreadyExistsRemoteError =>
      'เซิร์ฟเวอร์นี้ตั้งค่าร้านไว้แล้ว กรุณาให้เจ้าของร้านเข้าสู่ระบบให้คุณแทนการสร้างร้านใหม่';

  @override
  String get welcomeVersionInfo => 'v1.0 · โฮสต์เองหรือใช้คลาวด์';

  @override
  String get loginScreenTitle => 'เข้าสู่ระบบ';

  @override
  String loginConnectedTo(String serverAddress) {
    return 'เชื่อมต่อกับ $serverAddress';
  }

  @override
  String get usernameOrEmailLabel => 'ชื่อผู้ใช้ / อีเมล';

  @override
  String get deviceNameLabel => 'ชื่ออุปกรณ์';

  @override
  String get deviceNameHint => 'เช่น เครื่องที่ 1, เคาน์เตอร์หน้าร้าน';

  @override
  String get deviceNameRequiredValidator => 'กรุณากรอกชื่ออุปกรณ์';

  @override
  String get defaultDeviceNameOnSetup => 'เครื่องหลัก';

  @override
  String get rememberMeLabel => 'จดจำฉันไว้';

  @override
  String get loginForgotPasswordLink => 'ลืมรหัสผ่าน';

  @override
  String get loginErrorMessage => 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get loginSignInButton => 'เข้าสู่ระบบ';

  @override
  String get loginWelcomeMessage => 'ยินดีต้อนรับกลับ!';

  @override
  String get forgotPasswordTitle => 'ลืมรหัสผ่าน';

  @override
  String get forgotPasswordInstructions =>
      'กรอกชื่อผู้ใช้หรืออีเมลเพื่อรับรหัสใช้ครั้งเดียว';

  @override
  String get forgotPasswordValidator => 'กรุณากรอกข้อมูลนี้';

  @override
  String get forgotPasswordErrorMessage =>
      'ไม่พบบัญชีที่ใช้ชื่อผู้ใช้หรืออีเมลนี้';

  @override
  String get forgotPasswordSendCodeButton => 'ส่งรหัส';

  @override
  String get forgotPasswordBackLink => 'กลับไปหน้าเข้าสู่ระบบ';

  @override
  String get otpVerificationTitle => 'กรอกรหัส';

  @override
  String otpVerificationInstructions(String username) {
    return 'รหัส 6 หลักถูกส่งไปยังอีเมล\nที่ผูกกับ $username แล้ว';
  }

  @override
  String get otpVerificationIncompleteError => 'กรุณากรอกรหัส 6 หลักให้ครบ';

  @override
  String get otpVerificationInvalidError =>
      'รหัสไม่ถูกต้องหรือหมดอายุ กรุณาลองใหม่อีกครั้ง';

  @override
  String get otpVerificationSuccessMessage => 'ส่งรหัสใหม่แล้ว';

  @override
  String get otpVerificationVerifyButton => 'ยืนยัน';

  @override
  String get otpVerificationResendButton => 'ส่งรหัสอีกครั้ง';

  @override
  String get resetPasswordTitle => 'รหัสผ่านใหม่';

  @override
  String get resetPasswordInstructions =>
      'ตั้งรหัสผ่านที่ปลอดภัยสำหรับบัญชีของคุณ';

  @override
  String get resetPasswordNewPasswordLabel => 'รหัสผ่านใหม่';

  @override
  String get resetPasswordLengthValidator => 'ต้องมีอย่างน้อย 8 ตัวอักษร';

  @override
  String get resetPasswordConfirmEmptyValidator => 'กรุณายืนยันรหัสผ่าน';

  @override
  String get resetPasswordErrorMessage =>
      'รีเซ็ตไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';

  @override
  String get resetPasswordSuccessMessage =>
      'รีเซ็ตรหัสผ่านแล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่';

  @override
  String get resetPasswordButton => 'รีเซ็ตรหัสผ่าน';

  @override
  String get connectAppBarTitle => 'เชื่อมต่อเซิร์ฟเวอร์';

  @override
  String get connectTabWifi => 'ไวไฟนี้';

  @override
  String get connectTabManual => 'กรอกเอง';

  @override
  String get connectManualTitle => 'กรอกที่อยู่เซิร์ฟเวอร์';

  @override
  String get connectManualInstructions =>
      'สอบถามที่อยู่ของโฮสต์ MinePOS จากผู้ดูแลระบบ';

  @override
  String get connectMixedContentWarning =>
      'การค้นหาผ่านไวไฟใช้ไม่ได้บนเว็บเบราว์เซอร์ หากที่อยู่โฮสต์ของคุณใช้ http:// และหน้านี้โหลดผ่าน https:// เบราว์เซอร์อาจบล็อกการเชื่อมต่อเนื่องจากเป็นเนื้อหาผสม';

  @override
  String get connectServerAddressLabel => 'ที่อยู่เซิร์ฟเวอร์';

  @override
  String get connectServerAddressHint => '192.168.1.10:8080';

  @override
  String get connectEmptyAddressError => 'กรุณากรอกที่อยู่เซิร์ฟเวอร์';

  @override
  String get connectFailureError =>
      'เชื่อมต่อไม่สำเร็จ กรุณาตรวจสอบที่อยู่แล้วลองใหม่';

  @override
  String get connectNoShopError =>
      'เซิร์ฟเวอร์นี้ยังไม่ได้ตั้งค่าร้าน กรุณาใช้ \"สร้างร้านใหม่\" เพื่อตั้งค่าก่อน';

  @override
  String get connectButton => 'เชื่อมต่อ';

  @override
  String get connectWifiTitle => 'ร้านค้าบนไวไฟนี้';

  @override
  String get connectWifiInstructions =>
      'ตรวจสอบว่าอุปกรณ์นี้อยู่ในไวไฟเดียวกับโฮสต์ MinePOS';

  @override
  String get connectScanButton => 'ค้นหาร้านค้า';

  @override
  String get connectScanningLabel => 'กำลังค้นหา...';

  @override
  String get connectNoShopsFound => 'ยังไม่พบร้านค้า';

  @override
  String get roleSelectionTitle => 'อุปกรณ์นี้ใช้ทำอะไร?';

  @override
  String get roleSelectionInstructions =>
      'ขั้นตอนถัดไปคุณจะเลือกเซิร์ฟเวอร์ที่จะเชื่อมต่อ';

  @override
  String get roleSelectionCashierTitle => 'แคชเชียร์ / ผู้จัดการ';

  @override
  String get roleSelectionCashierSubtitle =>
      'รับออร์เดอร์และจัดการร้าน — เข้าสู่ระบบตามปกติ';

  @override
  String get roleSelectionKitchenTitle => 'จอครัว';

  @override
  String get roleSelectionKitchenSubtitle =>
      'หน้าจอครัวโดยเฉพาะ — เข้าสู่ระบบแล้วอยู่ที่หน้าจอนี้';

  @override
  String get roleSelectionCustomerTitle => 'จอลูกค้า';

  @override
  String get roleSelectionCustomerSubtitle =>
      'หันหน้าเข้าหาลูกค้า แสดงออร์เดอร์แบบสด — ไม่ต้องเข้าสู่ระบบ';

  @override
  String get shopSetupChoiceTitle => 'ตั้งค่าอุปกรณ์นี้';

  @override
  String get shopSetupChoiceInstructions =>
      'เริ่มร้านใหม่ทั้งหมด หรือย้ายร้านเดิมจากอุปกรณ์อื่นมาที่นี่';

  @override
  String get shopSetupChoiceFreshTitle => 'เริ่มใหม่';

  @override
  String get shopSetupChoiceFreshSubtitle => 'ตั้งค่าร้านใหม่ทั้งหมดตั้งแต่ต้น';

  @override
  String get shopSetupChoiceRestoreTitle => 'กู้คืนจากไฟล์สำรอง';

  @override
  String get shopSetupChoiceRestoreSubtitle =>
      'นำข้อมูลร้านเดิมมาไว้ที่อุปกรณ์นี้';

  @override
  String get restoreShopAppBarTitle => 'กู้คืนร้าน';

  @override
  String get restoreShopFileTab => 'ไฟล์สำรอง';

  @override
  String get restoreShopTransferTab => 'อุปกรณ์อื่น';

  @override
  String get restoreShopFileTitle => 'กู้คืนจากไฟล์สำรอง';

  @override
  String get restoreShopFileInstructions =>
      'เลือกไฟล์สำรองที่ส่งออกจากเมนูตั้งค่าบนอุปกรณ์เดิม';

  @override
  String get restoreShopChooseFileButton => 'เลือกไฟล์สำรอง';

  @override
  String get restoreShopInvalidFileError =>
      'ไฟล์นี้ไม่ใช่ไฟล์สำรองของ MinePOS กรุณาเลือกไฟล์อื่น';

  @override
  String restoreShopFoundShopLabel(String shopName) {
    return 'พบร้าน: $shopName';
  }

  @override
  String get restoreShopConfirmButton => 'กู้คืนร้านนี้';

  @override
  String get restoreShopTransferTitle => 'กู้คืนจากอุปกรณ์อื่น';

  @override
  String get restoreShopTransferInstructions =>
      'กรอกที่อยู่เซิร์ฟเวอร์ที่กำลังใช้งานร้านที่ต้องการย้ายมาที่นี่';

  @override
  String get restoreShopOldOwnerLoginLabel =>
      'เข้าสู่ระบบในฐานะเจ้าของร้านนั้นเพื่อดำเนินการต่อ';

  @override
  String get restoreShopTransferButton => 'เข้าสู่ระบบและย้ายข้อมูล';

  @override
  String get restoreShopTransferFieldsRequiredError =>
      'ต้องกรอกชื่ออุปกรณ์ ชื่อผู้ใช้ และรหัสผ่านให้ครบ';

  @override
  String get restoreShopTransferLoginError =>
      'เข้าสู่ระบบเซิร์ฟเวอร์นั้นไม่สำเร็จ กรุณาตรวจสอบชื่อผู้ใช้และรหัสผ่าน';

  @override
  String get restoreDestinationTitle => 'ต้องการกู้คืนไปที่ไหน?';

  @override
  String get restoreDestinationLocalOption => 'อุปกรณ์นี้ (จัดเก็บในเครื่อง)';

  @override
  String get restoreDestinationLocalUnavailableNote =>
      'ไม่สามารถใช้งานได้ — แพลตฟอร์มนี้โฮสต์เองไม่ได้ หรืออุปกรณ์นี้มีร้านอยู่แล้ว';

  @override
  String get restoreDestinationServerOption => 'เซิร์ฟเวอร์อื่น (ระบุ IP)';

  @override
  String get restoreDestinationServerHasShopError =>
      'เซิร์ฟเวอร์นั้นมีร้านตั้งค่าไว้แล้ว การกู้คืนใช้ได้เฉพาะเซิร์ฟเวอร์ที่ยังไม่เคยตั้งค่ามาก่อน';

  @override
  String get createShopAppBarTitle => 'สร้างร้านใหม่';

  @override
  String stepIndicator(int stepNumber, int stepCount) {
    return 'ขั้นตอนที่ $stepNumber จาก $stepCount';
  }

  @override
  String get finishSetupButton => 'เสร็จสิ้นการตั้งค่า';

  @override
  String get shopCreatedDefaultTitle => 'สร้างร้านเรียบร้อยแล้ว!';

  @override
  String shopReadyTitle(String shopName) {
    return '$shopName พร้อมใช้งานแล้ว!';
  }

  @override
  String get shopDetailsStepTitle => 'ข้อมูลร้าน';

  @override
  String get shopDetailsStepSubtitle => 'บอกเราเกี่ยวกับร้านของคุณ';

  @override
  String get shopLogoTapInstruction => 'แตะเพื่อเพิ่มโลโก้';

  @override
  String get shopNameFieldLabel => 'ชื่อร้าน';

  @override
  String get shopNameFieldHint => 'Cozy Cafe';

  @override
  String get shopNameValidatorError => 'กรุณากรอกชื่อร้าน';

  @override
  String get emailFieldLabel => 'อีเมล';

  @override
  String get emailFieldHint => 'shop@example.com';

  @override
  String get emailRequiredValidatorError => 'กรุณากรอกอีเมล';

  @override
  String get emailInvalidValidatorError => 'กรุณากรอกอีเมลให้ถูกต้อง';

  @override
  String get addressFieldLabel => 'ที่อยู่';

  @override
  String get taxIdFieldLabel => 'เลขประจำตัวผู้เสียภาษี';

  @override
  String get receiptFooterFieldLabel => 'ข้อความท้ายใบเสร็จ';

  @override
  String get receiptFooterFieldHint => 'ไม่บังคับ เช่น \"ขอบคุณค่ะ!\"';

  @override
  String get promptpayIdFieldLabel => 'หมายเลขพร้อมเพย์';

  @override
  String get promptpayIdFieldHint => 'เบอร์มือถือ หรือเลขประจำตัว 13 หลัก';

  @override
  String get promptpayIdValidatorError =>
      'กรอกเบอร์มือถือ 10 หลัก หรือเลขประจำตัว 13 หลัก';

  @override
  String get promptpayLabelFieldLabel => 'ข้อความใต้ QR';

  @override
  String get promptpayLabelFieldHint => 'ไม่บังคับ เช่น ชื่อร้าน';

  @override
  String get shopDetailsSectionLabel => 'ข้อมูลร้าน';

  @override
  String get shopDetailsSavedMessage => 'บันทึกข้อมูลร้านแล้ว';

  @override
  String shopSetupFailedMessage(String error) {
    return 'ตั้งค่าไม่สำเร็จ: $error';
  }

  @override
  String get adminAccountStepTitle => 'บัญชีผู้ดูแลระบบคนแรก';

  @override
  String get adminAccountStepSubtitle => 'บัญชีนี้เข้าถึง MinePOS ได้ทุกส่วน';

  @override
  String get passwordMinLengthValidatorError => 'อย่างน้อย 6 ตัวอักษร';

  @override
  String get connectionModeStepTitle => 'รูปแบบการเชื่อมต่อ';

  @override
  String get connectionModeStepSubtitle => 'ร้านนี้จะทำงานแบบไหน?';

  @override
  String get localConnectionModeSubtitleWindows =>
      'ไม่ต้องใช้อินเทอร์เน็ต ข้อมูลอยู่ในพีซีเครื่องนี้ อุปกรณ์อื่นเชื่อมต่อผ่านไวไฟ';

  @override
  String get localConnectionModeSubtitleOther =>
      'ใช้ได้เฉพาะแอปเดสก์ท็อป Windows เท่านั้น';

  @override
  String get localConnectionModeSubtitleMobile =>
      'ไม่ต้องใช้อินเทอร์เน็ต ข้อมูลอยู่ในอุปกรณ์นี้เท่านั้น อุปกรณ์อื่นเชื่อมต่อไม่ได้';

  @override
  String get cloudConnectionModeSubtitle =>
      'เชื่อมต่อกับเซิร์ฟเวอร์ที่ทำงานอยู่ที่อื่นแล้ว ด้วยที่อยู่เซิร์ฟเวอร์';

  @override
  String get printerSetupStepTitle => 'ตั้งค่าเครื่องพิมพ์';

  @override
  String get printerSetupStepSubtitle =>
      'เลือกวิธีพิมพ์ใบเสร็จ เปลี่ยนภายหลังได้';

  @override
  String get bluetoothPrinterOptionSubtitle =>
      'จับคู่เครื่องพิมพ์ความร้อนแบบบลูทูธ';

  @override
  String get usbPrinterOptionSubtitle => 'เชื่อมต่อเครื่องพิมพ์ความร้อนแบบ USB';

  @override
  String get skipPrinterOptionTitle => 'ข้ามไปก่อน';

  @override
  String get skipPrinterOptionSubtitle =>
      'ตั้งค่าเครื่องพิมพ์ภายหลังได้จากหน้าตั้งค่า';

  @override
  String get printerDiscoveryNote =>
      'แตะพิมพ์บนใบเสร็จเพื่อค้นหาเครื่องพิมพ์ที่จับคู่ไว้ — ตรวจสอบว่าเปิดเครื่องและอยู่ในระยะ';

  @override
  String get setupSummaryStepTitle => 'ตรวจสอบและเสร็จสิ้น';

  @override
  String get setupSummaryStepSubtitle => 'ตรวจสอบข้อมูลให้ถูกต้องก่อนสร้างร้าน';

  @override
  String get summaryRowLabelAdminUsername => 'ชื่อผู้ใช้ผู้ดูแลระบบ';

  @override
  String get summaryRowLabelConnectionMode => 'รูปแบบการเชื่อมต่อ';

  @override
  String get summaryRowLabelPrinter => 'เครื่องพิมพ์';

  @override
  String get summaryPrinterSkippedLabel => 'ข้ามไปก่อน';

  @override
  String get clearOrderDialogTitle => 'ล้างออร์เดอร์?';

  @override
  String get clearOrderDialogContent =>
      'นำสินค้าทั้งหมดออกจากออร์เดอร์นี้หรือไม่?';

  @override
  String get clearButton => 'ล้าง';

  @override
  String get newOrderAppBarTitle => 'ออร์เดอร์ใหม่';

  @override
  String get clearOrderTooltip => 'ล้างออร์เดอร์';

  @override
  String get orderHistoryTooltip => 'ประวัติออร์เดอร์';

  @override
  String get cartTabLabel => 'ตะกร้า';

  @override
  String orderNumberLabel(String number) {
    return 'ออร์เดอร์ #$number';
  }

  @override
  String get emptyCartMessage => 'แตะสินค้า\nเพื่อเพิ่มลงในออร์เดอร์';

  @override
  String get proceedToPayButton => 'ไปหน้าชำระเงิน';

  @override
  String get heldOrderResumedMessage => 'กู้คืนออร์เดอร์ที่พักไว้แล้ว';

  @override
  String get searchMenuHint => 'ค้นหาเมนู';

  @override
  String get noSearchResultsMessage => 'ไม่พบสินค้าที่ตรงกัน';

  @override
  String get orderNoteHint => 'โน้ตถึงครัว (เช่น ไม่ใส่นม) — ไม่พิมพ์ในใบเสร็จ';

  @override
  String get comboBundlesTitle => 'ชุดคอมโบ';

  @override
  String comboPriceLabel(String price) {
    return 'ราคาชุด $price';
  }

  @override
  String get paymentAppBarTitle => 'ชำระเงิน';

  @override
  String get orderSummaryHeader => 'สรุปออร์เดอร์';

  @override
  String get amountReceivedHeader => 'จำนวนเงินที่รับ';

  @override
  String get amountLessThanTotalError => 'จำนวนเงินน้อยกว่ายอดรวม';

  @override
  String get promptpayConfigMessage =>
      'ตั้งค่าหมายเลขพร้อมเพย์\nในหน้าตั้งค่าเพื่อเปิดใช้งาน';

  @override
  String get tapToEnlargeQrMessage => 'แตะเพื่อขยาย';

  @override
  String get scanQrToPayMessage => 'สแกน QR เพื่อชำระเงิน';

  @override
  String confirmPaymentButton(String total) {
    return 'ยืนยันการชำระเงิน  •  $total';
  }

  @override
  String receiptAppBarTitle(String orderNumber) {
    return 'ใบเสร็จ $orderNumber';
  }

  @override
  String get businessName => 'MinePOS Coffee';

  @override
  String get receiptThankYouMessage => 'ขอบคุณสำหรับการสั่งซื้อ!';

  @override
  String get receiptOrderLabel => 'ออร์เดอร์';

  @override
  String get receiptDateLabel => 'วันที่';

  @override
  String get receiptPaymentLabel => 'การชำระเงิน';

  @override
  String get receiptClosingMessage => '— แล้วพบกันใหม่! —';

  @override
  String get printButtonLabel => 'พิมพ์';

  @override
  String get printingInProgressMessage => 'กำลังพิมพ์…';

  @override
  String get printSuccessMessage => 'ส่งใบเสร็จไปยังเครื่องพิมพ์แล้ว';

  @override
  String get printNoPrinterMessage =>
      'ไม่พบเครื่องพิมพ์ ตรวจสอบว่าเปิดเครื่องและอยู่ในระยะ';

  @override
  String printFailedMessage(String error) {
    return 'พิมพ์ไม่สำเร็จ: $error';
  }

  @override
  String get printSkippedMessage =>
      'ยังไม่ได้เลือกเครื่องพิมพ์ — ตั้งค่าได้ที่หน้าตั้งค่า';

  @override
  String get orderHistoryAppBarTitle => 'ประวัติออร์เดอร์';

  @override
  String get noOrdersMessage => 'ยังไม่มีออร์เดอร์';

  @override
  String get noMenuItemsMessage =>
      'ยังไม่มีรายการเมนู กรุณาเพิ่มในหน้าจัดการเมนู';

  @override
  String orderItemsSummary(int count, String paymentMethod) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0  •  $paymentMethod';
  }

  @override
  String get exitCustomerDisplayTitle => 'ออกจากจอลูกค้า?';

  @override
  String get exitCustomerDisplayContent => 'จะกลับไปยังหน้าต้อนรับ';

  @override
  String get exitButton => 'ออก';

  @override
  String get welcomeToMinePosMessage => 'ยินดีต้อนรับสู่ MinePOS';

  @override
  String get orderWillAppearMessage => 'ออร์เดอร์ของคุณจะแสดงที่นี่';

  @override
  String get selectStationTitle => 'เลือกเครื่อง';

  @override
  String get noStationsOnlineMessage =>
      'ยังไม่มีเครื่องออนไลน์ กรุณาเปิดเครื่องขายและเริ่มออร์เดอร์';

  @override
  String get customerDisplayOrderLabel => 'ออร์เดอร์ของคุณ';

  @override
  String customerDisplayOrderWithNumber(String orderNumber) {
    return 'ออร์เดอร์ #$orderNumber';
  }

  @override
  String get thankYouMessage => 'ขอบคุณค่ะ!';

  @override
  String totalPaidLabel(String amount) {
    return 'ยอดชำระ: $amount';
  }

  @override
  String changeMessageLabel(String amount) {
    return 'เงินทอน: $amount';
  }

  @override
  String get goodMorningGreeting => 'สวัสดีตอนเช้า';

  @override
  String get goodAfternoonGreeting => 'สวัสดีตอนบ่าย';

  @override
  String get goodEveningGreeting => 'สวัสดีตอนเย็น';

  @override
  String get signOutDialogTitle => 'ออกจากระบบ?';

  @override
  String get signOutDialogContent => 'คุณจะถูกนำกลับไปยังหน้าต้อนรับ';

  @override
  String get desktopDashboardNavLabel => 'แดชบอร์ด';

  @override
  String get menuMgmtNavLabel => 'จัดการเมนู';

  @override
  String get kitchenNavLabel => 'ครัว';

  @override
  String get defaultAdminUsername => 'ผู้ดูแลระบบ';

  @override
  String get mobileBottomNavHome => 'หน้าแรก';

  @override
  String get mobileBottomNavOrders => 'ออร์เดอร์';

  @override
  String get mobileBottomNavMore => 'เพิ่มเติม';

  @override
  String greetingWithName(String greeting) {
    return '$greeting คุณแอดมิน';
  }

  @override
  String get homeOrdersTodayStat => 'ออร์เดอร์วันนี้';

  @override
  String get recentOrdersHeader => 'ออร์เดอร์ล่าสุด';

  @override
  String get viewAllOrdersLink => 'ดูทั้งหมด →';

  @override
  String get noOrdersTodayMessage => 'วันนี้ยังไม่มีออร์เดอร์';

  @override
  String get recentOrderQrLabel => 'QR';

  @override
  String get menuManagementTitle => 'จัดการเมนู';

  @override
  String get addItemTooltip => 'เพิ่มเมนู';

  @override
  String get sortMenuTooltip => 'จัดเรียง';

  @override
  String get sortDefaultOption => 'ลำดับเริ่มต้น';

  @override
  String get sortNameAscOption => 'ชื่อ (ก-ฮ)';

  @override
  String get sortNameDescOption => 'ชื่อ (ฮ-ก)';

  @override
  String get sortPriceAscOption => 'ราคา (น้อยไปมาก)';

  @override
  String get sortPriceDescOption => 'ราคา (มากไปน้อย)';

  @override
  String get manageCategoriesTooltip => 'จัดการหมวดหมู่';

  @override
  String get manageCategoriesTitle => 'หมวดหมู่';

  @override
  String get manageCategoriesHint =>
      'ลากเพื่อจัดลำดับใหม่ แตะไอคอนดินสอเพื่อเปลี่ยนชื่อหมวดหมู่ — สินค้าทุกชิ้นในหมวดนี้จะย้ายไปใช้ชื่อใหม่';

  @override
  String get renameCategoryTitle => 'เปลี่ยนชื่อหมวดหมู่';

  @override
  String get renameCategoryLabel => 'ชื่อหมวดหมู่';

  @override
  String get renameCategoryEmptyError => 'กรุณาระบุชื่อหมวดหมู่';

  @override
  String get renameCategorySnackbar => 'เปลี่ยนชื่อหมวดหมู่แล้ว';

  @override
  String get noItemsEmpty => 'ไม่มีรายการในหมวดหมู่นี้';

  @override
  String get deleteItemTitle => 'ลบเมนู?';

  @override
  String deleteItemContent(String itemName) {
    return 'นำ \"$itemName\" ออกจากเมนูหรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้';
  }

  @override
  String deleteItemSnackbar(String itemName) {
    return 'ลบ \"$itemName\" แล้ว';
  }

  @override
  String get editItemFormTitle => 'แก้ไขเมนู';

  @override
  String get itemNameLabel => 'ชื่อเมนู (อังกฤษ)';

  @override
  String get itemNameHint => 'เช่น คาราเมล ลาเต้';

  @override
  String get itemNameRequired => 'กรุณากรอกชื่อเมนู';

  @override
  String get itemNameThLabel => 'ชื่อเมนู (ไทย)';

  @override
  String get itemNameThHint => 'ไม่บังคับ เช่น คาราเมลลาเต้';

  @override
  String get categoryLabel => 'หมวดหมู่';

  @override
  String get categoryHint => 'เช่น กาแฟ';

  @override
  String get categoryRequired => 'กรุณากรอกหมวดหมู่';

  @override
  String get priceLabel => 'ราคา';

  @override
  String get priceHint => '0';

  @override
  String get priceRequired => 'กรุณากรอกราคา';

  @override
  String get priceInvalid => 'กรุณากรอกราคาที่ถูกต้อง';

  @override
  String get availableLabel => 'แสดงในเมนู';

  @override
  String get hasSweetnessLabel => 'ถามระดับความหวาน';

  @override
  String get saveChangesButton => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get selectSweetnessTitle => 'ระดับความหวาน';

  @override
  String get sweetnessLess => 'หวานน้อย';

  @override
  String get sweetnessNormal => 'หวานปกติ';

  @override
  String get sweetnessSweet => 'หวานมาก';

  @override
  String get todayRange => 'วันนี้';

  @override
  String get yesterdayRange => 'เมื่อวาน';

  @override
  String get last7Range => '7 วันล่าสุด';

  @override
  String get last30Range => '30 วันล่าสุด';

  @override
  String get allTimeRange => 'ทั้งหมด';

  @override
  String get monthRange => 'เลือกเดือน…';

  @override
  String get customRange => 'กำหนดเอง…';

  @override
  String get startTimeLabel => 'เวลาเริ่มต้น';

  @override
  String get endTimeLabel => 'เวลาสิ้นสุด';

  @override
  String get customRangeDialogTitle => 'ช่วงเวลาที่กำหนดเอง';

  @override
  String get applyButton => 'ใช้';

  @override
  String get endBeforeStartError => 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่มต้น';

  @override
  String get reportsOrdersLabel => 'ออร์เดอร์';

  @override
  String get ordersColumnHeader => 'ออร์เดอร์';

  @override
  String get totalDiscountedLabel => 'ส่วนลดรวม';

  @override
  String get staffSalesHeader => 'ยอดขายตามพนักงาน';

  @override
  String get staffSalesUnknownLabel => 'ไม่ทราบ';

  @override
  String get ordersSuffix => 'ออเดอร์';

  @override
  String get promotionBreakdownHeader => 'โปรโมชั่นที่ใช้';

  @override
  String get usedSuffix => 'ครั้ง';

  @override
  String get topSellingItemsHeader => 'สินค้าขายดี';

  @override
  String get salesTrendHeader => 'แนวโน้มยอดขาย';

  @override
  String get soldSuffix => 'ขายแล้ว';

  @override
  String get exportCSVButton => 'ส่งออก CSV';

  @override
  String get reportsNoOrdersEmpty => 'ไม่มีออร์เดอร์ในช่วงเวลานี้';

  @override
  String get exportCancelledSnackbar => 'ยกเลิกการส่งออกแล้ว';

  @override
  String exportSuccessSnackbar(String path) {
    return 'บันทึกไว้ที่ $path';
  }

  @override
  String exportFailedSnackbar(String error) {
    return 'ส่งออกไม่สำเร็จ: $error';
  }

  @override
  String get cancelOrderLabel => 'ยกเลิกออร์เดอร์';

  @override
  String get cancelOrderDialogTitle => 'ยกเลิกออร์เดอร์นี้หรือไม่?';

  @override
  String get cancelOrderSnackbar => 'ยกเลิกออร์เดอร์แล้ว';

  @override
  String cancelOrderFailedSnackbar(String error) {
    return 'ยกเลิกไม่สำเร็จ: $error';
  }

  @override
  String get cancelledOrderBadge => 'ยกเลิกแล้ว';

  @override
  String get cancelReasonPromptLabel => 'ทำไมถึงยกเลิกออร์เดอร์นี้?';

  @override
  String get cancelReasonCustomerChanged => 'ลูกค้าเปลี่ยนใจ';

  @override
  String get cancelReasonDuplicate => 'ออร์เดอร์ซ้ำ';

  @override
  String get cancelReasonWrongItem => 'กรอกรายการผิด';

  @override
  String get cancelReasonOutOfStock => 'สินค้าหมด';

  @override
  String get cancelReasonOther => 'อื่นๆ';

  @override
  String get cancelReasonExtraHint => 'รายละเอียดเพิ่มเติม (ถ้ามี)';

  @override
  String get cancelReasonRequiredError => 'กรุณาเลือกเหตุผล';

  @override
  String get staffManagementTitle => 'จัดการพนักงาน';

  @override
  String get addStaffTooltip => 'เพิ่มพนักงาน';

  @override
  String get youLabel => '(คุณ)';

  @override
  String get forceSignoutTooltip => 'บังคับออกจากระบบ';

  @override
  String get removeStaffTitle => 'นำพนักงานออก?';

  @override
  String removeStaffContent(String username) {
    return 'นำ \"$username\" ออกจากระบบอย่างถาวรหรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้';
  }

  @override
  String signedOutSnackbar(String username) {
    return 'บังคับให้ \"$username\" ออกจากระบบทุกอุปกรณ์แล้ว';
  }

  @override
  String get addStaffLabel => 'เพิ่มพนักงาน';

  @override
  String get usernameHint => 'เช่น jane';

  @override
  String get staffPasswordLabel => 'รหัสผ่านชั่วคราว';

  @override
  String get staffPasswordHint => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get staffPasswordTooShort => 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';

  @override
  String get editStaffTooltip => 'แก้ไข';

  @override
  String get editStaffLabel => 'แก้ไขพนักงาน';

  @override
  String get staffPasswordEditHint => 'เว้นว่างไว้เพื่อใช้รหัสผ่านเดิม';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get phoneFieldLabel => 'เบอร์โทรศัพท์';

  @override
  String get phoneFieldHint => 'เช่น 081-234-5678';

  @override
  String get staffNameLabel => 'ชื่อ';

  @override
  String get staffNameHint => 'เช่น สมชาย ใจดี';

  @override
  String get confirmYourPasswordLabel => 'รหัสผ่านของคุณ';

  @override
  String get confirmYourPasswordHint =>
      'ป้อนรหัสผ่านของคุณเพื่อเปลี่ยนชื่อผู้ใช้นี้';

  @override
  String get confirmYourPasswordRequiredValidator =>
      'ต้องใช้รหัสผ่านของคุณเพื่อเปลี่ยนชื่อผู้ใช้';

  @override
  String get settingsAccountSectionLabel => 'บัญชี';

  @override
  String get signedInAsLabel => 'เข้าสู่ระบบในชื่อ';

  @override
  String get connectionSectionLabel => 'การเชื่อมต่อ';

  @override
  String get settingsServerAddressLabel => 'ที่อยู่เซิร์ฟเวอร์';

  @override
  String get disconnectLabel => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get disconnectTitle => 'ยกเลิกการเชื่อมต่อเซิร์ฟเวอร์?';

  @override
  String get disconnectContent => 'คุณจะออกจากระบบและกลับไปยังหน้าต้อนรับ';

  @override
  String get printerSectionLabel => 'เครื่องพิมพ์';

  @override
  String get noPrinterOption => 'ไม่ใช้';

  @override
  String get selectedPrinterLabel => 'อุปกรณ์';

  @override
  String get printerNotSelectedValue => 'อัตโนมัติ (เครื่องแรกที่พบ)';

  @override
  String get selectPrinterButton => 'เลือกเครื่องพิมพ์';

  @override
  String get changePrinterButton => 'เปลี่ยน';

  @override
  String get selectPrinterDialogTitle => 'เลือกเครื่องพิมพ์';

  @override
  String get noPrintersFoundMessage =>
      'ไม่พบเครื่องพิมพ์ ตรวจสอบว่าเปิดเครื่องและอยู่ในระยะ';

  @override
  String get scanningForPrintersLabel => 'กำลังค้นหาเครื่องพิมพ์…';

  @override
  String get loadingPairedPrintersLabel =>
      'กำลังตรวจสอบเครื่องพิมพ์ที่จับคู่ไว้…';

  @override
  String get scanForPrintersButton => 'สแกน';

  @override
  String get noPairedPrintersMessage =>
      'ไม่มีเครื่องพิมพ์ที่จับคู่ไว้ กรุณาจับคู่ในตั้งค่าบลูทูธ หรือสแกนหาอุปกรณ์ใกล้เคียง';

  @override
  String get bluetoothPermissionDeniedMessage =>
      'ต้องได้รับอนุญาตบลูทูธเพื่อค้นหาเครื่องพิมพ์ กรุณาเปิดสิทธิ์นี้ให้แอปในการตั้งค่าโทรศัพท์';

  @override
  String get paperSizeLabel => 'ขนาดกระดาษ';

  @override
  String get paperSize58 => '58มม.';

  @override
  String get paperSize80 => '80มม.';

  @override
  String get languageSectionLabel => 'ภาษา';

  @override
  String get kitchenDisplaySectionLabel => 'หน้าจอครัว';

  @override
  String get kitchenShowImagesLabel => 'แสดงรูปเมนูใน Focus Mode';

  @override
  String get englishOption => 'English';

  @override
  String get thaiOption => 'ภาษาไทย (Thai)';

  @override
  String get backupSectionLabel => 'สำรองข้อมูล';

  @override
  String get exportBackupButton => 'ส่งออกไฟล์สำรอง';

  @override
  String get exportBackupHint =>
      'บันทึกสำเนาข้อมูลร้าน — บัญชี เมนู และออร์เดอร์ — เพื่อย้ายไปยังอุปกรณ์อื่น';

  @override
  String get exportBackupSavedMessage => 'บันทึกไฟล์สำรองแล้ว';

  @override
  String get exportBackupCancelledMessage => 'ยกเลิกการสำรองข้อมูล';

  @override
  String get exportBackupFailedMessage =>
      'ส่งออกไฟล์สำรองไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get staffJoinedLabel => 'เข้าทำงานเมื่อ';

  @override
  String get staffTenureLabel => 'ทำงานที่นี่มาแล้ว';

  @override
  String tenureDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
    );
    return '$_temp0';
  }

  @override
  String tenureMonthsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เดือน',
    );
    return '$_temp0';
  }

  @override
  String tenureYearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ปี',
    );
    return '$_temp0';
  }

  @override
  String get promotionsSectionLabel => 'โปรโมชั่น';

  @override
  String get promotionsEmptyMessage =>
      'ยังไม่มีโปรโมชั่น เพิ่มส่วนลด ซื้อ 1 แถม 1 หรือโค้ดส่วนลดได้เลย';

  @override
  String get promotionsAddButton => 'เพิ่มโปรโมชั่น';

  @override
  String get promotionDeleteConfirmTitle => 'ลบโปรโมชั่นนี้หรือไม่?';

  @override
  String get promotionDeleteConfirmContent =>
      'ไม่สามารถย้อนกลับได้ ออเดอร์เก่าที่เคยใช้โปรโมชั่นนี้จะยังคงมีประวัติอยู่เหมือนเดิม';

  @override
  String get promotionDeleteConfirmButton => 'ลบ';

  @override
  String get promotionEditorNewTitle => 'โปรโมชั่นใหม่';

  @override
  String get promotionEditorEditTitle => 'แก้ไขโปรโมชั่น';

  @override
  String get promotionNameLabel => 'ชื่อโปรโมชั่น';

  @override
  String get promotionNameHint => 'เช่น ลด 10% วันธรรมดา';

  @override
  String get promotionNameRequiredError => 'กรุณาระบุชื่อโปรโมชั่น';

  @override
  String get promotionActiveLabel => 'เปิดใช้งาน';

  @override
  String get promotionSavedMessage => 'บันทึกโปรโมชั่นแล้ว';

  @override
  String get promotionSaveButton => 'บันทึก';

  @override
  String get promotionTypeLabel => 'ประเภท';

  @override
  String get promotionTypePercent => 'ลดเปอร์เซ็นต์';

  @override
  String get promotionTypeFlat => 'ลดจำนวนเงินคงที่';

  @override
  String get promotionTypeBogo => 'ซื้อ 1 แถม 1';

  @override
  String get promotionTypeCode => 'โค้ดส่วนลด';

  @override
  String get promotionTypeCombo => 'ราคาชุด/คอมโบ';

  @override
  String get promotionTypeMinSpend => 'ยอดซื้อขั้นต่ำ';

  @override
  String get promotionTypeTiered => 'ราคาตามจำนวนซื้อ';

  @override
  String get promotionScopeLabel => 'ใช้ได้กับ';

  @override
  String get promotionScopeItem => 'เมนูเฉพาะรายการ';

  @override
  String get promotionScopeCategory => 'หมวดหมู่';

  @override
  String get promotionScopeShop => 'ทั้งร้าน';

  @override
  String get promotionExcludeItemsLabel => 'ยกเว้นสินค้าบางรายการ (ไม่บังคับ)';

  @override
  String get promotionPercentLabel => 'ลดกี่เปอร์เซ็นต์ (%)';

  @override
  String get promotionMaxCapLabel => 'ส่วนลดสูงสุดไม่เกิน (ไม่บังคับ)';

  @override
  String get promotionFlatAmountLabel => 'ลดจำนวนเงิน (฿)';

  @override
  String get promotionMinSpendLabel => 'ยอดสั่งซื้อขั้นต่ำ (฿)';

  @override
  String get promotionRewardPercent => 'ลดเปอร์เซ็นต์';

  @override
  String get promotionRewardFlat => 'ลดจำนวนเงินคงที่';

  @override
  String get promotionBogoBuyQtyLabel => 'จำนวนที่ต้องซื้อ';

  @override
  String get promotionBogoGetQtyLabel => 'จำนวนที่ได้รับส่วนลด';

  @override
  String get promotionBogoDiscountLabel =>
      'ส่วนลดของชิ้นที่ได้รับ (%, 100 = ฟรี)';

  @override
  String get promotionComboPriceLabel => 'ราคาชุด (฿)';

  @override
  String get promotionComboItemsLabel => 'สินค้าที่รวมอยู่ในชุด';

  @override
  String get promotionTieredLabel => 'ระดับจำนวน / ราคา';

  @override
  String get promotionTieredQtyLabel => 'จำนวน';

  @override
  String get promotionTieredPriceLabel => 'ราคา (฿)';

  @override
  String get promotionTieredAddRow => 'เพิ่มระดับราคา';

  @override
  String get promotionScheduleLabel => 'ตั้งเวลา (ไม่บังคับ)';

  @override
  String get promotionStartDateLabel => 'วันที่เริ่ม';

  @override
  String get promotionEndDateLabel => 'วันที่สิ้นสุด';

  @override
  String get promotionDaysOfWeekLabel => 'วันในสัปดาห์ (เว้นว่างไว้ = ทุกวัน)';

  @override
  String get promotionTimeStartLabel => 'เวลาเริ่ม';

  @override
  String get promotionTimeEndLabel => 'เวลาสิ้นสุด';

  @override
  String get promotionApprovalLabel => 'ต้องมีการอนุมัติจากผู้จัดการ';

  @override
  String get promotionApprovalThresholdLabel =>
      'เฉพาะเมื่อส่วนลดเกินจำนวนนี้ (ไม่บังคับ, ฿)';

  @override
  String get promotionCodesLabel => 'โค้ดส่วนลด';

  @override
  String promotionCodeUsageLabel(int usedCount, String maxUses) {
    return 'ใช้ไปแล้ว $usedCount / $maxUses';
  }

  @override
  String get promotionNewCodeLabel => 'โค้ดใหม่';

  @override
  String get promotionMaxUsesLabel => 'จำกัดจำนวนการใช้ (ไม่บังคับ)';

  @override
  String get promotionAddCodeButton => 'เพิ่มโค้ด';

  @override
  String get subtotalLabel => 'ยอดรวมก่อนหักส่วนลด';

  @override
  String get discountCodeFieldLabel => 'โค้ดส่วนลด';

  @override
  String get discountCodeFieldHint => 'กรอกโค้ด';

  @override
  String get applyCodeButton => 'ใช้โค้ด';

  @override
  String get invalidDiscountCodeError => 'โค้ดนี้ไม่ถูกต้องหรือถูกใช้ไปหมดแล้ว';

  @override
  String promotionNeedsApprovalLabel(String name) {
    return '$name ต้องได้รับการอนุมัติจากผู้จัดการ';
  }

  @override
  String get approveButton => 'อนุมัติ';

  @override
  String get managerApprovalDialogTitle => 'การอนุมัติจากผู้จัดการ';

  @override
  String get managerApprovalDialogContent =>
      'ผู้จัดการหรือเจ้าของร้านต้องยืนยันตัวตนของตนเองเพื่ออนุมัติส่วนลดนี้';

  @override
  String get advertisingSectionLabel => 'โฆษณา';

  @override
  String get advertisingSectionHint =>
      'ขนาดที่แนะนำ: 1920×1080 (16:9) รูปภาพ/GIF และวิดีโอจะถูกครอปให้เต็มหน้าจอ (เหมือนโฆษณาทีวี) ควรจัดเนื้อหาสำคัญไว้ตรงกลาง';

  @override
  String get advertisingEmptyMessage =>
      'ยังไม่มีสไลด์ เพิ่มรูปภาพ, GIF หรือวิดีโอเพื่อเล่นบนหน้าจอลูกค้าเวลาที่ว่าง';

  @override
  String get advertisingAddSlideButton => 'เพิ่มสไลด์';

  @override
  String get advertisingDurationLabel => 'วินาที';

  @override
  String get advertisingPlaysUntilEndLabel => 'เล่นจนจบคลิป';

  @override
  String get advertisingDeleteSlideTooltip => 'ลบสไลด์';

  @override
  String get advertisingPreviewTooltip => 'ดูตัวอย่าง';

  @override
  String get advertisingMuteTooltip => 'ปิดเสียง';

  @override
  String get advertisingUnmuteTooltip => 'เปิดเสียง';

  @override
  String get advertisingEditTooltip => 'แก้ไขรายละเอียด';

  @override
  String get advertisingUnnamedSlideLabel => 'ยังไม่ได้ตั้งชื่อ';

  @override
  String get adMediaDetailsTitle => 'รายละเอียดสื่อ';

  @override
  String get adMediaNameLabel => 'ชื่อ (ไม่บังคับ)';

  @override
  String get adMediaNameHint => 'เช่น โปรโมชั่นซื้อ 1 แถม 1 ลาเต้';

  @override
  String get adMediaDurationLabel => 'ระยะเวลา (วินาที)';

  @override
  String get adMediaTransitionLabel => 'ทรานซิชัน';

  @override
  String get adTransitionNoneOption => 'ไม่มี';

  @override
  String get adTransitionFadeOption => 'จางเข้า';

  @override
  String get adTransitionSlideOption => 'เลื่อน';

  @override
  String get adMediaExpiryLabel => 'วันหมดอายุ';

  @override
  String get adExpiryNeverOption => 'ไม่มีวันหมดอายุ (จนกว่าจะลบ)';

  @override
  String adExpiryInDaysOption(int days) {
    return 'อีก $days วัน';
  }

  @override
  String get adExpiryCustomDateOption => 'เลือกวันที่…';

  @override
  String get adMediaNeverExpiresLabel => 'ไม่มีวันหมดอายุ';

  @override
  String adMediaExpiresOnLabel(String date) {
    return 'หมดอายุ $date';
  }

  @override
  String adMediaExpiredOnLabel(String date) {
    return 'หมดอายุแล้ว $date';
  }

  @override
  String get dangerZoneSectionLabel => 'โซนอันตราย';

  @override
  String get removeShopButton => 'ลบร้านนี้';

  @override
  String get removeShopWarningText =>
      'ลบร้านนี้และข้อมูลทั้งหมด — บัญชี เมนู ออร์เดอร์ — ออกจากเซิร์ฟเวอร์อย่างถาวร ไม่สามารถย้อนกลับได้';

  @override
  String get removeShopDialogTitle => 'ลบร้านนี้ใช่หรือไม่?';

  @override
  String get removeShopDialogWarning =>
      'การดำเนินการนี้จะลบทุกบัญชี เมนู และออร์เดอร์บนเซิร์ฟเวอร์นี้อย่างถาวร และออกจากระบบทุกอุปกรณ์ที่เชื่อมต่ออยู่ ไม่สามารถย้อนกลับได้';

  @override
  String get removeShopEmailHint => 'อีเมลที่ลงทะเบียนไว้ของร้านนี้';

  @override
  String get removeShopConfirmButton => 'ลบร้าน';

  @override
  String get backToDashboardTooltip => 'กลับไปหน้าหลัก';

  @override
  String get cropImageTitle => 'ครอบตัดรูปภาพ';

  @override
  String get cropConfirmButton => 'เสร็จสิ้น';

  @override
  String get cropHintText => 'บีบนิ้วเพื่อซูม • ลากเพื่อจัดตำแหน่งภาพ';

  @override
  String get gridViewTooltip => 'มุมมองตาราง';

  @override
  String get listViewTooltip => 'มุมมองรายการ';

  @override
  String get extraDisplaySectionLabel => 'จอแสดงผลเพิ่มเติม';

  @override
  String get openExtraDisplayButton => 'เปิดจอแสดงผลเพิ่มเติม';

  @override
  String get openExtraDisplayHint =>
      'เปิดในหน้าต่างใหม่ พร้อมลงชื่อเข้าใช้แล้ว — ลากไปที่จอที่สอง';

  @override
  String get openExtraDisplayFailedMessage =>
      'ไม่สามารถเปิดหน้าต่างจอแสดงผลเพิ่มเติมได้';

  @override
  String get serverSectionLabel => 'เซิร์ฟเวอร์';

  @override
  String get serverStatusButton => 'สถานะเซิร์ฟเวอร์';

  @override
  String get serverStatusRunningLabel => 'กำลังทำงาน';

  @override
  String get serverStatusStoppedLabel => 'หยุดทำงาน';

  @override
  String get restartServerButton => 'รีสตาร์ทเซิร์ฟเวอร์';

  @override
  String get restartServerTitle => 'รีสตาร์ทเซิร์ฟเวอร์ใช่หรือไม่?';

  @override
  String get restartServerContent =>
      'อุปกรณ์ที่เชื่อมต่ออยู่ทั้งหมด — จอครัว เครื่องแคชเชียร์อื่น จอลูกค้า — จะขาดการเชื่อมต่อชั่วคราวระหว่างรีสตาร์ท';

  @override
  String get restartingServerMessage => 'กำลังรีสตาร์ท…';

  @override
  String get restartServerFailedMessage =>
      'ไม่สามารถรีสตาร์ทอัตโนมัติได้ ลองปิดแล้วเปิดแอปใหม่หากเซิร์ฟเวอร์ไม่กลับมาทำงาน';

  @override
  String get startServerButton => 'เริ่มเซิร์ฟเวอร์';

  @override
  String get startingServerMessage => 'กำลังเริ่ม…';

  @override
  String get startServerFailedMessage =>
      'ไม่สามารถเริ่มอัตโนมัติได้ กรุณาตรวจสอบบันทึก';

  @override
  String get liveActivityTitle => 'กิจกรรมขณะนี้';

  @override
  String get usersOnlineLabel => 'ผู้ใช้ที่ออนไลน์';

  @override
  String get noUsersOnlineMessage => 'ไม่มีใครลงชื่อเข้าใช้อยู่ในขณะนี้';

  @override
  String get kitchenDisplaysLabel => 'จอครัว';

  @override
  String get customerDisplaysLabel => 'จอลูกค้า';

  @override
  String get viewLogsButton => 'ดูบันทึก';

  @override
  String get serverLogsTitle => 'บันทึกเซิร์ฟเวอร์';

  @override
  String get serverLogsEmptyMessage =>
      'ยังไม่พบไฟล์บันทึก — จะปรากฏเฉพาะบนเครื่อง Windows ที่เป็นโฮสต์ของร้านเท่านั้น';

  @override
  String get copyLogsButton => 'คัดลอก';

  @override
  String get logsCopiedSnackbar => 'คัดลอกบันทึกแล้ว';

  @override
  String get openLogFolderButton => 'เปิดโฟลเดอร์บันทึก';

  @override
  String get kitchenDisplayTitle => 'จอครัว';

  @override
  String get signOutTooltip => 'ออกจากระบบ';

  @override
  String get liveConnectionLabel => 'ออนไลน์';

  @override
  String get connectingLabel => 'กำลังเชื่อมต่อ…';

  @override
  String get reconnectingLabel => 'กำลังเชื่อมต่อใหม่…';

  @override
  String get offlineLabel => 'ออฟไลน์';

  @override
  String get newColumnTitle => 'ใหม่';

  @override
  String get preparingColumnTitle => 'กำลังทำ';

  @override
  String get readyColumnTitle => 'พร้อมเสิร์ฟ';

  @override
  String get completeButton => 'เสร็จสิ้น';

  @override
  String get kitchenNoOrders => 'ไม่มีออร์เดอร์';

  @override
  String get justNowElapsed => 'เมื่อสักครู่';

  @override
  String get oneMinAgoElapsed => '1 นาทีที่แล้ว';

  @override
  String minAgoElapsed(int mins) {
    return '$mins นาทีที่แล้ว';
  }

  @override
  String get pendingStatusLabel => 'รอดำเนินการ';

  @override
  String get preparingStatusLabel => 'กำลังทำ';

  @override
  String get readyStatusLabel => 'พร้อมเสิร์ฟ';

  @override
  String updateOrderErrorSnackbar(String error) {
    return 'ไม่สามารถอัปเดตออร์เดอร์ได้: $error';
  }

  @override
  String updateItemErrorSnackbar(String error) {
    return 'ไม่สามารถอัปเดตรายการได้: $error';
  }

  @override
  String get focusModeTitle => 'โฟกัสโหมด';

  @override
  String get startPreparingButton => 'เริ่มทำ';

  @override
  String get readyToServeButton => 'พร้อมเสิร์ฟ';

  @override
  String get customerViewTooltip => 'มุมมองลูกค้า';

  @override
  String accessRestrictedMessage(String feature) {
    return '$feature ใช้ได้เฉพาะผู้จัดการและเจ้าของร้านเท่านั้น';
  }
}

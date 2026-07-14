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
  String get customRange => 'กำหนดเอง…';

  @override
  String get reportsOrdersLabel => 'ออร์เดอร์';

  @override
  String get ordersColumnHeader => 'ออร์เดอร์';

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
  String get englishOption => 'English';

  @override
  String get thaiOption => 'ภาษาไทย (Thai)';

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
  String accessRestrictedMessage(String feature) {
    return '$feature ใช้ได้เฉพาะผู้จัดการและเจ้าของร้านเท่านั้น';
  }
}

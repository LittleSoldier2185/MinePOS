// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MinePOS';

  @override
  String get appTagline => 'Coffee Shop POS';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get total => 'Total';

  @override
  String get change => 'Change';

  @override
  String get cash => 'Cash';

  @override
  String get promptpay => 'PromptPay';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get usb => 'USB';

  @override
  String get signOut => 'Sign Out';

  @override
  String get back => 'BACK';

  @override
  String get next => 'NEXT';

  @override
  String get newOrderButton => 'NEW ORDER';

  @override
  String get reportsLabel => 'Reports';

  @override
  String get staffLabel => 'Staff';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get menuLabel => 'Menu';

  @override
  String get orderHistoryLabel => 'Order History';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get avgOrderLabel => 'Avg Order';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequiredValidator => 'Username is required';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequiredValidator => 'Password is required';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordMismatchValidator => 'Passwords do not match';

  @override
  String get roleLabel => 'Role';

  @override
  String get employeeRoleDisplay => 'Employee';

  @override
  String get managerRoleDisplay => 'Manager';

  @override
  String get ownerRoleDisplay => 'Owner';

  @override
  String get connectionModeLocalLabel => 'Offline Mode (this device)';

  @override
  String get connectionModeCloudLabel => 'Online Mode';

  @override
  String get optionalHint => 'Optional';

  @override
  String get emDash => '—';

  @override
  String get addItemLabel => 'Add Item';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get welcomeAppTitle => 'MINEPOS';

  @override
  String get welcomeOpenRegisterButton => 'OPEN REGISTER';

  @override
  String get welcomeOpenRegisterDescription => 'This device — offline mode';

  @override
  String get welcomeOpenRegisterFailedMessage =>
      'Couldn\'t start the local server. Use \"Connect to Server\" instead, or make sure MinePOS is fully installed.';

  @override
  String get localServerLaunchFailedError =>
      'Could not start the local server.';

  @override
  String get welcomeOpenRegisterUnavailableNote =>
      'Not available on this platform. Use \"Connect to Server\" instead.';

  @override
  String get welcomeOrDivider => 'or';

  @override
  String get welcomeConnectServerButton => 'CONNECT TO SERVER';

  @override
  String get welcomeCreateShopButton => 'CREATE SHOP';

  @override
  String get welcomeCreateShopUnavailableNote =>
      'This device already has a shop set up. Use \"Open Register\" to sign in.';

  @override
  String get shopAlreadyExistsLocalError =>
      'This device already has a shop set up. Use \"Open Register\" to sign in instead.';

  @override
  String get shopAlreadyExistsRemoteError =>
      'This server already has a shop set up. Ask its owner to sign you in instead of creating a new one.';

  @override
  String get welcomeVersionInfo => 'v1.0 · Self-hosted or Cloud';

  @override
  String get loginScreenTitle => 'SIGN IN';

  @override
  String loginConnectedTo(String serverAddress) {
    return 'Connected to $serverAddress';
  }

  @override
  String get usernameOrEmailLabel => 'Username / Email';

  @override
  String get deviceNameLabel => 'Device Name';

  @override
  String get deviceNameHint => 'e.g. Register 1, Front Counter';

  @override
  String get deviceNameRequiredValidator => 'Device name is required';

  @override
  String get defaultDeviceNameOnSetup => 'Main Register';

  @override
  String get rememberMeLabel => 'Remember me';

  @override
  String get loginForgotPasswordLink => 'Forgot Password';

  @override
  String get loginErrorMessage => 'Invalid username or password.';

  @override
  String get loginSignInButton => 'SIGN IN';

  @override
  String get loginWelcomeMessage => 'Welcome back!';

  @override
  String get forgotPasswordTitle => 'FORGOT PASSWORD';

  @override
  String get forgotPasswordInstructions =>
      'Enter your username or email to receive a one-time code.';

  @override
  String get forgotPasswordValidator => 'This field is required';

  @override
  String get forgotPasswordErrorMessage =>
      'No account found with that username or email.';

  @override
  String get forgotPasswordSendCodeButton => 'SEND CODE';

  @override
  String get forgotPasswordBackLink => 'Back to Sign In';

  @override
  String get otpVerificationTitle => 'ENTER CODE';

  @override
  String otpVerificationInstructions(String username) {
    return 'A 6-digit code was sent to the email\nassociated with $username.';
  }

  @override
  String get otpVerificationIncompleteError =>
      'Please enter the complete 6-digit code.';

  @override
  String get otpVerificationInvalidError =>
      'Invalid or expired code. Please try again.';

  @override
  String get otpVerificationSuccessMessage => 'A new code has been sent.';

  @override
  String get otpVerificationVerifyButton => 'VERIFY';

  @override
  String get otpVerificationResendButton => 'Resend Code';

  @override
  String get resetPasswordTitle => 'NEW PASSWORD';

  @override
  String get resetPasswordInstructions =>
      'Choose a strong password for your account.';

  @override
  String get resetPasswordNewPasswordLabel => 'New Password';

  @override
  String get resetPasswordLengthValidator => 'Must be at least 8 characters';

  @override
  String get resetPasswordConfirmEmptyValidator =>
      'Please confirm your password';

  @override
  String get resetPasswordErrorMessage => 'Reset failed. Please try again.';

  @override
  String get resetPasswordSuccessMessage =>
      'Password reset. Please sign in with your new password.';

  @override
  String get resetPasswordButton => 'RESET PASSWORD';

  @override
  String get connectAppBarTitle => 'Connect to Server';

  @override
  String get connectTabWifi => 'ON THIS WI-FI';

  @override
  String get connectTabManual => 'MANUAL';

  @override
  String get connectManualTitle => 'Enter server address';

  @override
  String get connectManualInstructions =>
      'Ask your admin for the address of the MinePOS host.';

  @override
  String get connectMixedContentWarning =>
      'Wi-Fi discovery isn\'t available in a web browser. If your host address uses http:// and this page is loaded over https://, your browser may block the connection as mixed content.';

  @override
  String get connectServerAddressLabel => 'Server Address';

  @override
  String get connectServerAddressHint => '192.168.1.10:8080';

  @override
  String get connectEmptyAddressError => 'Enter a server address';

  @override
  String get connectFailureError =>
      'Couldn\'t connect. Check the address and try again.';

  @override
  String get connectNoShopError =>
      'This server hasn\'t set up a shop yet. Use \"Create Shop\" to set it up first.';

  @override
  String get connectButton => 'CONNECT';

  @override
  String get connectWifiTitle => 'Shops on this Wi-Fi';

  @override
  String get connectWifiInstructions =>
      'Make sure this device is on the same Wi-Fi as the MinePOS host.';

  @override
  String get connectScanButton => 'SCAN FOR SHOPS';

  @override
  String get connectScanningLabel => 'Scanning...';

  @override
  String get connectNoShopsFound => 'No shops found yet.';

  @override
  String get roleSelectionTitle => 'WHAT IS THIS DEVICE FOR?';

  @override
  String get roleSelectionInstructions =>
      'You\'ll pick a server to connect to next.';

  @override
  String get roleSelectionCashierTitle => 'Cashier / Manager';

  @override
  String get roleSelectionCashierSubtitle =>
      'Take orders, manage the shop — signs in normally.';

  @override
  String get roleSelectionKitchenTitle => 'Kitchen Display';

  @override
  String get roleSelectionKitchenSubtitle =>
      'Dedicated kitchen board — signs in, then stays on the board.';

  @override
  String get roleSelectionCustomerTitle => 'Customer Display';

  @override
  String get roleSelectionCustomerSubtitle =>
      'Faces the customer, mirrors the live order — no sign-in.';

  @override
  String get shopSetupChoiceTitle => 'SET UP THIS DEVICE';

  @override
  String get shopSetupChoiceInstructions =>
      'Start a brand-new shop, or bring an existing one over from another device.';

  @override
  String get shopSetupChoiceFreshTitle => 'Start Fresh';

  @override
  String get shopSetupChoiceFreshSubtitle =>
      'Set up a brand-new shop from scratch.';

  @override
  String get shopSetupChoiceRestoreTitle => 'Restore from Backup';

  @override
  String get shopSetupChoiceRestoreSubtitle =>
      'Bring an existing shop\'s data onto this device.';

  @override
  String get restoreShopAppBarTitle => 'Restore Shop';

  @override
  String get restoreShopFileTab => 'Backup File';

  @override
  String get restoreShopTransferTab => 'Another Device';

  @override
  String get restoreShopFileTitle => 'Restore from a backup file';

  @override
  String get restoreShopFileInstructions =>
      'Pick a backup file exported from Settings on the old device.';

  @override
  String get restoreShopChooseFileButton => 'CHOOSE BACKUP FILE';

  @override
  String get restoreShopInvalidFileError =>
      'That file doesn\'t look like a MinePOS backup. Pick a different file.';

  @override
  String restoreShopFoundShopLabel(String shopName) {
    return 'Found shop: $shopName';
  }

  @override
  String get restoreShopConfirmButton => 'RESTORE THIS SHOP';

  @override
  String get restoreShopTransferTitle => 'Restore from another device';

  @override
  String get restoreShopTransferInstructions =>
      'Enter the address of the server currently running the shop you want to move here.';

  @override
  String get restoreShopOldOwnerLoginLabel =>
      'Sign in as the owner of that shop to continue.';

  @override
  String get restoreShopTransferButton => 'SIGN IN & TRANSFER';

  @override
  String get restoreShopTransferFieldsRequiredError =>
      'Device name, username, and password are all required.';

  @override
  String get restoreShopTransferLoginError =>
      'Couldn\'t sign in to that server. Check the username and password.';

  @override
  String get restoreDestinationTitle => 'WHERE DO YOU WANT TO RESTORE THIS?';

  @override
  String get restoreDestinationLocalOption => 'This Device (Local Storage)';

  @override
  String get restoreDestinationLocalUnavailableNote =>
      'Not available — either this platform can\'t self-host, or this device already has a shop.';

  @override
  String get restoreDestinationServerOption => 'Another Server (by IP)';

  @override
  String get restoreDestinationServerHasShopError =>
      'That server already has a shop set up. Restore only works on a server that\'s never been set up before.';

  @override
  String get createShopAppBarTitle => 'Create Shop';

  @override
  String stepIndicator(int stepNumber, int stepCount) {
    return 'Step $stepNumber of $stepCount';
  }

  @override
  String get finishSetupButton => 'FINISH SETUP';

  @override
  String get shopCreatedDefaultTitle => 'Shop created!';

  @override
  String shopReadyTitle(String shopName) {
    return '$shopName is ready!';
  }

  @override
  String get shopDetailsStepTitle => 'Shop details';

  @override
  String get shopDetailsStepSubtitle => 'Tell us about your shop.';

  @override
  String get shopLogoTapInstruction => 'Tap to add a logo';

  @override
  String get shopNameFieldLabel => 'Shop Name';

  @override
  String get shopNameFieldHint => 'Cozy Cafe';

  @override
  String get shopNameValidatorError => 'Shop name is required';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldHint => 'shop@example.com';

  @override
  String get emailRequiredValidatorError => 'Email is required';

  @override
  String get emailInvalidValidatorError => 'Enter a valid email';

  @override
  String get addressFieldLabel => 'Address';

  @override
  String get taxIdFieldLabel => 'Tax ID';

  @override
  String get receiptFooterFieldLabel => 'Receipt Footer';

  @override
  String get receiptFooterFieldHint => 'Optional, e.g. \"Thank you!\"';

  @override
  String get promptpayIdFieldLabel => 'PromptPay ID';

  @override
  String get promptpayIdFieldHint => 'Mobile number or 13-digit Tax/Citizen ID';

  @override
  String get promptpayIdValidatorError =>
      'Enter a 10-digit phone number or 13-digit ID';

  @override
  String get promptpayLabelFieldLabel => 'QR Caption';

  @override
  String get promptpayLabelFieldHint =>
      'Optional text shown under the QR, e.g. shop name';

  @override
  String get shopDetailsSectionLabel => 'Shop Details';

  @override
  String get shopDetailsSavedMessage => 'Shop details saved';

  @override
  String shopSetupFailedMessage(String error) {
    return 'Setup failed: $error';
  }

  @override
  String get adminAccountStepTitle => 'First admin account';

  @override
  String get adminAccountStepSubtitle =>
      'This account has full access to MinePOS.';

  @override
  String get passwordMinLengthValidatorError => 'At least 6 characters';

  @override
  String get connectionModeStepTitle => 'Connection mode';

  @override
  String get connectionModeStepSubtitle => 'How will this shop run?';

  @override
  String get localConnectionModeSubtitleWindows =>
      'No internet needed. Data stays on this PC — other devices connect over Wi-Fi.';

  @override
  String get localConnectionModeSubtitleOther =>
      'Only available on the Windows desktop app.';

  @override
  String get localConnectionModeSubtitleMobile =>
      'No internet needed. Data stays on this device only — others can\'t connect.';

  @override
  String get cloudConnectionModeSubtitle =>
      'Connect to a server already running elsewhere, by its address.';

  @override
  String get printerSetupStepTitle => 'Printer setup';

  @override
  String get printerSetupStepSubtitle =>
      'Choose how receipts will print. You can change this later.';

  @override
  String get bluetoothPrinterOptionSubtitle =>
      'Pair a Bluetooth thermal printer';

  @override
  String get usbPrinterOptionSubtitle => 'Connect a USB thermal printer';

  @override
  String get skipPrinterOptionTitle => 'Skip for now';

  @override
  String get skipPrinterOptionSubtitle =>
      'Set up a printer later from Settings';

  @override
  String get printerDiscoveryNote =>
      'Tap Print on a receipt to scan for a paired printer — make sure it\'s on and in range.';

  @override
  String get setupSummaryStepTitle => 'Review & finish';

  @override
  String get setupSummaryStepSubtitle =>
      'Check everything looks right before creating your shop.';

  @override
  String get summaryRowLabelAdminUsername => 'Admin Username';

  @override
  String get summaryRowLabelConnectionMode => 'Connection Mode';

  @override
  String get summaryRowLabelPrinter => 'Printer';

  @override
  String get summaryPrinterSkippedLabel => 'Skipped for now';

  @override
  String get clearOrderDialogTitle => 'Clear Order?';

  @override
  String get clearOrderDialogContent =>
      'Remove all items from the current order?';

  @override
  String get clearButton => 'Clear';

  @override
  String get newOrderAppBarTitle => 'New Order';

  @override
  String get clearOrderTooltip => 'Clear order';

  @override
  String get orderHistoryTooltip => 'Order history';

  @override
  String get cartTabLabel => 'Cart';

  @override
  String orderNumberLabel(String number) {
    return 'Order  #$number';
  }

  @override
  String get emptyCartMessage => 'Tap items\nto add to order';

  @override
  String get proceedToPayButton => 'PROCEED TO PAY';

  @override
  String get paymentAppBarTitle => 'Payment';

  @override
  String get orderSummaryHeader => 'ORDER SUMMARY';

  @override
  String get amountReceivedHeader => 'AMOUNT RECEIVED';

  @override
  String get amountLessThanTotalError => 'Amount is less than total';

  @override
  String get promptpayConfigMessage =>
      'Configure PromptPay ID\nin Settings to enable';

  @override
  String get tapToEnlargeQrMessage => 'Tap to enlarge';

  @override
  String get scanQrToPayMessage => 'Scan QR to pay';

  @override
  String confirmPaymentButton(String total) {
    return 'CONFIRM PAYMENT  •  $total';
  }

  @override
  String receiptAppBarTitle(String orderNumber) {
    return 'Receipt $orderNumber';
  }

  @override
  String get businessName => 'MinePOS Coffee';

  @override
  String get receiptThankYouMessage => 'Thank you for your order!';

  @override
  String get receiptOrderLabel => 'Order';

  @override
  String get receiptDateLabel => 'Date';

  @override
  String get receiptPaymentLabel => 'Payment';

  @override
  String get receiptClosingMessage => '— See you again! —';

  @override
  String get printButtonLabel => 'PRINT';

  @override
  String get printingInProgressMessage => 'Printing…';

  @override
  String get printSuccessMessage => 'Receipt sent to printer.';

  @override
  String get printNoPrinterMessage =>
      'No printer found. Check it\'s on and in range.';

  @override
  String printFailedMessage(String error) {
    return 'Couldn\'t print: $error';
  }

  @override
  String get printSkippedMessage =>
      'No printer selected — set one up in Settings.';

  @override
  String get orderHistoryAppBarTitle => 'Order History';

  @override
  String get noOrdersMessage => 'No orders yet';

  @override
  String get noMenuItemsMessage =>
      'No menu items yet — add some in Menu Management';

  @override
  String orderItemsSummary(int count, String paymentMethod) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0  •  $paymentMethod';
  }

  @override
  String get exitCustomerDisplayTitle => 'Exit Customer Display?';

  @override
  String get exitCustomerDisplayContent =>
      'This returns to the welcome screen.';

  @override
  String get exitButton => 'Exit';

  @override
  String get welcomeToMinePosMessage => 'Welcome to MinePOS';

  @override
  String get orderWillAppearMessage => 'Your order will appear here';

  @override
  String get selectStationTitle => 'Select a Station';

  @override
  String get noStationsOnlineMessage =>
      'No stations are online yet. Open a register and start an order.';

  @override
  String get customerDisplayOrderLabel => 'Your Order';

  @override
  String customerDisplayOrderWithNumber(String orderNumber) {
    return 'Order #$orderNumber';
  }

  @override
  String get thankYouMessage => 'Thank You!';

  @override
  String totalPaidLabel(String amount) {
    return 'Total paid: $amount';
  }

  @override
  String changeMessageLabel(String amount) {
    return 'Change: $amount';
  }

  @override
  String get goodMorningGreeting => 'Good morning';

  @override
  String get goodAfternoonGreeting => 'Good afternoon';

  @override
  String get goodEveningGreeting => 'Good evening';

  @override
  String get signOutDialogTitle => 'Sign Out?';

  @override
  String get signOutDialogContent =>
      'You will be returned to the welcome screen.';

  @override
  String get desktopDashboardNavLabel => 'Dashboard';

  @override
  String get menuMgmtNavLabel => 'Menu Mgmt';

  @override
  String get kitchenNavLabel => 'Kitchen';

  @override
  String get defaultAdminUsername => 'Admin';

  @override
  String get mobileBottomNavHome => 'Home';

  @override
  String get mobileBottomNavOrders => 'Orders';

  @override
  String get mobileBottomNavMore => 'More';

  @override
  String greetingWithName(String greeting) {
    return '$greeting, Admin';
  }

  @override
  String get homeOrdersTodayStat => 'Orders Today';

  @override
  String get recentOrdersHeader => 'RECENT ORDERS';

  @override
  String get viewAllOrdersLink => 'View all →';

  @override
  String get noOrdersTodayMessage => 'No orders yet today';

  @override
  String get recentOrderQrLabel => 'QR';

  @override
  String get menuManagementTitle => 'Menu Management';

  @override
  String get addItemTooltip => 'Add item';

  @override
  String get noItemsEmpty => 'No items in this category.';

  @override
  String get deleteItemTitle => 'Delete Item?';

  @override
  String deleteItemContent(String itemName) {
    return 'Remove \"$itemName\" from the menu? This cannot be undone.';
  }

  @override
  String deleteItemSnackbar(String itemName) {
    return '\"$itemName\" removed';
  }

  @override
  String get editItemFormTitle => 'Edit Item';

  @override
  String get itemNameLabel => 'Item name (English)';

  @override
  String get itemNameHint => 'e.g. Caramel Latte';

  @override
  String get itemNameRequired => 'Name is required';

  @override
  String get itemNameThLabel => 'Item name (Thai)';

  @override
  String get itemNameThHint => 'Optional, e.g. คาราเมลลาเต้';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g. Coffee';

  @override
  String get categoryRequired => 'Category is required';

  @override
  String get priceLabel => 'Price';

  @override
  String get priceHint => '0';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get priceInvalid => 'Enter a valid price';

  @override
  String get availableLabel => 'Available on menu';

  @override
  String get hasSweetnessLabel => 'Ask sweetness level';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get selectSweetnessTitle => 'Sweetness level';

  @override
  String get sweetnessLess => 'Less';

  @override
  String get sweetnessNormal => 'Normal';

  @override
  String get sweetnessSweet => 'Sweet';

  @override
  String get todayRange => 'Today';

  @override
  String get yesterdayRange => 'Yesterday';

  @override
  String get last7Range => 'Last 7 Days';

  @override
  String get last30Range => 'Last 30 Days';

  @override
  String get allTimeRange => 'All Time';

  @override
  String get monthRange => 'Month…';

  @override
  String get customRange => 'Custom…';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get endTimeLabel => 'End time';

  @override
  String get customRangeDialogTitle => 'Custom Range';

  @override
  String get applyButton => 'Apply';

  @override
  String get endBeforeStartError => 'End must be after start';

  @override
  String get reportsOrdersLabel => 'Orders';

  @override
  String get ordersColumnHeader => 'ORDERS';

  @override
  String get totalDiscountedLabel => 'Discounted';

  @override
  String get staffSalesHeader => 'SALES BY STAFF';

  @override
  String get staffSalesUnknownLabel => 'Unknown';

  @override
  String get ordersSuffix => 'orders';

  @override
  String get promotionBreakdownHeader => 'PROMOTIONS USED';

  @override
  String get usedSuffix => 'used';

  @override
  String get topSellingItemsHeader => 'TOP SELLING ITEMS';

  @override
  String get salesTrendHeader => 'SALES TREND';

  @override
  String get soldSuffix => 'sold';

  @override
  String get exportCSVButton => 'Export CSV';

  @override
  String get reportsNoOrdersEmpty => 'No orders in this range';

  @override
  String get exportCancelledSnackbar => 'Export cancelled';

  @override
  String exportSuccessSnackbar(String path) {
    return 'Saved to $path';
  }

  @override
  String exportFailedSnackbar(String error) {
    return 'Export failed: $error';
  }

  @override
  String get cancelOrderLabel => 'Cancel Order';

  @override
  String get cancelOrderDialogTitle => 'Cancel this order?';

  @override
  String get cancelOrderSnackbar => 'Order cancelled';

  @override
  String cancelOrderFailedSnackbar(String error) {
    return 'Couldn\'t cancel: $error';
  }

  @override
  String get cancelledOrderBadge => 'Cancelled';

  @override
  String get cancelReasonPromptLabel => 'Why are you cancelling this order?';

  @override
  String get cancelReasonCustomerChanged => 'Customer changed their mind';

  @override
  String get cancelReasonDuplicate => 'Duplicate order';

  @override
  String get cancelReasonWrongItem => 'Wrong item entered';

  @override
  String get cancelReasonOutOfStock => 'Item out of stock';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get cancelReasonExtraHint => 'Additional details (optional)';

  @override
  String get cancelReasonRequiredError => 'Please select a reason';

  @override
  String get staffManagementTitle => 'Staff Management';

  @override
  String get addStaffTooltip => 'Add staff';

  @override
  String get youLabel => '(you)';

  @override
  String get forceSignoutTooltip => 'Force sign-out';

  @override
  String get removeStaffTitle => 'Remove Staff?';

  @override
  String removeStaffContent(String username) {
    return 'Permanently remove \"$username\" from the system? This cannot be undone.';
  }

  @override
  String signedOutSnackbar(String username) {
    return '\"$username\" signed out on all devices';
  }

  @override
  String get addStaffLabel => 'Add Staff';

  @override
  String get usernameHint => 'e.g. jane';

  @override
  String get staffPasswordLabel => 'Temporary password';

  @override
  String get staffPasswordHint => 'At least 8 characters';

  @override
  String get staffPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get editStaffTooltip => 'Edit';

  @override
  String get editStaffLabel => 'Edit Staff';

  @override
  String get staffPasswordEditHint => 'Leave blank to keep current password';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get phoneFieldLabel => 'Phone';

  @override
  String get phoneFieldHint => 'e.g. 081-234-5678';

  @override
  String get staffNameLabel => 'Name';

  @override
  String get staffNameHint => 'e.g. Jane Smith';

  @override
  String get confirmYourPasswordLabel => 'Your password';

  @override
  String get confirmYourPasswordHint =>
      'Enter your password to change this username';

  @override
  String get confirmYourPasswordRequiredValidator =>
      'Your password is required to change a username';

  @override
  String get settingsAccountSectionLabel => 'ACCOUNT';

  @override
  String get signedInAsLabel => 'Signed in as';

  @override
  String get connectionSectionLabel => 'CONNECTION';

  @override
  String get settingsServerAddressLabel => 'Server address';

  @override
  String get disconnectLabel => 'Disconnect';

  @override
  String get disconnectTitle => 'Disconnect from Server?';

  @override
  String get disconnectContent =>
      'You will be signed out and returned to the welcome screen.';

  @override
  String get printerSectionLabel => 'PRINTER';

  @override
  String get noPrinterOption => 'None';

  @override
  String get selectedPrinterLabel => 'Device';

  @override
  String get printerNotSelectedValue => 'Auto (first found)';

  @override
  String get selectPrinterButton => 'Select Printer';

  @override
  String get changePrinterButton => 'Change';

  @override
  String get selectPrinterDialogTitle => 'Select Printer';

  @override
  String get noPrintersFoundMessage =>
      'No printers found. Make sure it\'s on and in range.';

  @override
  String get scanningForPrintersLabel => 'Scanning for printers…';

  @override
  String get loadingPairedPrintersLabel => 'Checking paired printers…';

  @override
  String get scanForPrintersButton => 'SCAN';

  @override
  String get noPairedPrintersMessage =>
      'No paired printers. Pair one in Bluetooth settings, or scan for nearby devices.';

  @override
  String get bluetoothPermissionDeniedMessage =>
      'Bluetooth permission is required to find printers. Enable it for this app in phone Settings.';

  @override
  String get paperSizeLabel => 'Paper Size';

  @override
  String get paperSize58 => '58mm';

  @override
  String get paperSize80 => '80mm';

  @override
  String get languageSectionLabel => 'LANGUAGE';

  @override
  String get englishOption => 'English';

  @override
  String get thaiOption => 'ภาษาไทย (Thai)';

  @override
  String get backupSectionLabel => 'BACKUP';

  @override
  String get exportBackupButton => 'Export Backup';

  @override
  String get exportBackupHint =>
      'Save a copy of your shop\'s data — accounts, menu, and orders — to move it to another device.';

  @override
  String get exportBackupSavedMessage => 'Backup saved.';

  @override
  String get exportBackupCancelledMessage => 'Backup cancelled.';

  @override
  String get exportBackupFailedMessage =>
      'Couldn\'t export the backup. Try again.';

  @override
  String get staffJoinedLabel => 'Joined';

  @override
  String get staffTenureLabel => 'Working here for';

  @override
  String tenureDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String tenureMonthsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String tenureYearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String get promotionsSectionLabel => 'PROMOTIONS';

  @override
  String get promotionsEmptyMessage =>
      'No promotions yet. Add a discount, BOGO, or promo code.';

  @override
  String get promotionsAddButton => 'Add Promotion';

  @override
  String get promotionDeleteConfirmTitle => 'Delete this promotion?';

  @override
  String get promotionDeleteConfirmContent =>
      'This can\'t be undone. Past orders that already used it keep their own record either way.';

  @override
  String get promotionDeleteConfirmButton => 'Delete';

  @override
  String get promotionEditorNewTitle => 'New Promotion';

  @override
  String get promotionEditorEditTitle => 'Edit Promotion';

  @override
  String get promotionNameLabel => 'Name';

  @override
  String get promotionNameHint => 'e.g. Weekday 10% off';

  @override
  String get promotionNameRequiredError => 'Name is required';

  @override
  String get promotionActiveLabel => 'Active';

  @override
  String get promotionSavedMessage => 'Promotion saved';

  @override
  String get promotionSaveButton => 'Save';

  @override
  String get promotionTypeLabel => 'Type';

  @override
  String get promotionTypePercent => 'Percent off';

  @override
  String get promotionTypeFlat => 'Flat amount off';

  @override
  String get promotionTypeBogo => 'Buy one get one';

  @override
  String get promotionTypeCode => 'Discount code';

  @override
  String get promotionTypeCombo => 'Combo bundle';

  @override
  String get promotionTypeMinSpend => 'Minimum spend';

  @override
  String get promotionTypeTiered => 'Tiered pricing';

  @override
  String get promotionScopeLabel => 'Applies to';

  @override
  String get promotionScopeItem => 'Specific item(s)';

  @override
  String get promotionScopeCategory => 'Category';

  @override
  String get promotionScopeShop => 'Whole shop';

  @override
  String get promotionExcludeItemsLabel => 'Exclude specific items (optional)';

  @override
  String get promotionPercentLabel => 'Percent off (%)';

  @override
  String get promotionMaxCapLabel => 'Max discount amount (optional)';

  @override
  String get promotionFlatAmountLabel => 'Amount off (฿)';

  @override
  String get promotionMinSpendLabel => 'Minimum order total (฿)';

  @override
  String get promotionRewardPercent => 'Percent off';

  @override
  String get promotionRewardFlat => 'Fixed amount off';

  @override
  String get promotionBogoBuyQtyLabel => 'Buy quantity';

  @override
  String get promotionBogoGetQtyLabel => 'Get quantity';

  @override
  String get promotionBogoDiscountLabel =>
      'Discount on the \"get\" items (%, 100 = free)';

  @override
  String get promotionComboPriceLabel => 'Bundle price (฿)';

  @override
  String get promotionComboItemsLabel => 'Items included in the bundle';

  @override
  String get promotionTieredLabel => 'Quantity / price tiers';

  @override
  String get promotionTieredQtyLabel => 'Qty';

  @override
  String get promotionTieredPriceLabel => 'Price (฿)';

  @override
  String get promotionTieredAddRow => 'Add tier';

  @override
  String get promotionScheduleLabel => 'Schedule (optional)';

  @override
  String get promotionStartDateLabel => 'Start date';

  @override
  String get promotionEndDateLabel => 'End date';

  @override
  String get promotionDaysOfWeekLabel =>
      'Days of week (leave empty for every day)';

  @override
  String get promotionTimeStartLabel => 'Start time';

  @override
  String get promotionTimeEndLabel => 'End time';

  @override
  String get promotionApprovalLabel => 'Requires manager approval';

  @override
  String get promotionApprovalThresholdLabel =>
      'Only above this discount amount (optional, ฿)';

  @override
  String get promotionCodesLabel => 'Codes';

  @override
  String promotionCodeUsageLabel(int usedCount, String maxUses) {
    return 'Used $usedCount / $maxUses';
  }

  @override
  String get promotionNewCodeLabel => 'New code';

  @override
  String get promotionMaxUsesLabel => 'Max uses (optional)';

  @override
  String get promotionAddCodeButton => 'Add Code';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get discountCodeFieldLabel => 'Discount code';

  @override
  String get discountCodeFieldHint => 'Enter a code';

  @override
  String get applyCodeButton => 'Apply';

  @override
  String get invalidDiscountCodeError =>
      'That code isn\'t valid or has already been used up.';

  @override
  String promotionNeedsApprovalLabel(String name) {
    return '$name needs manager approval';
  }

  @override
  String get approveButton => 'Approve';

  @override
  String get managerApprovalDialogTitle => 'Manager approval';

  @override
  String get managerApprovalDialogContent =>
      'A manager or owner must confirm their own credentials to approve this discount.';

  @override
  String get advertisingSectionLabel => 'ADVERTISING';

  @override
  String get advertisingSectionHint =>
      'Recommended size: 1920×1080 (16:9). Images/GIFs and videos are cropped to fill the screen (like a TV ad), so keep important content centered.';

  @override
  String get advertisingEmptyMessage =>
      'No slides yet. Add images, GIFs, or videos to play on the customer display whenever it\'s idle.';

  @override
  String get advertisingAddSlideButton => 'Add Slide';

  @override
  String get advertisingDurationLabel => 'Seconds';

  @override
  String get advertisingPlaysUntilEndLabel => 'Plays until it ends';

  @override
  String get advertisingDeleteSlideTooltip => 'Delete slide';

  @override
  String get dangerZoneSectionLabel => 'DANGER ZONE';

  @override
  String get removeShopButton => 'REMOVE SHOP';

  @override
  String get removeShopWarningText =>
      'Permanently deletes this shop and all its data — accounts, menu, orders — from the server. This cannot be undone.';

  @override
  String get removeShopDialogTitle => 'Remove this shop?';

  @override
  String get removeShopDialogWarning =>
      'This permanently deletes every account, menu item, and order on this server, and signs out every connected device. This cannot be undone.';

  @override
  String get removeShopEmailHint => 'This shop\'s registered email';

  @override
  String get removeShopConfirmButton => 'DELETE SHOP';

  @override
  String get backToDashboardTooltip => 'Back to Dashboard';

  @override
  String get cropImageTitle => 'Crop Image';

  @override
  String get cropConfirmButton => 'Done';

  @override
  String get cropHintText => 'Pinch to zoom • Drag to reposition';

  @override
  String get gridViewTooltip => 'Grid View';

  @override
  String get listViewTooltip => 'List View';

  @override
  String get extraDisplaySectionLabel => 'EXTRA DISPLAY';

  @override
  String get openExtraDisplayButton => 'Open Extra Display';

  @override
  String get openExtraDisplayHint =>
      'Opens in a new window, already signed in — drag it to a second monitor.';

  @override
  String get openExtraDisplayFailedMessage =>
      'Couldn\'t open the extra display window';

  @override
  String get serverSectionLabel => 'SERVER';

  @override
  String get serverStatusButton => 'Server Status';

  @override
  String get serverStatusRunningLabel => 'Running';

  @override
  String get serverStatusStoppedLabel => 'Stopped';

  @override
  String get restartServerButton => 'Restart Server';

  @override
  String get restartServerTitle => 'Restart the server?';

  @override
  String get restartServerContent =>
      'Every connected device — kitchen display, other cashiers, customer display — will briefly disconnect while it restarts.';

  @override
  String get restartingServerMessage => 'Restarting…';

  @override
  String get restartServerFailedMessage =>
      'Couldn\'t restart automatically. Close and reopen the app if it doesn\'t come back.';

  @override
  String get startServerButton => 'Start Server';

  @override
  String get startingServerMessage => 'Starting…';

  @override
  String get startServerFailedMessage =>
      'Couldn\'t start automatically. Check the log for details.';

  @override
  String get liveActivityTitle => 'Live Activity';

  @override
  String get usersOnlineLabel => 'Users online';

  @override
  String get noUsersOnlineMessage => 'No one else is signed in right now.';

  @override
  String get kitchenDisplaysLabel => 'Kitchen displays';

  @override
  String get customerDisplaysLabel => 'Customer displays';

  @override
  String get viewLogsButton => 'View Logs';

  @override
  String get serverLogsTitle => 'Server Logs';

  @override
  String get serverLogsEmptyMessage =>
      'No log file found yet — this only appears on the Windows device hosting the shop.';

  @override
  String get copyLogsButton => 'Copy';

  @override
  String get logsCopiedSnackbar => 'Logs copied to clipboard';

  @override
  String get openLogFolderButton => 'Open Log Folder';

  @override
  String get kitchenDisplayTitle => 'Kitchen Display';

  @override
  String get signOutTooltip => 'Sign Out';

  @override
  String get liveConnectionLabel => 'Live';

  @override
  String get connectingLabel => 'Connecting…';

  @override
  String get reconnectingLabel => 'Reconnecting…';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get newColumnTitle => 'NEW';

  @override
  String get preparingColumnTitle => 'PREPARING';

  @override
  String get readyColumnTitle => 'READY';

  @override
  String get completeButton => 'Complete';

  @override
  String get kitchenNoOrders => 'No orders';

  @override
  String get justNowElapsed => 'just now';

  @override
  String get oneMinAgoElapsed => '1 min ago';

  @override
  String minAgoElapsed(int mins) {
    return '$mins min ago';
  }

  @override
  String get pendingStatusLabel => 'Pending';

  @override
  String get preparingStatusLabel => 'Preparing';

  @override
  String get readyStatusLabel => 'Ready';

  @override
  String updateOrderErrorSnackbar(String error) {
    return 'Could not update order: $error';
  }

  @override
  String updateItemErrorSnackbar(String error) {
    return 'Could not update item: $error';
  }

  @override
  String accessRestrictedMessage(String feature) {
    return '$feature is only available to managers and owners.';
  }
}

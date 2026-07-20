import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MinePOS'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Coffee Shop POS'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @promptpay.
  ///
  /// In en, this message translates to:
  /// **'PromptPay'**
  String get promptpay;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get usb;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get next;

  /// No description provided for @newOrderButton.
  ///
  /// In en, this message translates to:
  /// **'NEW ORDER'**
  String get newOrderButton;

  /// No description provided for @reportsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsLabel;

  /// No description provided for @staffLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffLabel;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @menuLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuLabel;

  /// No description provided for @orderHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryLabel;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @avgOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Order'**
  String get avgOrderLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequiredValidator;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredValidator;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordMismatchValidator.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatchValidator;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @employeeRoleDisplay.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeRoleDisplay;

  /// No description provided for @managerRoleDisplay.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get managerRoleDisplay;

  /// No description provided for @ownerRoleDisplay.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRoleDisplay;

  /// No description provided for @connectionModeLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode (this device)'**
  String get connectionModeLocalLabel;

  /// No description provided for @connectionModeCloudLabel.
  ///
  /// In en, this message translates to:
  /// **'Online Mode'**
  String get connectionModeCloudLabel;

  /// No description provided for @optionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @emDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get emDash;

  /// No description provided for @addItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemLabel;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @welcomeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'MINEPOS'**
  String get welcomeAppTitle;

  /// No description provided for @welcomeOpenRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'OPEN REGISTER'**
  String get welcomeOpenRegisterButton;

  /// No description provided for @welcomeOpenRegisterDescription.
  ///
  /// In en, this message translates to:
  /// **'This device — offline mode'**
  String get welcomeOpenRegisterDescription;

  /// No description provided for @welcomeOpenRegisterFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the local server. Use \"Connect to Server\" instead, or make sure MinePOS is fully installed.'**
  String get welcomeOpenRegisterFailedMessage;

  /// No description provided for @localServerLaunchFailedError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the local server.'**
  String get localServerLaunchFailedError;

  /// No description provided for @welcomeOpenRegisterUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform. Use \"Connect to Server\" instead.'**
  String get welcomeOpenRegisterUnavailableNote;

  /// No description provided for @welcomeOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get welcomeOrDivider;

  /// No description provided for @welcomeConnectServerButton.
  ///
  /// In en, this message translates to:
  /// **'CONNECT TO SERVER'**
  String get welcomeConnectServerButton;

  /// No description provided for @welcomeCreateShopButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE SHOP'**
  String get welcomeCreateShopButton;

  /// No description provided for @welcomeCreateShopUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'This device already has a shop set up. Use \"Open Register\" to sign in.'**
  String get welcomeCreateShopUnavailableNote;

  /// No description provided for @shopAlreadyExistsLocalError.
  ///
  /// In en, this message translates to:
  /// **'This device already has a shop set up. Use \"Open Register\" to sign in instead.'**
  String get shopAlreadyExistsLocalError;

  /// No description provided for @shopAlreadyExistsRemoteError.
  ///
  /// In en, this message translates to:
  /// **'This server already has a shop set up. Ask its owner to sign you in instead of creating a new one.'**
  String get shopAlreadyExistsRemoteError;

  /// No description provided for @welcomeVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'v1.0 · Self-hosted or Cloud'**
  String get welcomeVersionInfo;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginScreenTitle;

  /// No description provided for @loginConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {serverAddress}'**
  String loginConnectedTo(String serverAddress);

  /// No description provided for @usernameOrEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Username / Email'**
  String get usernameOrEmailLabel;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceNameLabel;

  /// No description provided for @deviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Register 1, Front Counter'**
  String get deviceNameHint;

  /// No description provided for @deviceNameRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Device name is required'**
  String get deviceNameRequiredValidator;

  /// No description provided for @defaultDeviceNameOnSetup.
  ///
  /// In en, this message translates to:
  /// **'Main Register'**
  String get defaultDeviceNameOnSetup;

  /// No description provided for @rememberMeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMeLabel;

  /// No description provided for @loginForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get loginForgotPasswordLink;

  /// No description provided for @loginErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get loginErrorMessage;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get loginSignInButton;

  /// No description provided for @loginWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeMessage;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'FORGOT PASSWORD'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email to receive a one-time code.'**
  String get forgotPasswordInstructions;

  /// No description provided for @forgotPasswordValidator.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get forgotPasswordValidator;

  /// No description provided for @forgotPasswordErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'No account found with that username or email.'**
  String get forgotPasswordErrorMessage;

  /// No description provided for @forgotPasswordSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'SEND CODE'**
  String get forgotPasswordSendCodeButton;

  /// No description provided for @forgotPasswordBackLink.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get forgotPasswordBackLink;

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'ENTER CODE'**
  String get otpVerificationTitle;

  /// No description provided for @otpVerificationInstructions.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code was sent to the email\nassociated with {username}.'**
  String otpVerificationInstructions(String username);

  /// No description provided for @otpVerificationIncompleteError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code.'**
  String get otpVerificationIncompleteError;

  /// No description provided for @otpVerificationInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get otpVerificationInvalidError;

  /// No description provided for @otpVerificationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get otpVerificationSuccessMessage;

  /// No description provided for @otpVerificationVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get otpVerificationVerifyButton;

  /// No description provided for @otpVerificationResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpVerificationResendButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW PASSWORD'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your account.'**
  String get resetPasswordInstructions;

  /// No description provided for @resetPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get resetPasswordNewPasswordLabel;

  /// No description provided for @resetPasswordLengthValidator.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get resetPasswordLengthValidator;

  /// No description provided for @resetPasswordConfirmEmptyValidator.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get resetPasswordConfirmEmptyValidator;

  /// No description provided for @resetPasswordErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Reset failed. Please try again.'**
  String get resetPasswordErrorMessage;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please sign in with your new password.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get resetPasswordButton;

  /// No description provided for @connectAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Server'**
  String get connectAppBarTitle;

  /// No description provided for @connectTabWifi.
  ///
  /// In en, this message translates to:
  /// **'ON THIS WI-FI'**
  String get connectTabWifi;

  /// No description provided for @connectTabManual.
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get connectTabManual;

  /// No description provided for @connectManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter server address'**
  String get connectManualTitle;

  /// No description provided for @connectManualInstructions.
  ///
  /// In en, this message translates to:
  /// **'Ask your admin for the address of the MinePOS host.'**
  String get connectManualInstructions;

  /// No description provided for @connectMixedContentWarning.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi discovery isn\'t available in a web browser. If your host address uses http:// and this page is loaded over https://, your browser may block the connection as mixed content.'**
  String get connectMixedContentWarning;

  /// No description provided for @connectServerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get connectServerAddressLabel;

  /// No description provided for @connectServerAddressHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.10:8080'**
  String get connectServerAddressHint;

  /// No description provided for @connectEmptyAddressError.
  ///
  /// In en, this message translates to:
  /// **'Enter a server address'**
  String get connectEmptyAddressError;

  /// No description provided for @connectFailureError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check the address and try again.'**
  String get connectFailureError;

  /// No description provided for @connectNoShopError.
  ///
  /// In en, this message translates to:
  /// **'This server hasn\'t set up a shop yet. Use \"Create Shop\" to set it up first.'**
  String get connectNoShopError;

  /// No description provided for @connectButton.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connectButton;

  /// No description provided for @connectWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Shops on this Wi-Fi'**
  String get connectWifiTitle;

  /// No description provided for @connectWifiInstructions.
  ///
  /// In en, this message translates to:
  /// **'Make sure this device is on the same Wi-Fi as the MinePOS host.'**
  String get connectWifiInstructions;

  /// No description provided for @connectScanButton.
  ///
  /// In en, this message translates to:
  /// **'SCAN FOR SHOPS'**
  String get connectScanButton;

  /// No description provided for @connectScanningLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get connectScanningLabel;

  /// No description provided for @connectNoShopsFound.
  ///
  /// In en, this message translates to:
  /// **'No shops found yet.'**
  String get connectNoShopsFound;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'WHAT IS THIS DEVICE FOR?'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionInstructions.
  ///
  /// In en, this message translates to:
  /// **'You\'ll pick a server to connect to next.'**
  String get roleSelectionInstructions;

  /// No description provided for @roleSelectionCashierTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashier / Manager'**
  String get roleSelectionCashierTitle;

  /// No description provided for @roleSelectionCashierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take orders, manage the shop — signs in normally.'**
  String get roleSelectionCashierSubtitle;

  /// No description provided for @roleSelectionKitchenTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Display'**
  String get roleSelectionKitchenTitle;

  /// No description provided for @roleSelectionKitchenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dedicated kitchen board — signs in, then stays on the board.'**
  String get roleSelectionKitchenSubtitle;

  /// No description provided for @roleSelectionCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Display'**
  String get roleSelectionCustomerTitle;

  /// No description provided for @roleSelectionCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Faces the customer, mirrors the live order — no sign-in.'**
  String get roleSelectionCustomerSubtitle;

  /// No description provided for @shopSetupChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'SET UP THIS DEVICE'**
  String get shopSetupChoiceTitle;

  /// No description provided for @shopSetupChoiceInstructions.
  ///
  /// In en, this message translates to:
  /// **'Start a brand-new shop, or bring an existing one over from another device.'**
  String get shopSetupChoiceInstructions;

  /// No description provided for @shopSetupChoiceFreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get shopSetupChoiceFreshTitle;

  /// No description provided for @shopSetupChoiceFreshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a brand-new shop from scratch.'**
  String get shopSetupChoiceFreshSubtitle;

  /// No description provided for @shopSetupChoiceRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get shopSetupChoiceRestoreTitle;

  /// No description provided for @shopSetupChoiceRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring an existing shop\'s data onto this device.'**
  String get shopSetupChoiceRestoreSubtitle;

  /// No description provided for @restoreShopAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Shop'**
  String get restoreShopAppBarTitle;

  /// No description provided for @restoreShopFileTab.
  ///
  /// In en, this message translates to:
  /// **'Backup File'**
  String get restoreShopFileTab;

  /// No description provided for @restoreShopTransferTab.
  ///
  /// In en, this message translates to:
  /// **'Another Device'**
  String get restoreShopTransferTab;

  /// No description provided for @restoreShopFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get restoreShopFileTitle;

  /// No description provided for @restoreShopFileInstructions.
  ///
  /// In en, this message translates to:
  /// **'Pick a backup file exported from Settings on the old device.'**
  String get restoreShopFileInstructions;

  /// No description provided for @restoreShopChooseFileButton.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE BACKUP FILE'**
  String get restoreShopChooseFileButton;

  /// No description provided for @restoreShopInvalidFileError.
  ///
  /// In en, this message translates to:
  /// **'That file doesn\'t look like a MinePOS backup. Pick a different file.'**
  String get restoreShopInvalidFileError;

  /// No description provided for @restoreShopFoundShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Found shop: {shopName}'**
  String restoreShopFoundShopLabel(String shopName);

  /// No description provided for @restoreShopConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'RESTORE THIS SHOP'**
  String get restoreShopConfirmButton;

  /// No description provided for @restoreShopTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from another device'**
  String get restoreShopTransferTitle;

  /// No description provided for @restoreShopTransferInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of the server currently running the shop you want to move here.'**
  String get restoreShopTransferInstructions;

  /// No description provided for @restoreShopOldOwnerLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in as the owner of that shop to continue.'**
  String get restoreShopOldOwnerLoginLabel;

  /// No description provided for @restoreShopTransferButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN & TRANSFER'**
  String get restoreShopTransferButton;

  /// No description provided for @restoreShopTransferFieldsRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Device name, username, and password are all required.'**
  String get restoreShopTransferFieldsRequiredError;

  /// No description provided for @restoreShopTransferLoginError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in to that server. Check the username and password.'**
  String get restoreShopTransferLoginError;

  /// No description provided for @restoreDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'WHERE DO YOU WANT TO RESTORE THIS?'**
  String get restoreDestinationTitle;

  /// No description provided for @restoreDestinationLocalOption.
  ///
  /// In en, this message translates to:
  /// **'This Device (Local Storage)'**
  String get restoreDestinationLocalOption;

  /// No description provided for @restoreDestinationLocalUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'Not available — either this platform can\'t self-host, or this device already has a shop.'**
  String get restoreDestinationLocalUnavailableNote;

  /// No description provided for @restoreDestinationServerOption.
  ///
  /// In en, this message translates to:
  /// **'Another Server (by IP)'**
  String get restoreDestinationServerOption;

  /// No description provided for @restoreDestinationServerHasShopError.
  ///
  /// In en, this message translates to:
  /// **'That server already has a shop set up. Restore only works on a server that\'s never been set up before.'**
  String get restoreDestinationServerHasShopError;

  /// No description provided for @createShopAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Shop'**
  String get createShopAppBarTitle;

  /// No description provided for @stepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {stepNumber} of {stepCount}'**
  String stepIndicator(int stepNumber, int stepCount);

  /// No description provided for @finishSetupButton.
  ///
  /// In en, this message translates to:
  /// **'FINISH SETUP'**
  String get finishSetupButton;

  /// No description provided for @shopCreatedDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop created!'**
  String get shopCreatedDefaultTitle;

  /// No description provided for @shopReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'{shopName} is ready!'**
  String shopReadyTitle(String shopName);

  /// No description provided for @shopDetailsStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop details'**
  String get shopDetailsStepTitle;

  /// No description provided for @shopDetailsStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your shop.'**
  String get shopDetailsStepSubtitle;

  /// No description provided for @shopLogoTapInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a logo'**
  String get shopLogoTapInstruction;

  /// No description provided for @shopNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopNameFieldLabel;

  /// No description provided for @shopNameFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Cozy Cafe'**
  String get shopNameFieldHint;

  /// No description provided for @shopNameValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Shop name is required'**
  String get shopNameValidatorError;

  /// No description provided for @emailFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// No description provided for @emailFieldHint.
  ///
  /// In en, this message translates to:
  /// **'shop@example.com'**
  String get emailFieldHint;

  /// No description provided for @emailRequiredValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredValidatorError;

  /// No description provided for @emailInvalidValidatorError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalidValidatorError;

  /// No description provided for @addressFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressFieldLabel;

  /// No description provided for @taxIdFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxIdFieldLabel;

  /// No description provided for @receiptFooterFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt Footer'**
  String get receiptFooterFieldLabel;

  /// No description provided for @receiptFooterFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. \"Thank you!\"'**
  String get receiptFooterFieldHint;

  /// No description provided for @shopDetailsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetailsSectionLabel;

  /// No description provided for @shopDetailsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Shop details saved'**
  String get shopDetailsSavedMessage;

  /// No description provided for @shopSetupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Setup failed: {error}'**
  String shopSetupFailedMessage(String error);

  /// No description provided for @adminAccountStepTitle.
  ///
  /// In en, this message translates to:
  /// **'First admin account'**
  String get adminAccountStepTitle;

  /// No description provided for @adminAccountStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This account has full access to MinePOS.'**
  String get adminAccountStepSubtitle;

  /// No description provided for @passwordMinLengthValidatorError.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinLengthValidatorError;

  /// No description provided for @connectionModeStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection mode'**
  String get connectionModeStepTitle;

  /// No description provided for @connectionModeStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How will this shop run?'**
  String get connectionModeStepSubtitle;

  /// No description provided for @localConnectionModeSubtitleWindows.
  ///
  /// In en, this message translates to:
  /// **'No internet needed. Data stays on this PC — other devices connect over Wi-Fi.'**
  String get localConnectionModeSubtitleWindows;

  /// No description provided for @localConnectionModeSubtitleOther.
  ///
  /// In en, this message translates to:
  /// **'Only available on the Windows desktop app.'**
  String get localConnectionModeSubtitleOther;

  /// No description provided for @localConnectionModeSubtitleMobile.
  ///
  /// In en, this message translates to:
  /// **'No internet needed. Data stays on this device only — others can\'t connect.'**
  String get localConnectionModeSubtitleMobile;

  /// No description provided for @cloudConnectionModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server already running elsewhere, by its address.'**
  String get cloudConnectionModeSubtitle;

  /// No description provided for @printerSetupStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Printer setup'**
  String get printerSetupStepTitle;

  /// No description provided for @printerSetupStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how receipts will print. You can change this later.'**
  String get printerSetupStepSubtitle;

  /// No description provided for @bluetoothPrinterOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a Bluetooth thermal printer'**
  String get bluetoothPrinterOptionSubtitle;

  /// No description provided for @usbPrinterOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a USB thermal printer'**
  String get usbPrinterOptionSubtitle;

  /// No description provided for @skipPrinterOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipPrinterOptionTitle;

  /// No description provided for @skipPrinterOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a printer later from Settings'**
  String get skipPrinterOptionSubtitle;

  /// No description provided for @printerDiscoveryNote.
  ///
  /// In en, this message translates to:
  /// **'Tap Print on a receipt to scan for a paired printer — make sure it\'s on and in range.'**
  String get printerDiscoveryNote;

  /// No description provided for @setupSummaryStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & finish'**
  String get setupSummaryStepTitle;

  /// No description provided for @setupSummaryStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check everything looks right before creating your shop.'**
  String get setupSummaryStepSubtitle;

  /// No description provided for @summaryRowLabelAdminUsername.
  ///
  /// In en, this message translates to:
  /// **'Admin Username'**
  String get summaryRowLabelAdminUsername;

  /// No description provided for @summaryRowLabelConnectionMode.
  ///
  /// In en, this message translates to:
  /// **'Connection Mode'**
  String get summaryRowLabelConnectionMode;

  /// No description provided for @summaryRowLabelPrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get summaryRowLabelPrinter;

  /// No description provided for @summaryPrinterSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped for now'**
  String get summaryPrinterSkippedLabel;

  /// No description provided for @clearOrderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Order?'**
  String get clearOrderDialogTitle;

  /// No description provided for @clearOrderDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Remove all items from the current order?'**
  String get clearOrderDialogContent;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @newOrderAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrderAppBarTitle;

  /// No description provided for @clearOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear order'**
  String get clearOrderTooltip;

  /// No description provided for @orderHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get orderHistoryTooltip;

  /// No description provided for @cartTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTabLabel;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order  #{number}'**
  String orderNumberLabel(String number);

  /// No description provided for @emptyCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap items\nto add to order'**
  String get emptyCartMessage;

  /// No description provided for @proceedToPayButton.
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO PAY'**
  String get proceedToPayButton;

  /// No description provided for @paymentAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentAppBarTitle;

  /// No description provided for @orderSummaryHeader.
  ///
  /// In en, this message translates to:
  /// **'ORDER SUMMARY'**
  String get orderSummaryHeader;

  /// No description provided for @amountReceivedHeader.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT RECEIVED'**
  String get amountReceivedHeader;

  /// No description provided for @amountLessThanTotalError.
  ///
  /// In en, this message translates to:
  /// **'Amount is less than total'**
  String get amountLessThanTotalError;

  /// No description provided for @promptpayConfigMessage.
  ///
  /// In en, this message translates to:
  /// **'Configure PromptPay ID\nin Settings to enable'**
  String get promptpayConfigMessage;

  /// No description provided for @scanQrToPayMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to pay'**
  String get scanQrToPayMessage;

  /// No description provided for @confirmPaymentButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PAYMENT  •  {total}'**
  String confirmPaymentButton(String total);

  /// No description provided for @receiptAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt {orderNumber}'**
  String receiptAppBarTitle(String orderNumber);

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'MinePOS Coffee'**
  String get businessName;

  /// No description provided for @receiptThankYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order!'**
  String get receiptThankYouMessage;

  /// No description provided for @receiptOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get receiptOrderLabel;

  /// No description provided for @receiptDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDateLabel;

  /// No description provided for @receiptPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get receiptPaymentLabel;

  /// No description provided for @receiptClosingMessage.
  ///
  /// In en, this message translates to:
  /// **'— See you again! —'**
  String get receiptClosingMessage;

  /// No description provided for @printButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'PRINT'**
  String get printButtonLabel;

  /// No description provided for @printingInProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Printing…'**
  String get printingInProgressMessage;

  /// No description provided for @printSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to printer.'**
  String get printSuccessMessage;

  /// No description provided for @printNoPrinterMessage.
  ///
  /// In en, this message translates to:
  /// **'No printer found. Check it\'s on and in range.'**
  String get printNoPrinterMessage;

  /// No description provided for @printFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t print: {error}'**
  String printFailedMessage(String error);

  /// No description provided for @printSkippedMessage.
  ///
  /// In en, this message translates to:
  /// **'No printer selected — set one up in Settings.'**
  String get printSkippedMessage;

  /// No description provided for @orderHistoryAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryAppBarTitle;

  /// No description provided for @noOrdersMessage.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersMessage;

  /// No description provided for @noMenuItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No menu items yet — add some in Menu Management'**
  String get noMenuItemsMessage;

  /// No description provided for @orderItemsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}  •  {paymentMethod}'**
  String orderItemsSummary(int count, String paymentMethod);

  /// No description provided for @exitCustomerDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Customer Display?'**
  String get exitCustomerDisplayTitle;

  /// No description provided for @exitCustomerDisplayContent.
  ///
  /// In en, this message translates to:
  /// **'This returns to the welcome screen.'**
  String get exitCustomerDisplayContent;

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @welcomeToMinePosMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MinePOS'**
  String get welcomeToMinePosMessage;

  /// No description provided for @orderWillAppearMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order will appear here'**
  String get orderWillAppearMessage;

  /// No description provided for @selectStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Station'**
  String get selectStationTitle;

  /// No description provided for @noStationsOnlineMessage.
  ///
  /// In en, this message translates to:
  /// **'No stations are online yet. Open a register and start an order.'**
  String get noStationsOnlineMessage;

  /// No description provided for @customerDisplayOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Order'**
  String get customerDisplayOrderLabel;

  /// No description provided for @customerDisplayOrderWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNumber}'**
  String customerDisplayOrderWithNumber(String orderNumber);

  /// No description provided for @thankYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thankYouMessage;

  /// No description provided for @totalPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Total paid: {amount}'**
  String totalPaidLabel(String amount);

  /// No description provided for @changeMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Change: {amount}'**
  String changeMessageLabel(String amount);

  /// No description provided for @goodMorningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorningGreeting;

  /// No description provided for @goodAfternoonGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoonGreeting;

  /// No description provided for @goodEveningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEveningGreeting;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get signOutDialogTitle;

  /// No description provided for @signOutDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the welcome screen.'**
  String get signOutDialogContent;

  /// No description provided for @desktopDashboardNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get desktopDashboardNavLabel;

  /// No description provided for @menuMgmtNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu Mgmt'**
  String get menuMgmtNavLabel;

  /// No description provided for @kitchenNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get kitchenNavLabel;

  /// No description provided for @defaultAdminUsername.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get defaultAdminUsername;

  /// No description provided for @mobileBottomNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get mobileBottomNavHome;

  /// No description provided for @mobileBottomNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get mobileBottomNavOrders;

  /// No description provided for @mobileBottomNavMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get mobileBottomNavMore;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, Admin'**
  String greetingWithName(String greeting);

  /// No description provided for @homeOrdersTodayStat.
  ///
  /// In en, this message translates to:
  /// **'Orders Today'**
  String get homeOrdersTodayStat;

  /// No description provided for @recentOrdersHeader.
  ///
  /// In en, this message translates to:
  /// **'RECENT ORDERS'**
  String get recentOrdersHeader;

  /// No description provided for @viewAllOrdersLink.
  ///
  /// In en, this message translates to:
  /// **'View all →'**
  String get viewAllOrdersLink;

  /// No description provided for @noOrdersTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'No orders yet today'**
  String get noOrdersTodayMessage;

  /// No description provided for @recentOrderQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get recentOrderQrLabel;

  /// No description provided for @menuManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Management'**
  String get menuManagementTitle;

  /// No description provided for @addItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTooltip;

  /// No description provided for @noItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in this category.'**
  String get noItemsEmpty;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item?'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{itemName}\" from the menu? This cannot be undone.'**
  String deleteItemContent(String itemName);

  /// No description provided for @deleteItemSnackbar.
  ///
  /// In en, this message translates to:
  /// **'\"{itemName}\" removed'**
  String deleteItemSnackbar(String itemName);

  /// No description provided for @editItemFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItemFormTitle;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name (English)'**
  String get itemNameLabel;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Caramel Latte'**
  String get itemNameHint;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get itemNameRequired;

  /// No description provided for @itemNameThLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name (Thai)'**
  String get itemNameThLabel;

  /// No description provided for @itemNameThHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. คาราเมลลาเต้'**
  String get itemNameThHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee'**
  String get categoryHint;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequired;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get priceHint;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @priceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get priceInvalid;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available on menu'**
  String get availableLabel;

  /// No description provided for @hasSweetnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask sweetness level'**
  String get hasSweetnessLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @selectSweetnessTitle.
  ///
  /// In en, this message translates to:
  /// **'Sweetness level'**
  String get selectSweetnessTitle;

  /// No description provided for @sweetnessLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get sweetnessLess;

  /// No description provided for @sweetnessNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get sweetnessNormal;

  /// No description provided for @sweetnessSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get sweetnessSweet;

  /// No description provided for @todayRange.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayRange;

  /// No description provided for @yesterdayRange.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayRange;

  /// No description provided for @last7Range.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Range;

  /// No description provided for @last30Range.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Range;

  /// No description provided for @allTimeRange.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTimeRange;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get customRange;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTimeLabel;

  /// No description provided for @customRangeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRangeDialogTitle;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @endBeforeStartError.
  ///
  /// In en, this message translates to:
  /// **'End must be after start'**
  String get endBeforeStartError;

  /// No description provided for @reportsOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get reportsOrdersLabel;

  /// No description provided for @ordersColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'ORDERS'**
  String get ordersColumnHeader;

  /// No description provided for @topSellingItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'TOP SELLING ITEMS'**
  String get topSellingItemsHeader;

  /// No description provided for @salesTrendHeader.
  ///
  /// In en, this message translates to:
  /// **'SALES TREND'**
  String get salesTrendHeader;

  /// No description provided for @soldSuffix.
  ///
  /// In en, this message translates to:
  /// **'sold'**
  String get soldSuffix;

  /// No description provided for @exportCSVButton.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCSVButton;

  /// No description provided for @reportsNoOrdersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders in this range'**
  String get reportsNoOrdersEmpty;

  /// No description provided for @exportCancelledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelledSnackbar;

  /// No description provided for @exportSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportSuccessSnackbar(String path);

  /// No description provided for @exportFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedSnackbar(String error);

  /// No description provided for @cancelOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderLabel;

  /// No description provided for @cancelOrderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderDialogTitle;

  /// No description provided for @cancelOrderSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get cancelOrderSnackbar;

  /// No description provided for @cancelOrderFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel: {error}'**
  String cancelOrderFailedSnackbar(String error);

  /// No description provided for @cancelledOrderBadge.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledOrderBadge;

  /// No description provided for @cancelReasonPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling this order?'**
  String get cancelReasonPromptLabel;

  /// No description provided for @cancelReasonCustomerChanged.
  ///
  /// In en, this message translates to:
  /// **'Customer changed their mind'**
  String get cancelReasonCustomerChanged;

  /// No description provided for @cancelReasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate order'**
  String get cancelReasonDuplicate;

  /// No description provided for @cancelReasonWrongItem.
  ///
  /// In en, this message translates to:
  /// **'Wrong item entered'**
  String get cancelReasonWrongItem;

  /// No description provided for @cancelReasonOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Item out of stock'**
  String get cancelReasonOutOfStock;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @cancelReasonExtraHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get cancelReasonExtraHint;

  /// No description provided for @cancelReasonRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get cancelReasonRequiredError;

  /// No description provided for @staffManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagementTitle;

  /// No description provided for @addStaffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaffTooltip;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get youLabel;

  /// No description provided for @forceSignoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Force sign-out'**
  String get forceSignoutTooltip;

  /// No description provided for @removeStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff?'**
  String get removeStaffTitle;

  /// No description provided for @removeStaffContent.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove \"{username}\" from the system? This cannot be undone.'**
  String removeStaffContent(String username);

  /// No description provided for @signedOutSnackbar.
  ///
  /// In en, this message translates to:
  /// **'\"{username}\" signed out on all devices'**
  String signedOutSnackbar(String username);

  /// No description provided for @addStaffLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaffLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. jane'**
  String get usernameHint;

  /// No description provided for @staffPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get staffPasswordLabel;

  /// No description provided for @staffPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get staffPasswordHint;

  /// No description provided for @staffPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get staffPasswordTooShort;

  /// No description provided for @editStaffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editStaffTooltip;

  /// No description provided for @editStaffLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Staff'**
  String get editStaffLabel;

  /// No description provided for @staffPasswordEditHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current password'**
  String get staffPasswordEditHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @phoneFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneFieldLabel;

  /// No description provided for @phoneFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 081-234-5678'**
  String get phoneFieldHint;

  /// No description provided for @staffNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffNameLabel;

  /// No description provided for @staffNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jane Smith'**
  String get staffNameHint;

  /// No description provided for @confirmYourPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get confirmYourPasswordLabel;

  /// No description provided for @confirmYourPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to change this username'**
  String get confirmYourPasswordHint;

  /// No description provided for @confirmYourPasswordRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Your password is required to change a username'**
  String get confirmYourPasswordRequiredValidator;

  /// No description provided for @settingsAccountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settingsAccountSectionLabel;

  /// No description provided for @signedInAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get signedInAsLabel;

  /// No description provided for @connectionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'CONNECTION'**
  String get connectionSectionLabel;

  /// No description provided for @settingsServerAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get settingsServerAddressLabel;

  /// No description provided for @disconnectLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectLabel;

  /// No description provided for @disconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Server?'**
  String get disconnectTitle;

  /// No description provided for @disconnectContent.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out and returned to the welcome screen.'**
  String get disconnectContent;

  /// No description provided for @printerSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'PRINTER'**
  String get printerSectionLabel;

  /// No description provided for @noPrinterOption.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noPrinterOption;

  /// No description provided for @selectedPrinterLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get selectedPrinterLabel;

  /// No description provided for @printerNotSelectedValue.
  ///
  /// In en, this message translates to:
  /// **'Auto (first found)'**
  String get printerNotSelectedValue;

  /// No description provided for @selectPrinterButton.
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinterButton;

  /// No description provided for @changePrinterButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changePrinterButton;

  /// No description provided for @selectPrinterDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinterDialogTitle;

  /// No description provided for @noPrintersFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No printers found. Make sure it\'s on and in range.'**
  String get noPrintersFoundMessage;

  /// No description provided for @scanningForPrintersLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanning for printers…'**
  String get scanningForPrintersLabel;

  /// No description provided for @loadingPairedPrintersLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking paired printers…'**
  String get loadingPairedPrintersLabel;

  /// No description provided for @scanForPrintersButton.
  ///
  /// In en, this message translates to:
  /// **'SCAN'**
  String get scanForPrintersButton;

  /// No description provided for @noPairedPrintersMessage.
  ///
  /// In en, this message translates to:
  /// **'No paired printers. Pair one in Bluetooth settings, or scan for nearby devices.'**
  String get noPairedPrintersMessage;

  /// No description provided for @bluetoothPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission is required to find printers. Enable it for this app in phone Settings.'**
  String get bluetoothPermissionDeniedMessage;

  /// No description provided for @paperSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Paper Size'**
  String get paperSizeLabel;

  /// No description provided for @paperSize58.
  ///
  /// In en, this message translates to:
  /// **'58mm'**
  String get paperSize58;

  /// No description provided for @paperSize80.
  ///
  /// In en, this message translates to:
  /// **'80mm'**
  String get paperSize80;

  /// No description provided for @languageSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSectionLabel;

  /// No description provided for @englishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishOption;

  /// No description provided for @thaiOption.
  ///
  /// In en, this message translates to:
  /// **'ภาษาไทย (Thai)'**
  String get thaiOption;

  /// No description provided for @backupSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'BACKUP'**
  String get backupSectionLabel;

  /// No description provided for @exportBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackupButton;

  /// No description provided for @exportBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your shop\'s data — accounts, menu, and orders — to move it to another device.'**
  String get exportBackupHint;

  /// No description provided for @exportBackupSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup saved.'**
  String get exportBackupSavedMessage;

  /// No description provided for @exportBackupCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled.'**
  String get exportBackupCancelledMessage;

  /// No description provided for @exportBackupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export the backup. Try again.'**
  String get exportBackupFailedMessage;

  /// No description provided for @dangerZoneSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZoneSectionLabel;

  /// No description provided for @removeShopButton.
  ///
  /// In en, this message translates to:
  /// **'REMOVE SHOP'**
  String get removeShopButton;

  /// No description provided for @removeShopWarningText.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes this shop and all its data — accounts, menu, orders — from the server. This cannot be undone.'**
  String get removeShopWarningText;

  /// No description provided for @removeShopDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this shop?'**
  String get removeShopDialogTitle;

  /// No description provided for @removeShopDialogWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every account, menu item, and order on this server, and signs out every connected device. This cannot be undone.'**
  String get removeShopDialogWarning;

  /// No description provided for @removeShopEmailHint.
  ///
  /// In en, this message translates to:
  /// **'This shop\'s registered email'**
  String get removeShopEmailHint;

  /// No description provided for @removeShopConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE SHOP'**
  String get removeShopConfirmButton;

  /// No description provided for @backToDashboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboardTooltip;

  /// No description provided for @cropImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImageTitle;

  /// No description provided for @cropConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cropConfirmButton;

  /// No description provided for @cropHintText.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom • Drag to reposition'**
  String get cropHintText;

  /// No description provided for @gridViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridViewTooltip;

  /// No description provided for @listViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listViewTooltip;

  /// No description provided for @extraDisplaySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'EXTRA DISPLAY'**
  String get extraDisplaySectionLabel;

  /// No description provided for @openExtraDisplayButton.
  ///
  /// In en, this message translates to:
  /// **'Open Extra Display'**
  String get openExtraDisplayButton;

  /// No description provided for @openExtraDisplayHint.
  ///
  /// In en, this message translates to:
  /// **'Opens in a new window, already signed in — drag it to a second monitor.'**
  String get openExtraDisplayHint;

  /// No description provided for @openExtraDisplayFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the extra display window'**
  String get openExtraDisplayFailedMessage;

  /// No description provided for @serverSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get serverSectionLabel;

  /// No description provided for @serverStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Server Status'**
  String get serverStatusButton;

  /// No description provided for @serverStatusRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get serverStatusRunningLabel;

  /// No description provided for @serverStatusStoppedLabel.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get serverStatusStoppedLabel;

  /// No description provided for @restartServerButton.
  ///
  /// In en, this message translates to:
  /// **'Restart Server'**
  String get restartServerButton;

  /// No description provided for @restartServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the server?'**
  String get restartServerTitle;

  /// No description provided for @restartServerContent.
  ///
  /// In en, this message translates to:
  /// **'Every connected device — kitchen display, other cashiers, customer display — will briefly disconnect while it restarts.'**
  String get restartServerContent;

  /// No description provided for @restartingServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Restarting…'**
  String get restartingServerMessage;

  /// No description provided for @restartServerFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restart automatically. Close and reopen the app if it doesn\'t come back.'**
  String get restartServerFailedMessage;

  /// No description provided for @startServerButton.
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get startServerButton;

  /// No description provided for @startingServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get startingServerMessage;

  /// No description provided for @startServerFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start automatically. Check the log for details.'**
  String get startServerFailedMessage;

  /// No description provided for @liveActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get liveActivityTitle;

  /// No description provided for @usersOnlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Users online'**
  String get usersOnlineLabel;

  /// No description provided for @noUsersOnlineMessage.
  ///
  /// In en, this message translates to:
  /// **'No one else is signed in right now.'**
  String get noUsersOnlineMessage;

  /// No description provided for @kitchenDisplaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Kitchen displays'**
  String get kitchenDisplaysLabel;

  /// No description provided for @customerDisplaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer displays'**
  String get customerDisplaysLabel;

  /// No description provided for @viewLogsButton.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogsButton;

  /// No description provided for @serverLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Logs'**
  String get serverLogsTitle;

  /// No description provided for @serverLogsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No log file found yet — this only appears on the Windows device hosting the shop.'**
  String get serverLogsEmptyMessage;

  /// No description provided for @copyLogsButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLogsButton;

  /// No description provided for @logsCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logsCopiedSnackbar;

  /// No description provided for @openLogFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Open Log Folder'**
  String get openLogFolderButton;

  /// No description provided for @kitchenDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Display'**
  String get kitchenDisplayTitle;

  /// No description provided for @signOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTooltip;

  /// No description provided for @liveConnectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveConnectionLabel;

  /// No description provided for @connectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingLabel;

  /// No description provided for @reconnectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnectingLabel;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @newColumnTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newColumnTitle;

  /// No description provided for @preparingColumnTitle.
  ///
  /// In en, this message translates to:
  /// **'PREPARING'**
  String get preparingColumnTitle;

  /// No description provided for @readyColumnTitle.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get readyColumnTitle;

  /// No description provided for @completeButton.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeButton;

  /// No description provided for @kitchenNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get kitchenNoOrders;

  /// No description provided for @justNowElapsed.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNowElapsed;

  /// No description provided for @oneMinAgoElapsed.
  ///
  /// In en, this message translates to:
  /// **'1 min ago'**
  String get oneMinAgoElapsed;

  /// No description provided for @minAgoElapsed.
  ///
  /// In en, this message translates to:
  /// **'{mins} min ago'**
  String minAgoElapsed(int mins);

  /// No description provided for @pendingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatusLabel;

  /// No description provided for @preparingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparingStatusLabel;

  /// No description provided for @readyStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get readyStatusLabel;

  /// No description provided for @updateOrderErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not update order: {error}'**
  String updateOrderErrorSnackbar(String error);

  /// No description provided for @updateItemErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not update item: {error}'**
  String updateItemErrorSnackbar(String error);

  /// No description provided for @accessRestrictedMessage.
  ///
  /// In en, this message translates to:
  /// **'{feature} is only available to managers and owners.'**
  String accessRestrictedMessage(String feature);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

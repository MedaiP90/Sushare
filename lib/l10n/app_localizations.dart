import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// The app title
  ///
  /// In en, this message translates to:
  /// **'Sushare'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @navTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get navTables;

  /// No description provided for @navRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get navRestaurants;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sushare'**
  String get welcomeTitle;

  /// No description provided for @onboardingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Table'**
  String get onboardingCreateTitle;

  /// No description provided for @onboardingCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a new session, invite friends, and share the bill together.'**
  String get onboardingCreateDescription;

  /// No description provided for @onboardingJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Table'**
  String get onboardingJoinTitle;

  /// No description provided for @onboardingJoinDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or enter a code to join your friends\' session.'**
  String get onboardingJoinDescription;

  /// No description provided for @onboardingEnjoyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the Meal'**
  String get onboardingEnjoyTitle;

  /// No description provided for @onboardingEnjoyDescription.
  ///
  /// In en, this message translates to:
  /// **'Place your order, track the merged order, and split the bill fairly.'**
  String get onboardingEnjoyDescription;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile'**
  String get profileSetupSubtitle;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get labelUsername;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username'**
  String get hintUsername;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get validationUsernameMinLength;

  /// No description provided for @labelFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get labelFirstName;

  /// No description provided for @hintFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get hintFirstName;

  /// No description provided for @validationFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get validationFirstNameRequired;

  /// No description provided for @labelLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get labelLastName;

  /// No description provided for @hintLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get hintLastName;

  /// No description provided for @validationLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get validationLastNameRequired;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @errorSavingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String errorSavingProfile(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsSectionProfile;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAiService.
  ///
  /// In en, this message translates to:
  /// **'AI Service'**
  String get settingsSectionAiService;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No profile'**
  String get settingsNoProfile;

  /// No description provided for @settingsNoProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a profile to get started'**
  String get settingsNoProfileSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsGeminiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Google Gemini API Key'**
  String get settingsGeminiApiKey;

  /// No description provided for @settingsGeminiApiKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'For menu scanning'**
  String get settingsGeminiApiKeySubtitle;

  /// No description provided for @settingsAiModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get settingsAiModel;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEnglish;

  /// No description provided for @settingsLangItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get settingsLangItalian;

  /// No description provided for @settingsLangSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLangSpanish;

  /// No description provided for @settingsLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLangFrench;

  /// No description provided for @settingsLangGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get settingsLangGerman;

  /// No description provided for @settingsApiKeySetFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set your API key first'**
  String get settingsApiKeySetFirst;

  /// No description provided for @settingsApiKeyFetchError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch models from API. Using default.'**
  String get settingsApiKeyFetchError;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsApiKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your Google Gemini API key for menu scanning functionality.'**
  String get settingsApiKeyDescription;

  /// No description provided for @settingsApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get settingsApiKeyLabel;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get sessionsTitle;

  /// No description provided for @sessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tables yet'**
  String get sessionsEmpty;

  /// No description provided for @sessionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new table to order together, or join one from a friend.'**
  String get sessionsEmptySubtitle;

  /// No description provided for @sessionsNewTable.
  ///
  /// In en, this message translates to:
  /// **'New Table'**
  String get sessionsNewTable;

  /// No description provided for @sessionsJoinTable.
  ///
  /// In en, this message translates to:
  /// **'Join a Table'**
  String get sessionsJoinTable;

  /// No description provided for @sessionsJoinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Join table'**
  String get sessionsJoinTooltip;

  /// No description provided for @sessionStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get sessionStatusOpen;

  /// No description provided for @sessionStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Order sent'**
  String get sessionStatusSent;

  /// No description provided for @sessionStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get sessionStatusClosed;

  /// No description provided for @sessionCardHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get sessionCardHost;

  /// No description provided for @sessionCardUnknownRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Unknown restaurant'**
  String get sessionCardUnknownRestaurant;

  /// No description provided for @sessionTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get sessionTimeJustNow;

  /// No description provided for @sessionTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String sessionTimeMinutesAgo(int count);

  /// No description provided for @sessionTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String sessionTimeHoursAgo(int count);

  /// No description provided for @sessionTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String sessionTimeDaysAgo(int count);

  /// No description provided for @sessionActionsShareTable.
  ///
  /// In en, this message translates to:
  /// **'Share table'**
  String get sessionActionsShareTable;

  /// No description provided for @sessionActionsLeaveTable.
  ///
  /// In en, this message translates to:
  /// **'Leave the table'**
  String get sessionActionsLeaveTable;

  /// No description provided for @sessionLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the table'**
  String get sessionLeaveTitle;

  /// No description provided for @sessionLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'The table will be frozen. No one will be able to join or make changes.'**
  String get sessionLeaveMessage;

  /// No description provided for @sessionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Table'**
  String get sessionDeleteTitle;

  /// No description provided for @sessionDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String sessionDeleteMessage(String name);

  /// No description provided for @shareTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Table'**
  String get shareTableTitle;

  /// No description provided for @shareTableQrHint.
  ///
  /// In en, this message translates to:
  /// **'Let others join by scanning this QR code:'**
  String get shareTableQrHint;

  /// No description provided for @shareTableCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Or enter this code:'**
  String get shareTableCodeHint;

  /// No description provided for @joinTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Table'**
  String get joinTableTitle;

  /// No description provided for @joinTableHeading.
  ///
  /// In en, this message translates to:
  /// **'Join a table'**
  String get joinTableHeading;

  /// No description provided for @joinTableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the table code or scan the QR code'**
  String get joinTableSubtitle;

  /// No description provided for @joinTableScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get joinTableScanQr;

  /// No description provided for @joinTableOpenScanner.
  ///
  /// In en, this message translates to:
  /// **'Open Scanner'**
  String get joinTableOpenScanner;

  /// No description provided for @joinTableEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Code Manually'**
  String get joinTableEnterCode;

  /// No description provided for @joinTableCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Table Code'**
  String get joinTableCodeLabel;

  /// No description provided for @joinTableCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., ABC12345'**
  String get joinTableCodeHint;

  /// No description provided for @joinTableJoin.
  ///
  /// In en, this message translates to:
  /// **'Join Table'**
  String get joinTableJoin;

  /// No description provided for @joinTableStartNew.
  ///
  /// In en, this message translates to:
  /// **'Or start a new table'**
  String get joinTableStartNew;

  /// No description provided for @joinTableScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code'**
  String get joinTableScanHint;

  /// No description provided for @joinTableHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Host address'**
  String get joinTableHostLabel;

  /// No description provided for @joinTableHostHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 192.168.1.100:8080'**
  String get joinTableHostHint;

  /// No description provided for @joinTableClosedError.
  ///
  /// In en, this message translates to:
  /// **'This table is closed'**
  String get joinTableClosedError;

  /// No description provided for @newTableTitle.
  ///
  /// In en, this message translates to:
  /// **'New Table'**
  String get newTableTitle;

  /// No description provided for @newTableHeading.
  ///
  /// In en, this message translates to:
  /// **'Start a new ordering table'**
  String get newTableHeading;

  /// No description provided for @newTableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a table and invite others to join'**
  String get newTableSubtitle;

  /// No description provided for @newTableNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Table Name'**
  String get newTableNameLabel;

  /// No description provided for @newTableNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Friday dinner'**
  String get newTableNameHint;

  /// No description provided for @newTableNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a table name'**
  String get newTableNameRequired;

  /// No description provided for @newTableSelectRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Select Restaurant (optional)'**
  String get newTableSelectRestaurant;

  /// No description provided for @newTableNoRestaurants.
  ///
  /// In en, this message translates to:
  /// **'No restaurants saved yet'**
  String get newTableNoRestaurants;

  /// No description provided for @newTableNoRestaurantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A restaurant will be created automatically when you start the table.'**
  String get newTableNoRestaurantsSubtitle;

  /// No description provided for @newTableAddRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add a restaurant'**
  String get newTableAddRestaurant;

  /// No description provided for @newTableMenuItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String newTableMenuItems(int count);

  /// No description provided for @newTableStart.
  ///
  /// In en, this message translates to:
  /// **'Start Table'**
  String get newTableStart;

  /// No description provided for @newTableError.
  ///
  /// In en, this message translates to:
  /// **'Error creating table: {error}'**
  String newTableError(String error);

  /// No description provided for @restaurantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurantsTitle;

  /// No description provided for @restaurantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No restaurants yet'**
  String get restaurantsEmpty;

  /// No description provided for @restaurantsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first restaurant to get started'**
  String get restaurantsEmptySubtitle;

  /// No description provided for @restaurantsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Restaurant'**
  String get restaurantsAdd;

  /// No description provided for @restaurantDishes.
  ///
  /// In en, this message translates to:
  /// **'{count} dishes'**
  String restaurantDishes(int count);

  /// No description provided for @restaurantTemplatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} templates'**
  String restaurantTemplatesCount(int count);

  /// No description provided for @restaurantDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Restaurant'**
  String get restaurantDeleteTitle;

  /// No description provided for @restaurantDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String restaurantDeleteMessage(String name);

  /// No description provided for @restaurantAddCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Cover Photo'**
  String get restaurantAddCoverPhoto;

  /// No description provided for @restaurantAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Restaurant'**
  String get restaurantAddTitle;

  /// No description provided for @restaurantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name'**
  String get restaurantNameLabel;

  /// No description provided for @restaurantAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get restaurantAddressLabel;

  /// No description provided for @restaurantEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Restaurant'**
  String get restaurantEditTitle;

  /// No description provided for @restaurantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Restaurant not found'**
  String get restaurantNotFound;

  /// No description provided for @restaurantOrderTemplates.
  ///
  /// In en, this message translates to:
  /// **'Order Templates'**
  String get restaurantOrderTemplates;

  /// No description provided for @restaurantTemplatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Add one here or save from a personal order.'**
  String get restaurantTemplatesEmpty;

  /// No description provided for @restaurantMenuSection.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get restaurantMenuSection;

  /// No description provided for @restaurantScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get restaurantScanButton;

  /// No description provided for @restaurantMenuMarkYummie.
  ///
  /// In en, this message translates to:
  /// **'Mark as Yummie'**
  String get restaurantMenuMarkYummie;

  /// No description provided for @restaurantMenuRemoveYummie.
  ///
  /// In en, this message translates to:
  /// **'Remove Yummie'**
  String get restaurantMenuRemoveYummie;

  /// No description provided for @restaurantTemplateDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get restaurantTemplateDeleteTitle;

  /// No description provided for @restaurantTemplateDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String restaurantTemplateDeleteMessage(String name);

  /// No description provided for @restaurantTemplateReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace Template'**
  String get restaurantTemplateReplaceTitle;

  /// No description provided for @restaurantTemplateReplaceMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you also want to delete the old version?'**
  String get restaurantTemplateReplaceMessage;

  /// No description provided for @restaurantTemplateNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Order Template'**
  String get restaurantTemplateNewTitle;

  /// No description provided for @restaurantTemplateEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Order Template'**
  String get restaurantTemplateEditTitle;

  /// No description provided for @restaurantTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get restaurantTemplateNameLabel;

  /// No description provided for @restaurantTemplateSelectDishes.
  ///
  /// In en, this message translates to:
  /// **'Select dishes to include:'**
  String get restaurantTemplateSelectDishes;

  /// No description provided for @restaurantTemplateSave.
  ///
  /// In en, this message translates to:
  /// **'Save template ({count} items)'**
  String restaurantTemplateSave(int count);

  /// No description provided for @restaurantMenuItemEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get restaurantMenuItemEditTitle;

  /// No description provided for @restaurantMenuItemAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Menu Item'**
  String get restaurantMenuItemAddTitle;

  /// No description provided for @restaurantMenuItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get restaurantMenuItemNameLabel;

  /// No description provided for @restaurantMenuItemDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get restaurantMenuItemDescLabel;

  /// No description provided for @restaurantMenuItemNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Number'**
  String get restaurantMenuItemNumberLabel;

  /// No description provided for @sessionTableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Table not found'**
  String get sessionTableNotFound;

  /// No description provided for @sessionShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share table'**
  String get sessionShareTooltip;

  /// No description provided for @sessionLeaveTableMenu.
  ///
  /// In en, this message translates to:
  /// **'Leave the table'**
  String get sessionLeaveTableMenu;

  /// No description provided for @sessionDeleteTableMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get sessionDeleteTableMenu;

  /// No description provided for @sessionCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Table'**
  String get sessionCloseTitle;

  /// No description provided for @sessionCloseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Participants won\'t be able to join or order.'**
  String get sessionCloseMessage;

  /// No description provided for @sessionCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sessionCloseButton;

  /// No description provided for @sessionDeleteMessage2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this table?'**
  String get sessionDeleteMessage2;

  /// No description provided for @sessionClosedBanner.
  ///
  /// In en, this message translates to:
  /// **'This table has been left — no further changes can be made'**
  String get sessionClosedBanner;

  /// No description provided for @sessionUnreachableBanner.
  ///
  /// In en, this message translates to:
  /// **'Session temporarily unreachable — waiting for the host to reconnect'**
  String get sessionUnreachableBanner;

  /// No description provided for @sessionTabMyOrder.
  ///
  /// In en, this message translates to:
  /// **'My Order'**
  String get sessionTabMyOrder;

  /// No description provided for @sessionTabGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get sessionTabGroup;

  /// No description provided for @sessionTabChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get sessionTabChecklist;

  /// No description provided for @checklistComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get checklistComplete;

  /// No description provided for @checklistHostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track what has arrived from all orders'**
  String get checklistHostSubtitle;

  /// No description provided for @checklistGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track what has arrived from your dishes'**
  String get checklistGuestSubtitle;

  /// No description provided for @checklistNoOrder.
  ///
  /// In en, this message translates to:
  /// **'No order to track'**
  String get checklistNoOrder;

  /// No description provided for @checklistNoOrderHint.
  ///
  /// In en, this message translates to:
  /// **'The order hasn\'t been sent yet'**
  String get checklistNoOrderHint;

  /// No description provided for @checklistArrivedOf.
  ///
  /// In en, this message translates to:
  /// **'{arrived} of {total} arrived'**
  String checklistArrivedOf(int arrived, int total);

  /// No description provided for @checklistHostOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the host can update arrival status'**
  String get checklistHostOnly;

  /// No description provided for @checklistOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String checklistOrderLabel(int number);

  /// No description provided for @checklistItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String checklistItemsCount(int count);

  /// No description provided for @mergedOrderParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get mergedOrderParticipants;

  /// No description provided for @mergedOrderWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for all participants to lock their orders'**
  String get mergedOrderWaiting;

  /// No description provided for @mergedOrderSend.
  ///
  /// In en, this message translates to:
  /// **'Send Order'**
  String get mergedOrderSend;

  /// No description provided for @mergedOrderOpenRound.
  ///
  /// In en, this message translates to:
  /// **'Open New Round'**
  String get mergedOrderOpenRound;

  /// No description provided for @mergedOrderCurrentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Current Order — empty'**
  String get mergedOrderCurrentEmpty;

  /// No description provided for @mergedOrderNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get mergedOrderNoItems;

  /// No description provided for @mergedOrderBy.
  ///
  /// In en, this message translates to:
  /// **'By {count} participant(s)'**
  String mergedOrderBy(int count);

  /// No description provided for @mergedOrderItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String mergedOrderItemsCount(int count);

  /// No description provided for @mergedOrderSendLocked.
  ///
  /// In en, this message translates to:
  /// **'All participants must lock their orders first'**
  String get mergedOrderSendLocked;

  /// No description provided for @mergedOrderSent.
  ///
  /// In en, this message translates to:
  /// **'{label} sent! Participants can no longer edit.'**
  String mergedOrderSent(String label);

  /// No description provided for @mergedOrderRoundOpened.
  ///
  /// In en, this message translates to:
  /// **'Round {number} opened! Participants can add new items.'**
  String mergedOrderRoundOpened(int number);

  /// No description provided for @mergedOrderOpenRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Round {number}'**
  String mergedOrderOpenRoundTitle(int number);

  /// No description provided for @mergedOrderOpenRoundDescription.
  ///
  /// In en, this message translates to:
  /// **'This will allow participants to add items to a new order. Current orders will be locked.'**
  String get mergedOrderOpenRoundDescription;

  /// No description provided for @mergedOrderOpenRoundButton.
  ///
  /// In en, this message translates to:
  /// **'Open Round'**
  String get mergedOrderOpenRoundButton;

  /// No description provided for @mergedParticipantOrderAdded.
  ///
  /// In en, this message translates to:
  /// **'Order added'**
  String get mergedParticipantOrderAdded;

  /// No description provided for @mergedParticipantNoOrder.
  ///
  /// In en, this message translates to:
  /// **'No order yet'**
  String get mergedParticipantNoOrder;

  /// No description provided for @mergedParticipantItemsOrdered.
  ///
  /// In en, this message translates to:
  /// **'Items ordered'**
  String get mergedParticipantItemsOrdered;

  /// No description provided for @mergedOrderCurrentOrder.
  ///
  /// In en, this message translates to:
  /// **'Current Order'**
  String get mergedOrderCurrentOrder;

  /// No description provided for @personalOrderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your order is empty'**
  String get personalOrderEmpty;

  /// No description provided for @personalOrderEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add dishes'**
  String get personalOrderEmptyHint;

  /// No description provided for @personalOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Order ({count} items)'**
  String personalOrderTitle(int count);

  /// No description provided for @personalOrderSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get personalOrderSaveButton;

  /// No description provided for @personalOrderAddFromMenu.
  ///
  /// In en, this message translates to:
  /// **'Add from Menu'**
  String get personalOrderAddFromMenu;

  /// No description provided for @personalOrderCustomDish.
  ///
  /// In en, this message translates to:
  /// **'Custom dish'**
  String get personalOrderCustomDish;

  /// No description provided for @personalOrderUseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get personalOrderUseTemplate;

  /// No description provided for @personalOrderFromMenu.
  ///
  /// In en, this message translates to:
  /// **'From menu'**
  String get personalOrderFromMenu;

  /// No description provided for @personalOrderAddItemsButton.
  ///
  /// In en, this message translates to:
  /// **'Add {count} items'**
  String personalOrderAddItemsButton(int count);

  /// No description provided for @personalOrderCustomDishName.
  ///
  /// In en, this message translates to:
  /// **'Dish name'**
  String get personalOrderCustomDishName;

  /// No description provided for @personalOrderCustomDishDesc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get personalOrderCustomDishDesc;

  /// No description provided for @personalOrderCustomDishNumber.
  ///
  /// In en, this message translates to:
  /// **'Menu number (optional)'**
  String get personalOrderCustomDishNumber;

  /// No description provided for @personalOrderChooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a Template'**
  String get personalOrderChooseTemplate;

  /// No description provided for @personalOrderSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get personalOrderSaveAsTemplate;

  /// No description provided for @personalOrderTemplateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get personalOrderTemplateNameLabel;

  /// No description provided for @personalOrderTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" saved'**
  String personalOrderTemplateSaved(String name);

  /// No description provided for @personalOrderCustomDishAdded.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\" to order'**
  String personalOrderCustomDishAdded(String name);

  /// No description provided for @personalOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order saved with {count} items'**
  String personalOrderSaved(int count);

  /// No description provided for @personalOrderLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in first'**
  String get personalOrderLogin;

  /// No description provided for @personalOrderRestaurantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Restaurant not found'**
  String get personalOrderRestaurantNotFound;

  /// No description provided for @personalOrderSentBanner.
  ///
  /// In en, this message translates to:
  /// **'Order sent — wait for the host to open a new round before adding items.'**
  String get personalOrderSentBanner;

  /// No description provided for @scanMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Menu'**
  String get scanMenuTitle;

  /// No description provided for @scanMenuHeading.
  ///
  /// In en, this message translates to:
  /// **'Scan menu pages to add items'**
  String get scanMenuHeading;

  /// No description provided for @scanMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take photos or pick from gallery — multiple pages supported. AI will extract items and merge duplicates automatically.'**
  String get scanMenuSubtitle;

  /// No description provided for @scanMenuPagesScanned.
  ///
  /// In en, this message translates to:
  /// **'{count} page(s) scanned'**
  String scanMenuPagesScanned(int count);

  /// No description provided for @scanMenuTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scanMenuTakePhoto;

  /// No description provided for @scanMenuAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get scanMenuAddPhoto;

  /// No description provided for @scanMenuGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scanMenuGallery;

  /// No description provided for @scanMenuAddFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Add from Gallery'**
  String get scanMenuAddFromGallery;

  /// No description provided for @scanMenuAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing page…'**
  String get scanMenuAnalyzing;

  /// No description provided for @scanMenuItemsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) found:'**
  String scanMenuItemsFound(int count);

  /// No description provided for @scanMenuRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get scanMenuRemoveItem;

  /// No description provided for @scanMenuSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save to Menu'**
  String get scanMenuSaveButton;

  /// No description provided for @scanMenuApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Requires a Google Gemini API key for AI analysis. Add it in Settings > AI Service.'**
  String get scanMenuApiKeyHint;

  /// No description provided for @scanMenuNoApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please add your Google Gemini API key in Settings first'**
  String get scanMenuNoApiKey;

  /// No description provided for @scanMenuStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get scanMenuStartOver;

  /// No description provided for @scanMenuUpdated.
  ///
  /// In en, this message translates to:
  /// **'Menu updated successfully!'**
  String get scanMenuUpdated;

  /// No description provided for @scanMenuNumberConflicts.
  ///
  /// In en, this message translates to:
  /// **'Number Conflicts'**
  String get scanMenuNumberConflicts;

  /// No description provided for @scanMenuConflictDescription.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) share a number with existing menu items.'**
  String scanMenuConflictDescription(int count);

  /// No description provided for @scanMenuNumberConflictLabel.
  ///
  /// In en, this message translates to:
  /// **'Number #{number} conflict'**
  String scanMenuNumberConflictLabel(int number);

  /// No description provided for @scanMenuConflictExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get scanMenuConflictExisting;

  /// No description provided for @scanMenuConflictNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get scanMenuConflictNew;

  /// No description provided for @scanMenuKeepExisting.
  ///
  /// In en, this message translates to:
  /// **'Keep existing'**
  String get scanMenuKeepExisting;

  /// No description provided for @scanMenuUseNew.
  ///
  /// In en, this message translates to:
  /// **'Use new'**
  String get scanMenuUseNew;

  /// No description provided for @scanMenuKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get scanMenuKeepBoth;

  /// No description provided for @scanMenuSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save scanned items'**
  String get scanMenuSaveTitle;

  /// No description provided for @scanMenuSaveDescription.
  ///
  /// In en, this message translates to:
  /// **'The menu already has {count} item(s). How would you like to save the new scan?'**
  String scanMenuSaveDescription(int count);

  /// No description provided for @scanMenuAppend.
  ///
  /// In en, this message translates to:
  /// **'Append to existing menu'**
  String get scanMenuAppend;

  /// No description provided for @scanMenuReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace entire menu'**
  String get scanMenuReplace;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistTitle;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @personalOrderAddCustomDishTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Dish'**
  String get personalOrderAddCustomDishTitle;
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
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

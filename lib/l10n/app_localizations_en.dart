// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sushare';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get keep => 'Keep';

  @override
  String get clear => 'Clear';

  @override
  String get loading => 'Loading...';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get navTables => 'Tables';

  @override
  String get navRestaurants => 'Restaurants';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeTitle => 'Welcome to Sushare';

  @override
  String get onboardingCreateTitle => 'Create a Table';

  @override
  String get onboardingCreateDescription =>
      'Start a new session, invite friends, and share the bill together.';

  @override
  String get onboardingJoinTitle => 'Join a Table';

  @override
  String get onboardingJoinDescription =>
      'Connect via Bluetooth to join your friends\' table and share orders.';

  @override
  String get bluetoothWarningTitle => 'Bluetooth Required';

  @override
  String get bluetoothWarningMessage =>
      'Bluetooth is required to join or share tables. You can still use the app as a single user to manage your own orders.';

  @override
  String get bluetoothWarningOpenSettings => 'Open Settings';

  @override
  String get bluetoothWarningContinueAnyway => 'Continue Anyway';

  @override
  String get onboardingEnjoyTitle => 'Enjoy the Meal';

  @override
  String get onboardingEnjoyDescription =>
      'Place your order, track the merged order, and split the bill fairly.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get profileSetupSubtitle => 'Let\'s set up your profile';

  @override
  String get tapToAddPhoto => 'Tap to add photo';

  @override
  String get tapToChooseAvatar => 'Tap to choose avatar';

  @override
  String get chooseAvatarIcon => 'Choose Icon';

  @override
  String get chooseAvatarColor => 'Choose Color';

  @override
  String get labelUsername => 'Username';

  @override
  String get hintUsername => 'Choose a unique username';

  @override
  String get validationUsernameRequired => 'Please enter a username';

  @override
  String get validationUsernameMinLength =>
      'Username must be at least 3 characters';

  @override
  String get labelFirstName => 'First Name';

  @override
  String get hintFirstName => 'Enter your first name';

  @override
  String get validationFirstNameRequired => 'Please enter your first name';

  @override
  String get labelLastName => 'Last Name';

  @override
  String get hintLastName => 'Enter your last name';

  @override
  String get validationLastNameRequired => 'Please enter your last name';

  @override
  String get getStarted => 'Get Started';

  @override
  String errorSavingProfile(String error) {
    return 'Error saving profile: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionAiService => 'AI Service';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsNoProfile => 'No profile';

  @override
  String get settingsNoProfileSubtitle => 'Create a profile to get started';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsGeminiApiKey => 'Google Gemini API Key';

  @override
  String get settingsGeminiApiKeySubtitle => 'For menu scanning';

  @override
  String get settingsAiModel => 'AI Model';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLangEnglish => 'English';

  @override
  String get settingsLangItalian => 'Italian';

  @override
  String get settingsLangSpanish => 'Spanish';

  @override
  String get settingsLangFrench => 'French';

  @override
  String get settingsLangGerman => 'German';

  @override
  String get settingsApiKeySetFirst => 'Please set your API key first';

  @override
  String get settingsApiKeyFetchError =>
      'Could not fetch models from API. Using default.';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsProfileUpdated => 'Profile updated!';

  @override
  String get settingsApiKeyDescription =>
      'Enter your Google Gemini API key for menu scanning functionality.';

  @override
  String get settingsApiKeyLabel => 'API Key';

  @override
  String get sessionsTitle => 'Tables';

  @override
  String get sessionsEmpty => 'No tables yet';

  @override
  String get sessionsEmptySubtitle =>
      'Start a new table to order together, or join one from a friend.';

  @override
  String get sessionsNewTable => 'New Table';

  @override
  String get sessionsJoinTable => 'Join a Table';

  @override
  String get sessionsJoinTooltip => 'Join table';

  @override
  String get sessionStatusOpen => 'Open';

  @override
  String get sessionStatusSent => 'Order sent';

  @override
  String get sessionStatusClosed => 'Closed';

  @override
  String get sessionCardHost => 'Host';

  @override
  String get sessionCardUnknownRestaurant => 'Unknown restaurant';

  @override
  String get sessionTimeJustNow => 'Just now';

  @override
  String sessionTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String sessionTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String sessionTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get sessionActionsShareTable => 'Share table';

  @override
  String get sessionActionsLeaveTable => 'Leave the table';

  @override
  String get sessionLeaveTitle => 'Leave the table';

  @override
  String get sessionLeaveMessage =>
      'The table will be frozen. No one will be able to join or make changes.';

  @override
  String get sessionDeleteTitle => 'Delete Table';

  @override
  String sessionDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get shareTableTitle => 'Share Table';

  @override
  String get shareTableQrHint => 'Let others join by scanning this QR code:';

  @override
  String get shareTableCodeHint => 'Or enter this code:';

  @override
  String get joinTableTitle => 'Join Table';

  @override
  String get joinTableHeading => 'Join a table';

  @override
  String get joinTableSubtitle => 'Enter the table code or scan the QR code';

  @override
  String get joinTableScanQr => 'Scan QR Code';

  @override
  String get joinTableOpenScanner => 'Open Scanner';

  @override
  String get joinTableEnterCode => 'Enter Code Manually';

  @override
  String get joinTableCodeLabel => 'Table Code';

  @override
  String get joinTableCodeHint => 'e.g., ABC12345';

  @override
  String get joinTableJoin => 'Join Table';

  @override
  String get joinTableStartNew => 'Or start a new table';

  @override
  String get joinTableScanHint => 'Point camera at QR code';

  @override
  String get joinTableHostLabel => 'Host address';

  @override
  String get joinTableHostHint => 'e.g., 192.168.1.100:8080';

  @override
  String get joinTableClosedError => 'This table is closed';

  @override
  String get newTableTitle => 'New Table';

  @override
  String get newTableHeading => 'Start a new ordering table';

  @override
  String get newTableSubtitle => 'Create a table and invite others to join';

  @override
  String get newTableNameLabel => 'Table Name';

  @override
  String get newTableNameHint => 'e.g., Friday dinner';

  @override
  String get newTableNameRequired => 'Please enter a table name';

  @override
  String get newTableSelectRestaurant => 'Select Restaurant (optional)';

  @override
  String get newTableNoRestaurants => 'No restaurants saved yet';

  @override
  String get newTableNoRestaurantsSubtitle =>
      'A restaurant will be created automatically when you start the table.';

  @override
  String get newTableAddRestaurant => 'Add a restaurant';

  @override
  String newTableMenuItems(int count) {
    return '$count items';
  }

  @override
  String get newTableStart => 'Start Table';

  @override
  String newTableError(String error) {
    return 'Error creating table: $error';
  }

  @override
  String get restaurantsTitle => 'Restaurants';

  @override
  String get restaurantsEmpty => 'No restaurants yet';

  @override
  String get restaurantsEmptySubtitle =>
      'Add your first restaurant to get started';

  @override
  String get restaurantsAdd => 'Add Restaurant';

  @override
  String restaurantDishes(int count) {
    return '$count dishes';
  }

  @override
  String restaurantTemplatesCount(int count) {
    return '$count templates';
  }

  @override
  String get restaurantDeleteTitle => 'Delete Restaurant';

  @override
  String restaurantDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get restaurantAddCoverPhoto => 'Add Cover Photo';

  @override
  String get restaurantAddTitle => 'Add Restaurant';

  @override
  String get restaurantNameLabel => 'Restaurant Name';

  @override
  String get restaurantAddressLabel => 'Address (optional)';

  @override
  String get restaurantEditTitle => 'Edit Restaurant';

  @override
  String get restaurantNotFound => 'Restaurant not found';

  @override
  String get restaurantOrderTemplates => 'Order Templates';

  @override
  String get restaurantTemplatesEmpty =>
      'No templates yet. Add one here or save from a personal order.';

  @override
  String get restaurantMenuSection => 'Menu';

  @override
  String get restaurantScanButton => 'Scan';

  @override
  String get restaurantMenuMarkYummie => 'Mark as Yummie';

  @override
  String get restaurantMenuRemoveYummie => 'Remove Yummie';

  @override
  String get restaurantTemplateDeleteTitle => 'Delete Template';

  @override
  String restaurantTemplateDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get restaurantTemplateReplaceTitle => 'Replace Template';

  @override
  String get restaurantTemplateReplaceMessage =>
      'Do you also want to delete the old version?';

  @override
  String get restaurantTemplateNewTitle => 'New Order Template';

  @override
  String get restaurantTemplateEditTitle => 'Edit Order Template';

  @override
  String get restaurantTemplateNameLabel => 'Template name';

  @override
  String get restaurantTemplateSelectDishes => 'Select dishes to include:';

  @override
  String restaurantTemplateSave(int count) {
    return 'Save template ($count items)';
  }

  @override
  String get restaurantMenuItemEditTitle => 'Edit Menu Item';

  @override
  String get restaurantMenuItemAddTitle => 'Add Menu Item';

  @override
  String get restaurantMenuItemNameLabel => 'Item Name';

  @override
  String get restaurantMenuItemDescLabel => 'Description (optional)';

  @override
  String get restaurantMenuItemNumberLabel => 'Item Number';

  @override
  String get sessionTableNotFound => 'Table not found';

  @override
  String get sessionShareTooltip => 'Share table';

  @override
  String get sessionLeaveTableMenu => 'Leave the table';

  @override
  String get sessionDeleteTableMenu => 'Delete table';

  @override
  String get sessionCloseTitle => 'Close Table';

  @override
  String get sessionCloseMessage =>
      'Are you sure? Participants won\'t be able to join or order.';

  @override
  String get sessionCloseButton => 'Close';

  @override
  String get sessionDeleteMessage2 =>
      'Are you sure you want to delete this table?';

  @override
  String get sessionClosedBanner =>
      'This table has been left — no further changes can be made';

  @override
  String get sessionUnreachableBanner =>
      'Session temporarily unreachable — waiting for the host to reconnect';

  @override
  String get sessionTabMyOrder => 'My Order';

  @override
  String get sessionTabGroup => 'Group';

  @override
  String get sessionTabChecklist => 'Checklist';

  @override
  String get checklistComplete => 'Complete';

  @override
  String get checklistHostSubtitle => 'Track what has arrived from all orders';

  @override
  String get checklistGuestSubtitle =>
      'Track what has arrived from your dishes';

  @override
  String get checklistNoOrder => 'No order to track';

  @override
  String get checklistNoOrderHint => 'The order hasn\'t been sent yet';

  @override
  String checklistArrivedOf(int arrived, int total) {
    return '$arrived of $total arrived';
  }

  @override
  String get checklistHostOnly => 'Only the host can update arrival status';

  @override
  String checklistOrderLabel(int number) {
    return 'Order $number';
  }

  @override
  String checklistItemsCount(int count) {
    return '$count items';
  }

  @override
  String get mergedOrderParticipants => 'Participants';

  @override
  String get mergedOrderWaiting =>
      'Waiting for all participants to lock their orders';

  @override
  String get mergedOrderSend => 'Send Order';

  @override
  String get mergedOrderOpenRound => 'Open New Round';

  @override
  String get mergedOrderCurrentEmpty => 'Current Order — empty';

  @override
  String get mergedOrderNoItems => 'No items yet';

  @override
  String mergedOrderBy(int count) {
    return 'By $count participant(s)';
  }

  @override
  String mergedOrderItemsCount(int count) {
    return '$count items';
  }

  @override
  String get mergedOrderSendLocked =>
      'All participants must lock their orders first';

  @override
  String mergedOrderSent(String label) {
    return '$label sent! Participants can no longer edit.';
  }

  @override
  String mergedOrderRoundOpened(int number) {
    return 'Round $number opened! Participants can add new items.';
  }

  @override
  String mergedOrderOpenRoundTitle(int number) {
    return 'Open Round $number';
  }

  @override
  String get mergedOrderOpenRoundDescription =>
      'This will allow participants to add items to a new order. Current orders will be locked.';

  @override
  String get mergedOrderOpenRoundButton => 'Open Round';

  @override
  String get mergedParticipantOrderAdded => 'Order added';

  @override
  String get mergedParticipantNoOrder => 'No order yet';

  @override
  String get mergedParticipantItemsOrdered => 'Items ordered';

  @override
  String get mergedOrderCurrentOrder => 'Current Order';

  @override
  String get personalOrderEmpty => 'Your order is empty';

  @override
  String get personalOrderEmptyHint => 'Tap the button below to add dishes';

  @override
  String personalOrderTitle(int count) {
    return 'Your Order ($count items)';
  }

  @override
  String get personalOrderSaveButton => 'Save';

  @override
  String get personalOrderAddFromMenu => 'Add from Menu';

  @override
  String get personalOrderCustomDish => 'Custom dish';

  @override
  String get personalOrderUseTemplate => 'Use template';

  @override
  String get personalOrderFromMenu => 'From menu';

  @override
  String personalOrderAddItemsButton(int count) {
    return 'Add $count items';
  }

  @override
  String get personalOrderCustomDishName => 'Dish name';

  @override
  String get personalOrderCustomDishDesc => 'Description (optional)';

  @override
  String get personalOrderCustomDishNumber => 'Menu number (optional)';

  @override
  String get personalOrderChooseTemplate => 'Choose a Template';

  @override
  String get personalOrderSaveAsTemplate => 'Save as Template';

  @override
  String get personalOrderTemplateNameLabel => 'Template name';

  @override
  String personalOrderTemplateSaved(String name) {
    return 'Template \"$name\" saved';
  }

  @override
  String personalOrderCustomDishAdded(String name) {
    return 'Added \"$name\" to order';
  }

  @override
  String personalOrderSaved(int count) {
    return 'Order saved with $count items';
  }

  @override
  String get personalOrderLogin => 'Please log in first';

  @override
  String get personalOrderRestaurantNotFound => 'Restaurant not found';

  @override
  String get personalOrderSentBanner =>
      'Order sent — wait for the host to open a new round before adding items.';

  @override
  String get scanMenuTitle => 'Scan Menu';

  @override
  String get scanMenuHeading => 'Scan menu pages to add items';

  @override
  String get scanMenuSubtitle =>
      'Take photos or pick from gallery — multiple pages supported. AI will extract items and merge duplicates automatically.';

  @override
  String scanMenuPagesScanned(int count) {
    return '$count page(s) scanned';
  }

  @override
  String get scanMenuTakePhoto => 'Take Photo';

  @override
  String get scanMenuAddPhoto => 'Add Photo';

  @override
  String get scanMenuGallery => 'Gallery';

  @override
  String get scanMenuAddFromGallery => 'Add from Gallery';

  @override
  String get scanMenuAnalyzing => 'Analyzing page…';

  @override
  String scanMenuItemsFound(int count) {
    return '$count item(s) found:';
  }

  @override
  String get scanMenuRemoveItem => 'Remove';

  @override
  String get scanMenuSaveButton => 'Save to Menu';

  @override
  String get scanMenuApiKeyHint =>
      'Requires a Google Gemini API key for AI analysis. Add it in Settings > AI Service.';

  @override
  String get scanMenuNoApiKey =>
      'Please add your Google Gemini API key in Settings first';

  @override
  String get scanMenuStartOver => 'Start over';

  @override
  String get scanMenuUpdated => 'Menu updated successfully!';

  @override
  String get scanMenuNumberConflicts => 'Number Conflicts';

  @override
  String scanMenuConflictDescription(int count) {
    return '$count item(s) share a number with existing menu items.';
  }

  @override
  String scanMenuNumberConflictLabel(int number) {
    return 'Number #$number conflict';
  }

  @override
  String get scanMenuConflictExisting => 'Existing';

  @override
  String get scanMenuConflictNew => 'New';

  @override
  String get scanMenuKeepExisting => 'Keep existing';

  @override
  String get scanMenuUseNew => 'Use new';

  @override
  String get scanMenuKeepBoth => 'Keep both';

  @override
  String get scanMenuSaveTitle => 'Save scanned items';

  @override
  String scanMenuSaveDescription(int count) {
    return 'The menu already has $count item(s). How would you like to save the new scan?';
  }

  @override
  String get scanMenuAppend => 'Append to existing menu';

  @override
  String get scanMenuReplace => 'Replace entire menu';

  @override
  String get checklistTitle => 'Checklist';

  @override
  String get leave => 'Leave';

  @override
  String get personalOrderAddCustomDishTitle => 'Add Custom Dish';

  @override
  String get joinTableConnecting => 'Connecting…';

  @override
  String get joinTableNearbySessions => 'Nearby Sessions';

  @override
  String get joinTableScanning => 'Scanning for nearby sessions…';

  @override
  String get joinTableCrossPlatformNote =>
      'BLE discovery works between Android and iOS devices. Use the QR code or session code if the table doesn\'t appear automatically.';

  @override
  String joinTableSessionTileSubtitle(String hostName, String shortId) {
    return 'Host: $hostName  ·  Code: $shortId';
  }

  @override
  String get joinTableErrorNoProfile => 'Please set up your profile first.';

  @override
  String get joinTableErrorConnectFailed =>
      'Could not connect. Make sure you\'re close to the host device.';

  @override
  String get joinTableErrorSyncTimeout =>
      'Timed out waiting for session data from host.';

  @override
  String get joinTableErrorInvalidData => 'Received invalid data from host.';

  @override
  String get joinTableErrorConnectionTimeout => 'Connection timed out.';

  @override
  String joinTableErrorNotFound(String code) {
    return 'Session \"$code\" not found nearby. Make sure the host has Bluetooth enabled and you\'re within range.';
  }

  @override
  String get sessionReconnect => 'Reconnect';

  @override
  String get sessionShareBleHint =>
      'Make sure Bluetooth is enabled on all devices.';

  @override
  String get searchDishes => 'Search dishes...';
}

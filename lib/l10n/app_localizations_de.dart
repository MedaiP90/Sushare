// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Sushare';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get keep => 'Behalten';

  @override
  String get clear => 'Leeren';

  @override
  String get loading => 'Wird geladen...';

  @override
  String errorMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get navTables => 'Tische';

  @override
  String get navRestaurants => 'Restaurants';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get welcomeTitle => 'Willkommen bei Sushare';

  @override
  String get onboardingCreateTitle => 'Tisch Erstellen';

  @override
  String get onboardingCreateDescription =>
      'Starte eine neue Session, lade Freunde ein und teile die Rechnung zusammen.';

  @override
  String get onboardingJoinTitle => 'Tisch Beitreten';

  @override
  String get onboardingJoinDescription =>
      'Scanne einen QR-Code oder gib einen Code ein, um der Session deiner Freunde beizutreten.';

  @override
  String get onboardingEnjoyTitle => 'Genieße das Essen';

  @override
  String get onboardingEnjoyDescription =>
      'Bestelle, verfolge die zusammengeführte Bestellung und teile die Rechnung fair.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get profileSetupSubtitle => 'Lass uns dein Profil einrichten';

  @override
  String get tapToAddPhoto => 'Tippen, um ein Foto hinzuzufügen';

  @override
  String get labelUsername => 'Benutzername';

  @override
  String get hintUsername => 'Wähle einen eindeutigen Benutzernamen';

  @override
  String get validationUsernameRequired => 'Bitte gib einen Benutzernamen ein';

  @override
  String get validationUsernameMinLength =>
      'Der Benutzername muss mindestens 3 Zeichen lang sein';

  @override
  String get labelFirstName => 'Vorname';

  @override
  String get hintFirstName => 'Gib deinen Vornamen ein';

  @override
  String get validationFirstNameRequired => 'Bitte gib deinen Vornamen ein';

  @override
  String get labelLastName => 'Nachname';

  @override
  String get hintLastName => 'Gib deinen Nachnamen ein';

  @override
  String get validationLastNameRequired => 'Bitte gib deinen Nachnamen ein';

  @override
  String get getStarted => 'Loslegen';

  @override
  String errorSavingProfile(String error) {
    return 'Fehler beim Speichern des Profils: $error';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsSectionAppearance => 'Erscheinungsbild';

  @override
  String get settingsSectionAiService => 'KI-Dienst';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get settingsNoProfile => 'Kein Profil';

  @override
  String get settingsNoProfileSubtitle => 'Erstelle ein Profil, um loszulegen';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsGeminiApiKey => 'Google Gemini API-Schlüssel';

  @override
  String get settingsGeminiApiKeySubtitle => 'Für das Scannen von Speisekarten';

  @override
  String get settingsAiModel => 'KI-Modell';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get settingsThemeSystem => 'Systemstandard';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsLangEnglish => 'Englisch';

  @override
  String get settingsLangItalian => 'Italienisch';

  @override
  String get settingsLangSpanish => 'Spanisch';

  @override
  String get settingsLangFrench => 'Französisch';

  @override
  String get settingsLangGerman => 'Deutsch';

  @override
  String get settingsApiKeySetFirst =>
      'Bitte zuerst den API-Schlüssel festlegen';

  @override
  String get settingsApiKeyFetchError =>
      'Modelle konnten nicht von der API abgerufen werden. Standardwert wird verwendet.';

  @override
  String get settingsEditProfile => 'Profil bearbeiten';

  @override
  String get settingsProfileUpdated => 'Profil aktualisiert!';

  @override
  String get settingsApiKeyDescription =>
      'Gib deinen Google Gemini API-Schlüssel für die Speisekarten-Scan-Funktion ein.';

  @override
  String get settingsApiKeyLabel => 'API-Schlüssel';

  @override
  String get sessionsTitle => 'Tische';

  @override
  String get sessionsEmpty => 'Noch keine Tische';

  @override
  String get sessionsEmptySubtitle =>
      'Starte einen neuen Tisch, um gemeinsam zu bestellen, oder tritt einem Freund bei.';

  @override
  String get sessionsNewTable => 'Neuer Tisch';

  @override
  String get sessionsJoinTable => 'Tisch beitreten';

  @override
  String get sessionsJoinTooltip => 'Tisch beitreten';

  @override
  String get sessionStatusOpen => 'Offen';

  @override
  String get sessionStatusSent => 'Bestellung gesendet';

  @override
  String get sessionStatusClosed => 'Geschlossen';

  @override
  String get sessionCardHost => 'Gastgeber';

  @override
  String get sessionCardUnknownRestaurant => 'Unbekanntes Restaurant';

  @override
  String get sessionTimeJustNow => 'Gerade eben';

  @override
  String sessionTimeMinutesAgo(int count) {
    return 'Vor $count Min.';
  }

  @override
  String sessionTimeHoursAgo(int count) {
    return 'Vor $count Std.';
  }

  @override
  String sessionTimeDaysAgo(int count) {
    return 'Vor $count Tag(en)';
  }

  @override
  String get sessionActionsShareTable => 'Tisch teilen';

  @override
  String get sessionActionsLeaveTable => 'Tisch verlassen';

  @override
  String get sessionLeaveTitle => 'Tisch verlassen';

  @override
  String get sessionLeaveMessage =>
      'Der Tisch wird eingefroren. Niemand kann mehr beitreten oder Änderungen vornehmen.';

  @override
  String get sessionDeleteTitle => 'Tisch löschen';

  @override
  String sessionDeleteMessage(String name) {
    return 'Möchtest du \"$name\" wirklich löschen?';
  }

  @override
  String get shareTableTitle => 'Tisch teilen';

  @override
  String get shareTableQrHint =>
      'Andere können beitreten, indem sie diesen QR-Code scannen:';

  @override
  String get shareTableCodeHint => 'Oder diesen Code eingeben:';

  @override
  String get joinTableTitle => 'Tisch beitreten';

  @override
  String get joinTableHeading => 'Einem Tisch beitreten';

  @override
  String get joinTableSubtitle => 'Tischcode eingeben oder QR-Code scannen';

  @override
  String get joinTableScanQr => 'QR-Code scannen';

  @override
  String get joinTableOpenScanner => 'Scanner öffnen';

  @override
  String get joinTableEnterCode => 'Code manuell eingeben';

  @override
  String get joinTableCodeLabel => 'Tischcode';

  @override
  String get joinTableCodeHint => 'z.B. ABC12345';

  @override
  String get joinTableJoin => 'Tisch beitreten';

  @override
  String get joinTableStartNew => 'Oder neuen Tisch starten';

  @override
  String get joinTableScanHint => 'Kamera auf QR-Code richten';

  @override
  String get joinTableHostLabel => 'Host-Adresse';

  @override
  String get joinTableHostHint => 'z.B. 192.168.1.100:8080';

  @override
  String get joinTableClosedError => 'Dieser Tisch ist geschlossen';

  @override
  String get newTableTitle => 'Neuer Tisch';

  @override
  String get newTableHeading => 'Neuen Bestelltisch starten';

  @override
  String get newTableSubtitle =>
      'Tisch erstellen und andere einladen, beizutreten';

  @override
  String get newTableNameLabel => 'Tischname';

  @override
  String get newTableNameHint => 'z.B. Freitagabend-Essen';

  @override
  String get newTableNameRequired => 'Bitte gib einen Tischnamen ein';

  @override
  String get newTableSelectRestaurant => 'Restaurant auswählen (optional)';

  @override
  String get newTableNoRestaurants => 'Noch keine Restaurants gespeichert';

  @override
  String get newTableNoRestaurantsSubtitle =>
      'Ein Restaurant wird automatisch erstellt, wenn du den Tisch startest.';

  @override
  String get newTableAddRestaurant => 'Restaurant hinzufügen';

  @override
  String newTableMenuItems(int count) {
    return '$count Artikel';
  }

  @override
  String get newTableStart => 'Tisch starten';

  @override
  String newTableError(String error) {
    return 'Fehler beim Erstellen des Tisches: $error';
  }

  @override
  String get restaurantsTitle => 'Restaurants';

  @override
  String get restaurantsEmpty => 'Noch keine Restaurants';

  @override
  String get restaurantsEmptySubtitle =>
      'Füge dein erstes Restaurant hinzu, um loszulegen';

  @override
  String get restaurantsAdd => 'Restaurant hinzufügen';

  @override
  String restaurantDishes(int count) {
    return '$count Gerichte';
  }

  @override
  String restaurantTemplatesCount(int count) {
    return '$count Vorlagen';
  }

  @override
  String get restaurantDeleteTitle => 'Restaurant löschen';

  @override
  String restaurantDeleteMessage(String name) {
    return 'Möchtest du \"$name\" wirklich löschen?';
  }

  @override
  String get restaurantAddCoverPhoto => 'Titelbild hinzufügen';

  @override
  String get restaurantAddTitle => 'Restaurant hinzufügen';

  @override
  String get restaurantNameLabel => 'Restaurantname';

  @override
  String get restaurantAddressLabel => 'Adresse (optional)';

  @override
  String get restaurantEditTitle => 'Restaurant bearbeiten';

  @override
  String get restaurantNotFound => 'Restaurant nicht gefunden';

  @override
  String get restaurantOrderTemplates => 'Bestellvorlagen';

  @override
  String get restaurantTemplatesEmpty =>
      'Noch keine Vorlagen. Hier hinzufügen oder aus einer persönlichen Bestellung speichern.';

  @override
  String get restaurantMenuSection => 'Speisekarte';

  @override
  String get restaurantScanButton => 'Scannen';

  @override
  String get restaurantMenuMarkYummie => 'Als Lecker markieren';

  @override
  String get restaurantMenuRemoveYummie => 'Lecker entfernen';

  @override
  String get restaurantTemplateDeleteTitle => 'Vorlage löschen';

  @override
  String restaurantTemplateDeleteMessage(String name) {
    return 'Möchtest du \"$name\" wirklich löschen?';
  }

  @override
  String get restaurantTemplateReplaceTitle => 'Vorlage ersetzen';

  @override
  String get restaurantTemplateReplaceMessage =>
      'Möchtest du auch die alte Version löschen?';

  @override
  String get restaurantTemplateNewTitle => 'Neue Bestellvorlage';

  @override
  String get restaurantTemplateEditTitle => 'Bestellvorlage bearbeiten';

  @override
  String get restaurantTemplateNameLabel => 'Vorlagenname';

  @override
  String get restaurantTemplateSelectDishes => 'Gerichte auswählen:';

  @override
  String restaurantTemplateSave(int count) {
    return 'Vorlage speichern ($count Artikel)';
  }

  @override
  String get restaurantMenuItemEditTitle => 'Menüeintrag bearbeiten';

  @override
  String get restaurantMenuItemAddTitle => 'Menüeintrag hinzufügen';

  @override
  String get restaurantMenuItemNameLabel => 'Artikelname';

  @override
  String get restaurantMenuItemDescLabel => 'Beschreibung (optional)';

  @override
  String get restaurantMenuItemNumberLabel => 'Artikelnummer';

  @override
  String get sessionTableNotFound => 'Tisch nicht gefunden';

  @override
  String get sessionShareTooltip => 'Tisch teilen';

  @override
  String get sessionLeaveTableMenu => 'Tisch verlassen';

  @override
  String get sessionDeleteTableMenu => 'Tisch löschen';

  @override
  String get sessionCloseTitle => 'Tisch schließen';

  @override
  String get sessionCloseMessage =>
      'Bist du sicher? Teilnehmer können nicht mehr beitreten oder bestellen.';

  @override
  String get sessionCloseButton => 'Schließen';

  @override
  String get sessionDeleteMessage2 =>
      'Möchtest du diesen Tisch wirklich löschen?';

  @override
  String get sessionClosedBanner =>
      'Dieser Tisch wurde verlassen — es können keine weiteren Änderungen vorgenommen werden';

  @override
  String get sessionUnreachableBanner =>
      'Sitzung vorübergehend nicht erreichbar — warte auf Wiederverbindung des Hosts';

  @override
  String get sessionTabMyOrder => 'Meine Bestellung';

  @override
  String get sessionTabGroup => 'Gruppe';

  @override
  String get sessionTabChecklist => 'Checkliste';

  @override
  String get checklistComplete => 'Vollständig';

  @override
  String get checklistHostSubtitle =>
      'Verfolge, was aus allen Bestellungen angekommen ist';

  @override
  String get checklistGuestSubtitle =>
      'Verfolge, was von deinen Gerichten angekommen ist';

  @override
  String get checklistNoOrder => 'Keine Bestellung zu verfolgen';

  @override
  String get checklistNoOrderHint => 'Die Bestellung wurde noch nicht gesendet';

  @override
  String checklistArrivedOf(int arrived, int total) {
    return '$arrived von $total angekommen';
  }

  @override
  String get checklistHostOnly =>
      'Nur der Gastgeber kann den Ankunftsstatus aktualisieren';

  @override
  String checklistOrderLabel(int number) {
    return 'Bestellung $number';
  }

  @override
  String checklistItemsCount(int count) {
    return '$count Artikel';
  }

  @override
  String get mergedOrderParticipants => 'Teilnehmer';

  @override
  String get mergedOrderWaiting =>
      'Warten, bis alle Teilnehmer ihre Bestellungen gesperrt haben';

  @override
  String get mergedOrderSend => 'Bestellung senden';

  @override
  String get mergedOrderOpenRound => 'Neue Runde öffnen';

  @override
  String get mergedOrderCurrentEmpty => 'Aktuelle Bestellung — leer';

  @override
  String get mergedOrderNoItems => 'Noch keine Artikel';

  @override
  String mergedOrderBy(int count) {
    return 'Von $count Teilnehmer(n)';
  }

  @override
  String mergedOrderItemsCount(int count) {
    return '$count Artikel';
  }

  @override
  String get mergedOrderSendLocked =>
      'Alle Teilnehmer müssen ihre Bestellungen zuerst sperren';

  @override
  String mergedOrderSent(String label) {
    return '$label gesendet! Teilnehmer können nicht mehr bearbeiten.';
  }

  @override
  String mergedOrderRoundOpened(int number) {
    return 'Runde $number geöffnet! Teilnehmer können neue Artikel hinzufügen.';
  }

  @override
  String mergedOrderOpenRoundTitle(int number) {
    return 'Runde $number öffnen';
  }

  @override
  String get mergedOrderOpenRoundDescription =>
      'Dadurch können Teilnehmer Artikel zu einer neuen Bestellung hinzufügen. Aktuelle Bestellungen werden gesperrt.';

  @override
  String get mergedOrderOpenRoundButton => 'Runde öffnen';

  @override
  String get mergedParticipantOrderAdded => 'Bestellung hinzugefügt';

  @override
  String get mergedParticipantNoOrder => 'Noch keine Bestellung';

  @override
  String get mergedParticipantItemsOrdered => 'Bestellte Artikel';

  @override
  String get mergedOrderCurrentOrder => 'Aktuelle Bestellung';

  @override
  String get personalOrderEmpty => 'Deine Bestellung ist leer';

  @override
  String get personalOrderEmptyHint =>
      'Tippe auf die Schaltfläche unten, um Gerichte hinzuzufügen';

  @override
  String personalOrderTitle(int count) {
    return 'Deine Bestellung ($count Artikel)';
  }

  @override
  String get personalOrderSaveButton => 'Speichern';

  @override
  String get personalOrderAddFromMenu => 'Aus der Speisekarte hinzufügen';

  @override
  String get personalOrderCustomDish => 'Eigenes Gericht';

  @override
  String get personalOrderUseTemplate => 'Vorlage verwenden';

  @override
  String get personalOrderFromMenu => 'Aus der Speisekarte';

  @override
  String personalOrderAddItemsButton(int count) {
    return '$count Artikel hinzufügen';
  }

  @override
  String get personalOrderCustomDishName => 'Gerichtname';

  @override
  String get personalOrderCustomDishDesc => 'Beschreibung (optional)';

  @override
  String get personalOrderCustomDishNumber => 'Menünummer (optional)';

  @override
  String get personalOrderChooseTemplate => 'Vorlage auswählen';

  @override
  String get personalOrderSaveAsTemplate => 'Als Vorlage speichern';

  @override
  String get personalOrderTemplateNameLabel => 'Vorlagenname';

  @override
  String personalOrderTemplateSaved(String name) {
    return 'Vorlage \"$name\" gespeichert';
  }

  @override
  String personalOrderCustomDishAdded(String name) {
    return '\"$name\" zur Bestellung hinzugefügt';
  }

  @override
  String personalOrderSaved(int count) {
    return 'Bestellung mit $count Artikeln gespeichert';
  }

  @override
  String get personalOrderLogin => 'Bitte zuerst anmelden';

  @override
  String get personalOrderRestaurantNotFound => 'Restaurant nicht gefunden';

  @override
  String get personalOrderSentBanner =>
      'Bestellung gesendet — warte, bis der Gastgeber eine neue Runde öffnet, bevor du Artikel hinzufügst.';

  @override
  String get scanMenuTitle => 'Speisekarte scannen';

  @override
  String get scanMenuHeading =>
      'Speisekartenseiten scannen, um Artikel hinzuzufügen';

  @override
  String get scanMenuSubtitle =>
      'Fotos aufnehmen oder aus der Galerie auswählen — mehrere Seiten werden unterstützt. KI extrahiert Artikel und fügt Duplikate automatisch zusammen.';

  @override
  String scanMenuPagesScanned(int count) {
    return '$count Seite(n) gescannt';
  }

  @override
  String get scanMenuTakePhoto => 'Foto aufnehmen';

  @override
  String get scanMenuAddPhoto => 'Foto hinzufügen';

  @override
  String get scanMenuGallery => 'Galerie';

  @override
  String get scanMenuAddFromGallery => 'Aus Galerie hinzufügen';

  @override
  String get scanMenuAnalyzing => 'Seite wird analysiert…';

  @override
  String scanMenuItemsFound(int count) {
    return '$count Artikel gefunden:';
  }

  @override
  String get scanMenuRemoveItem => 'Entfernen';

  @override
  String get scanMenuSaveButton => 'In Speisekarte speichern';

  @override
  String get scanMenuApiKeyHint =>
      'Erfordert einen Google Gemini API-Schlüssel für die KI-Analyse. Unter Einstellungen > KI-Dienst hinzufügen.';

  @override
  String get scanMenuNoApiKey =>
      'Bitte zuerst den Google Gemini API-Schlüssel in den Einstellungen hinzufügen';

  @override
  String get scanMenuStartOver => 'Von vorne beginnen';

  @override
  String get scanMenuUpdated => 'Speisekarte erfolgreich aktualisiert!';

  @override
  String get scanMenuNumberConflicts => 'Nummernkonflikte';

  @override
  String scanMenuConflictDescription(int count) {
    return '$count Artikel teilen eine Nummer mit vorhandenen Menüeinträgen.';
  }

  @override
  String scanMenuNumberConflictLabel(int number) {
    return 'Nummer #$number Konflikt';
  }

  @override
  String get scanMenuConflictExisting => 'Vorhanden';

  @override
  String get scanMenuConflictNew => 'Neu';

  @override
  String get scanMenuKeepExisting => 'Vorhandenen behalten';

  @override
  String get scanMenuUseNew => 'Neuen verwenden';

  @override
  String get scanMenuKeepBoth => 'Beide behalten';

  @override
  String get scanMenuSaveTitle => 'Gescannte Artikel speichern';

  @override
  String scanMenuSaveDescription(int count) {
    return 'Die Speisekarte hat bereits $count Artikel. Wie möchtest du den neuen Scan speichern?';
  }

  @override
  String get scanMenuAppend => 'An vorhandene Speisekarte anhängen';

  @override
  String get scanMenuReplace => 'Gesamte Speisekarte ersetzen';

  @override
  String get checklistTitle => 'Checkliste';

  @override
  String get leave => 'Verlassen';

  @override
  String get personalOrderAddCustomDishTitle => 'Eigenes Gericht hinzufügen';
}

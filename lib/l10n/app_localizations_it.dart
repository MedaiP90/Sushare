// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Sushare';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get add => 'Aggiungi';

  @override
  String get confirm => 'Conferma';

  @override
  String get retry => 'Riprova';

  @override
  String get keep => 'Mantieni';

  @override
  String get clear => 'Svuota';

  @override
  String get loading => 'Caricamento...';

  @override
  String errorMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get navTables => 'Tavoli';

  @override
  String get navRestaurants => 'Ristoranti';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get welcomeTitle => 'Benvenuto su Sushare';

  @override
  String get profileSetupSubtitle => 'Configuriamo il tuo profilo';

  @override
  String get tapToAddPhoto => 'Tocca per aggiungere una foto';

  @override
  String get labelUsername => 'Nome utente';

  @override
  String get hintUsername => 'Scegli un nome utente univoco';

  @override
  String get validationUsernameRequired => 'Inserisci un nome utente';

  @override
  String get validationUsernameMinLength =>
      'Il nome utente deve avere almeno 3 caratteri';

  @override
  String get labelFirstName => 'Nome';

  @override
  String get hintFirstName => 'Inserisci il tuo nome';

  @override
  String get validationFirstNameRequired => 'Inserisci il tuo nome';

  @override
  String get labelLastName => 'Cognome';

  @override
  String get hintLastName => 'Inserisci il tuo cognome';

  @override
  String get validationLastNameRequired => 'Inserisci il tuo cognome';

  @override
  String get getStarted => 'Inizia';

  @override
  String errorSavingProfile(String error) {
    return 'Errore nel salvataggio del profilo: $error';
  }

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionProfile => 'Profilo';

  @override
  String get settingsSectionAppearance => 'Aspetto';

  @override
  String get settingsSectionAiService => 'Servizio IA';

  @override
  String get settingsSectionAbout => 'Informazioni';

  @override
  String get settingsNoProfile => 'Nessun profilo';

  @override
  String get settingsNoProfileSubtitle => 'Crea un profilo per iniziare';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsGeminiApiKey => 'Chiave API Google Gemini';

  @override
  String get settingsGeminiApiKeySubtitle => 'Per la scansione dei menu';

  @override
  String get settingsAiModel => 'Modello IA';

  @override
  String get settingsAppVersion => 'Versione app';

  @override
  String get settingsThemeSystem => 'Predefinito di sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsLangEnglish => 'Inglese';

  @override
  String get settingsLangItalian => 'Italiano';

  @override
  String get settingsLangSpanish => 'Spagnolo';

  @override
  String get settingsLangFrench => 'Francese';

  @override
  String get settingsLangGerman => 'Tedesco';

  @override
  String get settingsApiKeySetFirst => 'Imposta prima la tua chiave API';

  @override
  String get settingsApiKeyFetchError =>
      'Impossibile recuperare i modelli dall\'API. Uso il predefinito.';

  @override
  String get settingsEditProfile => 'Modifica profilo';

  @override
  String get settingsProfileUpdated => 'Profilo aggiornato!';

  @override
  String get settingsApiKeyDescription =>
      'Inserisci la tua chiave API Google Gemini per la funzione di scansione menu.';

  @override
  String get settingsApiKeyLabel => 'Chiave API';

  @override
  String get sessionsTitle => 'Tavoli';

  @override
  String get sessionsEmpty => 'Nessun tavolo ancora';

  @override
  String get sessionsEmptySubtitle =>
      'Crea un nuovo tavolo per ordinare insieme, o unisciti a quello di un amico.';

  @override
  String get sessionsNewTable => 'Nuovo tavolo';

  @override
  String get sessionsJoinTable => 'Unisciti a un tavolo';

  @override
  String get sessionsJoinTooltip => 'Unisciti al tavolo';

  @override
  String get sessionStatusOpen => 'Aperto';

  @override
  String get sessionStatusSent => 'Ordine inviato';

  @override
  String get sessionStatusClosed => 'Chiuso';

  @override
  String get sessionCardHost => 'Host';

  @override
  String get sessionCardUnknownRestaurant => 'Ristorante sconosciuto';

  @override
  String get sessionTimeJustNow => 'Proprio ora';

  @override
  String sessionTimeMinutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String sessionTimeHoursAgo(int count) {
    return '$count h fa';
  }

  @override
  String sessionTimeDaysAgo(int count) {
    return '$count giorno/i fa';
  }

  @override
  String get sessionActionsShareTable => 'Condividi tavolo';

  @override
  String get sessionActionsLeaveTable => 'Abbandona il tavolo';

  @override
  String get sessionLeaveTitle => 'Abbandona il tavolo';

  @override
  String get sessionLeaveMessage =>
      'Il tavolo verrà bloccato. Nessuno potrà unirsi o apportare modifiche.';

  @override
  String get sessionDeleteTitle => 'Elimina tavolo';

  @override
  String sessionDeleteMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get shareTableTitle => 'Condividi tavolo';

  @override
  String get shareTableQrHint =>
      'Altri possono unirsi scansionando questo codice QR:';

  @override
  String get shareTableCodeHint => 'Oppure inserisci questo codice:';

  @override
  String get joinTableTitle => 'Unisciti al tavolo';

  @override
  String get joinTableHeading => 'Unisciti a un tavolo';

  @override
  String get joinTableSubtitle =>
      'Inserisci il codice tavolo o scansiona il codice QR';

  @override
  String get joinTableScanQr => 'Scansiona codice QR';

  @override
  String get joinTableOpenScanner => 'Apri scanner';

  @override
  String get joinTableEnterCode => 'Inserisci il codice manualmente';

  @override
  String get joinTableCodeLabel => 'Codice tavolo';

  @override
  String get joinTableCodeHint => 'es. ABC12345';

  @override
  String get joinTableJoin => 'Unisciti al tavolo';

  @override
  String get joinTableStartNew => 'Oppure crea un nuovo tavolo';

  @override
  String get joinTableScanHint => 'Punta la fotocamera sul codice QR';

  @override
  String get joinTableHostLabel => 'Indirizzo host';

  @override
  String get joinTableHostHint => 'es. 192.168.1.100:8080';

  @override
  String get newTableTitle => 'Nuovo tavolo';

  @override
  String get newTableHeading => 'Crea un nuovo tavolo per ordinare';

  @override
  String get newTableSubtitle => 'Crea un tavolo e invita altri a unirsi';

  @override
  String get newTableNameLabel => 'Nome del tavolo';

  @override
  String get newTableNameHint => 'es. Cena del venerdì';

  @override
  String get newTableNameRequired => 'Inserisci un nome per il tavolo';

  @override
  String get newTableSelectRestaurant => 'Seleziona ristorante (opzionale)';

  @override
  String get newTableNoRestaurants => 'Nessun ristorante salvato ancora';

  @override
  String get newTableNoRestaurantsSubtitle =>
      'Un ristorante verrà creato automaticamente all\'avvio del tavolo.';

  @override
  String get newTableAddRestaurant => 'Aggiungi un ristorante';

  @override
  String newTableMenuItems(int count) {
    return '$count articoli';
  }

  @override
  String get newTableStart => 'Avvia tavolo';

  @override
  String newTableError(String error) {
    return 'Errore nella creazione del tavolo: $error';
  }

  @override
  String get restaurantsTitle => 'Ristoranti';

  @override
  String get restaurantsEmpty => 'Nessun ristorante ancora';

  @override
  String get restaurantsEmptySubtitle =>
      'Aggiungi il tuo primo ristorante per iniziare';

  @override
  String get restaurantsAdd => 'Aggiungi ristorante';

  @override
  String restaurantDishes(int count) {
    return '$count piatti';
  }

  @override
  String restaurantTemplatesCount(int count) {
    return '$count modelli';
  }

  @override
  String get restaurantDeleteTitle => 'Elimina ristorante';

  @override
  String restaurantDeleteMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get restaurantAddCoverPhoto => 'Aggiungi foto di copertina';

  @override
  String get restaurantAddTitle => 'Aggiungi ristorante';

  @override
  String get restaurantNameLabel => 'Nome del ristorante';

  @override
  String get restaurantAddressLabel => 'Indirizzo (opzionale)';

  @override
  String get restaurantEditTitle => 'Modifica ristorante';

  @override
  String get restaurantNotFound => 'Ristorante non trovato';

  @override
  String get restaurantOrderTemplates => 'Modelli di ordine';

  @override
  String get restaurantTemplatesEmpty =>
      'Nessun modello ancora. Aggiungine uno qui o salvane uno da un ordine personale.';

  @override
  String get restaurantMenuSection => 'Menu';

  @override
  String get restaurantScanButton => 'Scansiona';

  @override
  String get restaurantMenuMarkYummie => 'Segna come buonissimo';

  @override
  String get restaurantMenuRemoveYummie => 'Rimuovi buonissimo';

  @override
  String get restaurantTemplateDeleteTitle => 'Elimina modello';

  @override
  String restaurantTemplateDeleteMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get restaurantTemplateReplaceTitle => 'Sostituisci modello';

  @override
  String get restaurantTemplateReplaceMessage =>
      'Vuoi anche eliminare la versione precedente?';

  @override
  String get restaurantTemplateNewTitle => 'Nuovo modello di ordine';

  @override
  String get restaurantTemplateEditTitle => 'Modifica modello di ordine';

  @override
  String get restaurantTemplateNameLabel => 'Nome del modello';

  @override
  String get restaurantTemplateSelectDishes =>
      'Seleziona i piatti da includere:';

  @override
  String restaurantTemplateSave(int count) {
    return 'Salva modello ($count articoli)';
  }

  @override
  String get restaurantMenuItemEditTitle => 'Modifica voce del menu';

  @override
  String get restaurantMenuItemAddTitle => 'Aggiungi voce al menu';

  @override
  String get restaurantMenuItemNameLabel => 'Nome articolo';

  @override
  String get restaurantMenuItemDescLabel => 'Descrizione (opzionale)';

  @override
  String get restaurantMenuItemNumberLabel => 'Numero articolo';

  @override
  String get sessionTableNotFound => 'Tavolo non trovato';

  @override
  String get sessionShareTooltip => 'Condividi tavolo';

  @override
  String get sessionLeaveTableMenu => 'Abbandona il tavolo';

  @override
  String get sessionDeleteTableMenu => 'Elimina tavolo';

  @override
  String get sessionCloseTitle => 'Chiudi tavolo';

  @override
  String get sessionCloseMessage =>
      'Sei sicuro? I partecipanti non potranno più unirsi né ordinare.';

  @override
  String get sessionCloseButton => 'Chiudi';

  @override
  String get sessionDeleteMessage2 =>
      'Sei sicuro di voler eliminare questo tavolo?';

  @override
  String get sessionClosedBanner =>
      'Questo tavolo è stato abbandonato — non è possibile apportare ulteriori modifiche';

  @override
  String get sessionUnreachableBanner =>
      'Sessione temporaneamente irraggiungibile — in attesa che l\'host si riconnetta';

  @override
  String get sessionTabMyOrder => 'Il mio ordine';

  @override
  String get sessionTabGroup => 'Gruppo';

  @override
  String get sessionTabChecklist => 'Lista di controllo';

  @override
  String get checklistComplete => 'Completato';

  @override
  String get checklistHostSubtitle =>
      'Tieni traccia di cosa è arrivato da tutti gli ordini';

  @override
  String get checklistGuestSubtitle =>
      'Tieni traccia di cosa è arrivato dai tuoi piatti';

  @override
  String get checklistNoOrder => 'Nessun ordine da tracciare';

  @override
  String get checklistNoOrderHint => 'L\'ordine non è ancora stato inviato';

  @override
  String checklistArrivedOf(int arrived, int total) {
    return '$arrived di $total arrivati';
  }

  @override
  String get checklistHostOnly =>
      'Solo l\'host può aggiornare lo stato di arrivo';

  @override
  String checklistOrderLabel(int number) {
    return 'Ordine $number';
  }

  @override
  String checklistItemsCount(int count) {
    return '$count articoli';
  }

  @override
  String get mergedOrderParticipants => 'Partecipanti';

  @override
  String get mergedOrderWaiting =>
      'In attesa che tutti i partecipanti blocchino i loro ordini';

  @override
  String get mergedOrderSend => 'Invia ordine';

  @override
  String get mergedOrderOpenRound => 'Apri nuovo giro';

  @override
  String get mergedOrderCurrentEmpty => 'Ordine attuale — vuoto';

  @override
  String get mergedOrderNoItems => 'Nessun articolo ancora';

  @override
  String mergedOrderBy(int count) {
    return 'Da $count partecipante/i';
  }

  @override
  String mergedOrderItemsCount(int count) {
    return '$count articoli';
  }

  @override
  String get mergedOrderSendLocked =>
      'Tutti i partecipanti devono prima bloccare i loro ordini';

  @override
  String mergedOrderSent(String label) {
    return '$label inviato! I partecipanti non possono più modificare.';
  }

  @override
  String mergedOrderRoundOpened(int number) {
    return 'Giro $number aperto! I partecipanti possono aggiungere nuovi articoli.';
  }

  @override
  String mergedOrderOpenRoundTitle(int number) {
    return 'Apri giro $number';
  }

  @override
  String get mergedOrderOpenRoundDescription =>
      'Questo permetterà ai partecipanti di aggiungere articoli a un nuovo ordine. Gli ordini attuali verranno bloccati.';

  @override
  String get mergedOrderOpenRoundButton => 'Apri giro';

  @override
  String get mergedParticipantOrderAdded => 'Ordine aggiunto';

  @override
  String get mergedParticipantNoOrder => 'Nessun ordine ancora';

  @override
  String get mergedParticipantItemsOrdered => 'Articoli ordinati';

  @override
  String get mergedOrderCurrentOrder => 'Ordine attuale';

  @override
  String get personalOrderEmpty => 'Il tuo ordine è vuoto';

  @override
  String get personalOrderEmptyHint =>
      'Tocca il pulsante qui sotto per aggiungere piatti';

  @override
  String personalOrderTitle(int count) {
    return 'Il tuo ordine ($count articoli)';
  }

  @override
  String get personalOrderSaveButton => 'Salva';

  @override
  String get personalOrderAddFromMenu => 'Aggiungi dal menu';

  @override
  String get personalOrderCustomDish => 'Piatto personalizzato';

  @override
  String get personalOrderUseTemplate => 'Usa modello';

  @override
  String get personalOrderFromMenu => 'Dal menu';

  @override
  String personalOrderAddItemsButton(int count) {
    return 'Aggiungi $count articoli';
  }

  @override
  String get personalOrderCustomDishName => 'Nome del piatto';

  @override
  String get personalOrderCustomDishDesc => 'Descrizione (opzionale)';

  @override
  String get personalOrderCustomDishNumber => 'Numero del menu (opzionale)';

  @override
  String get personalOrderChooseTemplate => 'Scegli un modello';

  @override
  String get personalOrderSaveAsTemplate => 'Salva come modello';

  @override
  String get personalOrderTemplateNameLabel => 'Nome del modello';

  @override
  String personalOrderTemplateSaved(String name) {
    return 'Modello \"$name\" salvato';
  }

  @override
  String personalOrderCustomDishAdded(String name) {
    return '\"$name\" aggiunto all\'ordine';
  }

  @override
  String personalOrderSaved(int count) {
    return 'Ordine salvato con $count articoli';
  }

  @override
  String get personalOrderLogin => 'Accedi prima di continuare';

  @override
  String get personalOrderRestaurantNotFound => 'Ristorante non trovato';

  @override
  String get personalOrderSentBanner =>
      'Ordine inviato — aspetta che l\'host apra un nuovo giro prima di aggiungere articoli.';

  @override
  String get scanMenuTitle => 'Scansiona menu';

  @override
  String get scanMenuHeading =>
      'Scansiona le pagine del menu per aggiungere articoli';

  @override
  String get scanMenuSubtitle =>
      'Scatta foto o scegli dalla galleria — più pagine supportate. L\'IA estrarrà gli articoli e unirà i duplicati automaticamente.';

  @override
  String scanMenuPagesScanned(int count) {
    return '$count pagina/e scansionata/e';
  }

  @override
  String get scanMenuTakePhoto => 'Scatta foto';

  @override
  String get scanMenuAddPhoto => 'Aggiungi foto';

  @override
  String get scanMenuGallery => 'Galleria';

  @override
  String get scanMenuAddFromGallery => 'Aggiungi dalla galleria';

  @override
  String get scanMenuAnalyzing => 'Analisi della pagina…';

  @override
  String scanMenuItemsFound(int count) {
    return '$count articolo/i trovato/i:';
  }

  @override
  String get scanMenuRemoveItem => 'Rimuovi';

  @override
  String get scanMenuSaveButton => 'Salva nel menu';

  @override
  String get scanMenuApiKeyHint =>
      'Richiede una chiave API Google Gemini per l\'analisi IA. Aggiungila in Impostazioni > Servizio IA.';

  @override
  String get scanMenuNoApiKey =>
      'Aggiungi prima la tua chiave API Google Gemini nelle Impostazioni';

  @override
  String get scanMenuStartOver => 'Ricomincia';

  @override
  String get scanMenuUpdated => 'Menu aggiornato con successo!';

  @override
  String get scanMenuNumberConflicts => 'Conflitti di numerazione';

  @override
  String scanMenuConflictDescription(int count) {
    return '$count articolo/i condivide/condividono un numero con voci del menu esistenti.';
  }

  @override
  String scanMenuNumberConflictLabel(int number) {
    return 'Conflitto numero #$number';
  }

  @override
  String get scanMenuConflictExisting => 'Esistente';

  @override
  String get scanMenuConflictNew => 'Nuovo';

  @override
  String get scanMenuKeepExisting => 'Mantieni esistente';

  @override
  String get scanMenuUseNew => 'Usa nuovo';

  @override
  String get scanMenuKeepBoth => 'Mantieni entrambi';

  @override
  String get scanMenuSaveTitle => 'Salva articoli scansionati';

  @override
  String scanMenuSaveDescription(int count) {
    return 'Il menu ha già $count articolo/i. Come vuoi salvare la nuova scansione?';
  }

  @override
  String get scanMenuAppend => 'Aggiungi al menu esistente';

  @override
  String get scanMenuReplace => 'Sostituisci l\'intero menu';

  @override
  String get checklistTitle => 'Lista di controllo';

  @override
  String get leave => 'Abbandona';

  @override
  String get personalOrderAddCustomDishTitle =>
      'Aggiungi piatto personalizzato';
}

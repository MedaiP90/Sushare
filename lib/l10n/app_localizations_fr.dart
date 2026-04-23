// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Sushare';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get confirm => 'Confirmer';

  @override
  String get retry => 'Réessayer';

  @override
  String get keep => 'Conserver';

  @override
  String get clear => 'Effacer';

  @override
  String get loading => 'Chargement...';

  @override
  String errorMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get navTables => 'Tables';

  @override
  String get navRestaurants => 'Restaurants';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get welcomeTitle => 'Bienvenue sur Sushare';

  @override
  String get profileSetupSubtitle => 'Configurons ton profil';

  @override
  String get tapToAddPhoto => 'Appuie pour ajouter une photo';

  @override
  String get labelUsername => 'Nom d\'utilisateur';

  @override
  String get hintUsername => 'Choisis un nom d\'utilisateur unique';

  @override
  String get validationUsernameRequired =>
      'Veuillez saisir un nom d\'utilisateur';

  @override
  String get validationUsernameMinLength =>
      'Le nom d\'utilisateur doit comporter au moins 3 caractères';

  @override
  String get labelFirstName => 'Prénom';

  @override
  String get hintFirstName => 'Saisis ton prénom';

  @override
  String get validationFirstNameRequired => 'Veuillez saisir ton prénom';

  @override
  String get labelLastName => 'Nom';

  @override
  String get hintLastName => 'Saisis ton nom';

  @override
  String get validationLastNameRequired => 'Veuillez saisir ton nom';

  @override
  String get getStarted => 'Commencer';

  @override
  String errorSavingProfile(String error) {
    return 'Erreur lors de l\'enregistrement du profil : $error';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionAiService => 'Service IA';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsNoProfile => 'Aucun profil';

  @override
  String get settingsNoProfileSubtitle => 'Crée un profil pour commencer';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsGeminiApiKey => 'Clé API Google Gemini';

  @override
  String get settingsGeminiApiKeySubtitle => 'Pour scanner les menus';

  @override
  String get settingsAiModel => 'Modèle IA';

  @override
  String get settingsAppVersion => 'Version de l\'application';

  @override
  String get settingsThemeSystem => 'Défaut du système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsLangEnglish => 'Anglais';

  @override
  String get settingsLangItalian => 'Italien';

  @override
  String get settingsLangSpanish => 'Espagnol';

  @override
  String get settingsLangFrench => 'Français';

  @override
  String get settingsLangGerman => 'Allemand';

  @override
  String get settingsApiKeySetFirst => 'Veuillez d\'abord définir ta clé API';

  @override
  String get settingsApiKeyFetchError =>
      'Impossible de récupérer les modèles depuis l\'API. Utilisation du modèle par défaut.';

  @override
  String get settingsEditProfile => 'Modifier le profil';

  @override
  String get settingsProfileUpdated => 'Profil mis à jour !';

  @override
  String get settingsApiKeyDescription =>
      'Saisis ta clé API Google Gemini pour la fonctionnalité de scan de menu.';

  @override
  String get settingsApiKeyLabel => 'Clé API';

  @override
  String get sessionsTitle => 'Tables';

  @override
  String get sessionsEmpty => 'Aucune table pour l\'instant';

  @override
  String get sessionsEmptySubtitle =>
      'Crée une nouvelle table pour commander ensemble, ou rejoins celle d\'un ami.';

  @override
  String get sessionsNewTable => 'Nouvelle table';

  @override
  String get sessionsJoinTable => 'Rejoindre une table';

  @override
  String get sessionsJoinTooltip => 'Rejoindre la table';

  @override
  String get sessionStatusOpen => 'Ouverte';

  @override
  String get sessionStatusSent => 'Commande envoyée';

  @override
  String get sessionStatusClosed => 'Fermée';

  @override
  String get sessionCardHost => 'Hôte';

  @override
  String get sessionCardUnknownRestaurant => 'Restaurant inconnu';

  @override
  String get sessionTimeJustNow => 'À l\'instant';

  @override
  String sessionTimeMinutesAgo(int count) {
    return 'Il y a $count min';
  }

  @override
  String sessionTimeHoursAgo(int count) {
    return 'Il y a $count h';
  }

  @override
  String sessionTimeDaysAgo(int count) {
    return 'Il y a $count jour(s)';
  }

  @override
  String get sessionActionsShareTable => 'Partager la table';

  @override
  String get sessionActionsLeaveTable => 'Quitter la table';

  @override
  String get sessionLeaveTitle => 'Quitter la table';

  @override
  String get sessionLeaveMessage =>
      'La table sera gelée. Personne ne pourra la rejoindre ni y apporter des modifications.';

  @override
  String get sessionDeleteTitle => 'Supprimer la table';

  @override
  String sessionDeleteMessage(String name) {
    return 'Veux-tu vraiment supprimer \"$name\" ?';
  }

  @override
  String get shareTableTitle => 'Partager la table';

  @override
  String get shareTableQrHint =>
      'D\'autres peuvent rejoindre en scannant ce code QR :';

  @override
  String get shareTableCodeHint => 'Ou saisis ce code :';

  @override
  String get joinTableTitle => 'Rejoindre la table';

  @override
  String get joinTableHeading => 'Rejoindre une table';

  @override
  String get joinTableSubtitle =>
      'Saisis le code de table ou scanne le code QR';

  @override
  String get joinTableScanQr => 'Scanner le code QR';

  @override
  String get joinTableOpenScanner => 'Ouvrir le scanner';

  @override
  String get joinTableEnterCode => 'Saisir le code manuellement';

  @override
  String get joinTableCodeLabel => 'Code de table';

  @override
  String get joinTableCodeHint => 'ex. ABC12345';

  @override
  String get joinTableJoin => 'Rejoindre la table';

  @override
  String get joinTableStartNew => 'Ou créer une nouvelle table';

  @override
  String get joinTableScanHint => 'Pointe la caméra sur le code QR';

  @override
  String get joinTableHostLabel => 'Adresse de l\'hôte';

  @override
  String get joinTableHostHint => 'ex. 192.168.1.100:8080';

  @override
  String get newTableTitle => 'Nouvelle table';

  @override
  String get newTableHeading => 'Créer une nouvelle table de commande';

  @override
  String get newTableSubtitle =>
      'Crée une table et invite d\'autres personnes à la rejoindre';

  @override
  String get newTableNameLabel => 'Nom de la table';

  @override
  String get newTableNameHint => 'ex. Dîner du vendredi';

  @override
  String get newTableNameRequired => 'Veuillez saisir un nom pour la table';

  @override
  String get newTableSelectRestaurant =>
      'Sélectionner un restaurant (optionnel)';

  @override
  String get newTableNoRestaurants =>
      'Aucun restaurant enregistré pour l\'instant';

  @override
  String get newTableNoRestaurantsSubtitle =>
      'Un restaurant sera créé automatiquement au démarrage de la table.';

  @override
  String get newTableAddRestaurant => 'Ajouter un restaurant';

  @override
  String newTableMenuItems(int count) {
    return '$count article(s)';
  }

  @override
  String get newTableStart => 'Démarrer la table';

  @override
  String newTableError(String error) {
    return 'Erreur lors de la création de la table : $error';
  }

  @override
  String get restaurantsTitle => 'Restaurants';

  @override
  String get restaurantsEmpty => 'Aucun restaurant pour l\'instant';

  @override
  String get restaurantsEmptySubtitle =>
      'Ajoute ton premier restaurant pour commencer';

  @override
  String get restaurantsAdd => 'Ajouter un restaurant';

  @override
  String restaurantDishes(int count) {
    return '$count plat(s)';
  }

  @override
  String restaurantTemplatesCount(int count) {
    return '$count modèle(s)';
  }

  @override
  String get restaurantDeleteTitle => 'Supprimer le restaurant';

  @override
  String restaurantDeleteMessage(String name) {
    return 'Veux-tu vraiment supprimer \"$name\" ?';
  }

  @override
  String get restaurantAddCoverPhoto => 'Ajouter une photo de couverture';

  @override
  String get restaurantAddTitle => 'Ajouter un restaurant';

  @override
  String get restaurantNameLabel => 'Nom du restaurant';

  @override
  String get restaurantAddressLabel => 'Adresse (optionnel)';

  @override
  String get restaurantEditTitle => 'Modifier le restaurant';

  @override
  String get restaurantNotFound => 'Restaurant introuvable';

  @override
  String get restaurantOrderTemplates => 'Modèles de commande';

  @override
  String get restaurantTemplatesEmpty =>
      'Aucun modèle pour l\'instant. Ajoutes-en un ici ou enregistre depuis une commande personnelle.';

  @override
  String get restaurantMenuSection => 'Menu';

  @override
  String get restaurantScanButton => 'Scanner';

  @override
  String get restaurantMenuMarkYummie => 'Marquer comme délicieux';

  @override
  String get restaurantMenuRemoveYummie => 'Retirer délicieux';

  @override
  String get restaurantTemplateDeleteTitle => 'Supprimer le modèle';

  @override
  String restaurantTemplateDeleteMessage(String name) {
    return 'Veux-tu vraiment supprimer \"$name\" ?';
  }

  @override
  String get restaurantTemplateReplaceTitle => 'Remplacer le modèle';

  @override
  String get restaurantTemplateReplaceMessage =>
      'Veux-tu aussi supprimer l\'ancienne version ?';

  @override
  String get restaurantTemplateNewTitle => 'Nouveau modèle de commande';

  @override
  String get restaurantTemplateEditTitle => 'Modifier le modèle de commande';

  @override
  String get restaurantTemplateNameLabel => 'Nom du modèle';

  @override
  String get restaurantTemplateSelectDishes =>
      'Sélectionne les plats à inclure :';

  @override
  String restaurantTemplateSave(int count) {
    return 'Enregistrer le modèle ($count article(s))';
  }

  @override
  String get restaurantMenuItemEditTitle => 'Modifier l\'élément du menu';

  @override
  String get restaurantMenuItemAddTitle => 'Ajouter un élément au menu';

  @override
  String get restaurantMenuItemNameLabel => 'Nom de l\'article';

  @override
  String get restaurantMenuItemDescLabel => 'Description (optionnel)';

  @override
  String get restaurantMenuItemNumberLabel => 'Numéro d\'article';

  @override
  String get sessionTableNotFound => 'Table introuvable';

  @override
  String get sessionShareTooltip => 'Partager la table';

  @override
  String get sessionLeaveTableMenu => 'Quitter la table';

  @override
  String get sessionDeleteTableMenu => 'Supprimer la table';

  @override
  String get sessionCloseTitle => 'Fermer la table';

  @override
  String get sessionCloseMessage =>
      'Es-tu sûr(e) ? Les participants ne pourront plus rejoindre ni commander.';

  @override
  String get sessionCloseButton => 'Fermer';

  @override
  String get sessionDeleteMessage2 =>
      'Veux-tu vraiment supprimer cette table ?';

  @override
  String get sessionClosedBanner =>
      'Cette table a été quittée — aucune modification ne peut être apportée';

  @override
  String get sessionUnreachableBanner =>
      'Session temporairement injoignable — en attente de reconnexion de l\'hôte';

  @override
  String get sessionTabMyOrder => 'Ma commande';

  @override
  String get sessionTabGroup => 'Groupe';

  @override
  String get sessionTabChecklist => 'Liste de contrôle';

  @override
  String get checklistComplete => 'Terminé';

  @override
  String get checklistHostSubtitle =>
      'Suis ce qui est arrivé de toutes les commandes';

  @override
  String get checklistGuestSubtitle => 'Suis ce qui est arrivé de tes plats';

  @override
  String get checklistNoOrder => 'Aucune commande à suivre';

  @override
  String get checklistNoOrderHint => 'La commande n\'a pas encore été envoyée';

  @override
  String checklistArrivedOf(int arrived, int total) {
    return '$arrived sur $total arrivé(s)';
  }

  @override
  String get checklistHostOnly =>
      'Seul l\'hôte peut mettre à jour le statut d\'arrivée';

  @override
  String checklistOrderLabel(int number) {
    return 'Commande $number';
  }

  @override
  String checklistItemsCount(int count) {
    return '$count article(s)';
  }

  @override
  String get mergedOrderParticipants => 'Participants';

  @override
  String get mergedOrderWaiting =>
      'En attente que tous les participants verrouillent leurs commandes';

  @override
  String get mergedOrderSend => 'Envoyer la commande';

  @override
  String get mergedOrderOpenRound => 'Ouvrir un nouveau tour';

  @override
  String get mergedOrderCurrentEmpty => 'Commande actuelle — vide';

  @override
  String get mergedOrderNoItems => 'Aucun article pour l\'instant';

  @override
  String mergedOrderBy(int count) {
    return 'Par $count participant(s)';
  }

  @override
  String mergedOrderItemsCount(int count) {
    return '$count article(s)';
  }

  @override
  String get mergedOrderSendLocked =>
      'Tous les participants doivent d\'abord verrouiller leurs commandes';

  @override
  String mergedOrderSent(String label) {
    return '$label envoyé(e) ! Les participants ne peuvent plus modifier.';
  }

  @override
  String mergedOrderRoundOpened(int number) {
    return 'Tour $number ouvert ! Les participants peuvent ajouter de nouveaux articles.';
  }

  @override
  String mergedOrderOpenRoundTitle(int number) {
    return 'Ouvrir le tour $number';
  }

  @override
  String get mergedOrderOpenRoundDescription =>
      'Cela permettra aux participants d\'ajouter des articles à une nouvelle commande. Les commandes actuelles seront verrouillées.';

  @override
  String get mergedOrderOpenRoundButton => 'Ouvrir le tour';

  @override
  String get mergedParticipantOrderAdded => 'Commande ajoutée';

  @override
  String get mergedParticipantNoOrder => 'Pas encore de commande';

  @override
  String get mergedParticipantItemsOrdered => 'Articles commandés';

  @override
  String get mergedOrderCurrentOrder => 'Commande actuelle';

  @override
  String get personalOrderEmpty => 'Ta commande est vide';

  @override
  String get personalOrderEmptyHint =>
      'Appuie sur le bouton ci-dessous pour ajouter des plats';

  @override
  String personalOrderTitle(int count) {
    return 'Ta commande ($count article(s))';
  }

  @override
  String get personalOrderSaveButton => 'Enregistrer';

  @override
  String get personalOrderAddFromMenu => 'Ajouter depuis le menu';

  @override
  String get personalOrderCustomDish => 'Plat personnalisé';

  @override
  String get personalOrderUseTemplate => 'Utiliser un modèle';

  @override
  String get personalOrderFromMenu => 'Depuis le menu';

  @override
  String personalOrderAddItemsButton(int count) {
    return 'Ajouter $count article(s)';
  }

  @override
  String get personalOrderCustomDishName => 'Nom du plat';

  @override
  String get personalOrderCustomDishDesc => 'Description (optionnel)';

  @override
  String get personalOrderCustomDishNumber => 'Numéro de menu (optionnel)';

  @override
  String get personalOrderChooseTemplate => 'Choisir un modèle';

  @override
  String get personalOrderSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get personalOrderTemplateNameLabel => 'Nom du modèle';

  @override
  String personalOrderTemplateSaved(String name) {
    return 'Modèle \"$name\" enregistré';
  }

  @override
  String personalOrderCustomDishAdded(String name) {
    return '\"$name\" ajouté à la commande';
  }

  @override
  String personalOrderSaved(int count) {
    return 'Commande enregistrée avec $count article(s)';
  }

  @override
  String get personalOrderLogin => 'Veuillez d\'abord te connecter';

  @override
  String get personalOrderRestaurantNotFound => 'Restaurant introuvable';

  @override
  String get personalOrderSentBanner =>
      'Commande envoyée — attends que l\'hôte ouvre un nouveau tour avant d\'ajouter des articles.';

  @override
  String get scanMenuTitle => 'Scanner le menu';

  @override
  String get scanMenuHeading =>
      'Scanne les pages du menu pour ajouter des articles';

  @override
  String get scanMenuSubtitle =>
      'Prends des photos ou choisis depuis la galerie — plusieurs pages sont prises en charge. L\'IA extraira les articles et fusionnera les doublons automatiquement.';

  @override
  String scanMenuPagesScanned(int count) {
    return '$count page(s) scannée(s)';
  }

  @override
  String get scanMenuTakePhoto => 'Prendre une photo';

  @override
  String get scanMenuAddPhoto => 'Ajouter une photo';

  @override
  String get scanMenuGallery => 'Galerie';

  @override
  String get scanMenuAddFromGallery => 'Ajouter depuis la galerie';

  @override
  String get scanMenuAnalyzing => 'Analyse de la page…';

  @override
  String scanMenuItemsFound(int count) {
    return '$count article(s) trouvé(s) :';
  }

  @override
  String get scanMenuRemoveItem => 'Supprimer';

  @override
  String get scanMenuSaveButton => 'Enregistrer dans le menu';

  @override
  String get scanMenuApiKeyHint =>
      'Nécessite une clé API Google Gemini pour l\'analyse IA. Ajoute-la dans Paramètres > Service IA.';

  @override
  String get scanMenuNoApiKey =>
      'Veuillez d\'abord ajouter ta clé API Google Gemini dans les Paramètres';

  @override
  String get scanMenuStartOver => 'Recommencer';

  @override
  String get scanMenuUpdated => 'Menu mis à jour avec succès !';

  @override
  String get scanMenuNumberConflicts => 'Conflits de numéros';

  @override
  String scanMenuConflictDescription(int count) {
    return '$count article(s) partagent un numéro avec des éléments du menu existants.';
  }

  @override
  String scanMenuNumberConflictLabel(int number) {
    return 'Conflit numéro #$number';
  }

  @override
  String get scanMenuConflictExisting => 'Existant';

  @override
  String get scanMenuConflictNew => 'Nouveau';

  @override
  String get scanMenuKeepExisting => 'Conserver l\'existant';

  @override
  String get scanMenuUseNew => 'Utiliser le nouveau';

  @override
  String get scanMenuKeepBoth => 'Conserver les deux';

  @override
  String get scanMenuSaveTitle => 'Enregistrer les articles scannés';

  @override
  String scanMenuSaveDescription(int count) {
    return 'Le menu contient déjà $count article(s). Comment veux-tu enregistrer le nouveau scan ?';
  }

  @override
  String get scanMenuAppend => 'Ajouter au menu existant';

  @override
  String get scanMenuReplace => 'Remplacer tout le menu';

  @override
  String get checklistTitle => 'Liste de contrôle';

  @override
  String get leave => 'Quitter';

  @override
  String get personalOrderAddCustomDishTitle => 'Ajouter un plat personnalisé';
}

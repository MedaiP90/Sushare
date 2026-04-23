// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sushare';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get confirm => 'Confirmar';

  @override
  String get retry => 'Reintentar';

  @override
  String get keep => 'Conservar';

  @override
  String get clear => 'Borrar';

  @override
  String get loading => 'Cargando...';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get navTables => 'Mesas';

  @override
  String get navRestaurants => 'Restaurantes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get welcomeTitle => 'Bienvenido a Sushare';

  @override
  String get profileSetupSubtitle => 'Vamos a configurar tu perfil';

  @override
  String get tapToAddPhoto => 'Toca para añadir foto';

  @override
  String get labelUsername => 'Nombre de usuario';

  @override
  String get hintUsername => 'Elige un nombre de usuario único';

  @override
  String get validationUsernameRequired =>
      'Por favor, introduce un nombre de usuario';

  @override
  String get validationUsernameMinLength =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String get labelFirstName => 'Nombre';

  @override
  String get hintFirstName => 'Introduce tu nombre';

  @override
  String get validationFirstNameRequired => 'Por favor, introduce tu nombre';

  @override
  String get labelLastName => 'Apellido';

  @override
  String get hintLastName => 'Introduce tu apellido';

  @override
  String get validationLastNameRequired => 'Por favor, introduce tu apellido';

  @override
  String get getStarted => 'Comenzar';

  @override
  String errorSavingProfile(String error) {
    return 'Error al guardar el perfil: $error';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionAiService => 'Servicio de IA';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsNoProfile => 'Sin perfil';

  @override
  String get settingsNoProfileSubtitle => 'Crea un perfil para comenzar';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsGeminiApiKey => 'Clave API de Google Gemini';

  @override
  String get settingsGeminiApiKeySubtitle => 'Para escanear menús';

  @override
  String get settingsAiModel => 'Modelo de IA';

  @override
  String get settingsAppVersion => 'Versión de la app';

  @override
  String get settingsThemeSystem => 'Predeterminado del sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsLangEnglish => 'Inglés';

  @override
  String get settingsLangItalian => 'Italiano';

  @override
  String get settingsLangSpanish => 'Español';

  @override
  String get settingsLangFrench => 'Francés';

  @override
  String get settingsLangGerman => 'Alemán';

  @override
  String get settingsApiKeySetFirst =>
      'Por favor, configura primero tu clave API';

  @override
  String get settingsApiKeyFetchError =>
      'No se pudieron obtener los modelos de la API. Usando el predeterminado.';

  @override
  String get settingsEditProfile => 'Editar perfil';

  @override
  String get settingsProfileUpdated => '¡Perfil actualizado!';

  @override
  String get settingsApiKeyDescription =>
      'Introduce tu clave API de Google Gemini para la función de escaneo de menús.';

  @override
  String get settingsApiKeyLabel => 'Clave API';

  @override
  String get sessionsTitle => 'Mesas';

  @override
  String get sessionsEmpty => 'Aún no hay mesas';

  @override
  String get sessionsEmptySubtitle =>
      'Crea una nueva mesa para pedir juntos, o únete a la de un amigo.';

  @override
  String get sessionsNewTable => 'Nueva mesa';

  @override
  String get sessionsJoinTable => 'Unirse a una mesa';

  @override
  String get sessionsJoinTooltip => 'Unirse a la mesa';

  @override
  String get sessionStatusOpen => 'Abierta';

  @override
  String get sessionStatusSent => 'Pedido enviado';

  @override
  String get sessionStatusClosed => 'Cerrada';

  @override
  String get sessionCardHost => 'Anfitrión';

  @override
  String get sessionCardUnknownRestaurant => 'Restaurante desconocido';

  @override
  String get sessionTimeJustNow => 'Ahora mismo';

  @override
  String sessionTimeMinutesAgo(int count) {
    return 'Hace $count min';
  }

  @override
  String sessionTimeHoursAgo(int count) {
    return 'Hace $count h';
  }

  @override
  String sessionTimeDaysAgo(int count) {
    return 'Hace $count día(s)';
  }

  @override
  String get sessionActionsShareTable => 'Compartir mesa';

  @override
  String get sessionActionsLeaveTable => 'Abandonar la mesa';

  @override
  String get sessionLeaveTitle => 'Abandonar la mesa';

  @override
  String get sessionLeaveMessage =>
      'La mesa quedará bloqueada. Nadie podrá unirse ni hacer cambios.';

  @override
  String get sessionDeleteTitle => 'Eliminar mesa';

  @override
  String sessionDeleteMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get shareTableTitle => 'Compartir mesa';

  @override
  String get shareTableQrHint =>
      'Otros pueden unirse escaneando este código QR:';

  @override
  String get shareTableCodeHint => 'O introduce este código:';

  @override
  String get joinTableTitle => 'Unirse a la mesa';

  @override
  String get joinTableHeading => 'Unirse a una mesa';

  @override
  String get joinTableSubtitle =>
      'Introduce el código de mesa o escanea el código QR';

  @override
  String get joinTableScanQr => 'Escanear código QR';

  @override
  String get joinTableOpenScanner => 'Abrir escáner';

  @override
  String get joinTableEnterCode => 'Introducir código manualmente';

  @override
  String get joinTableCodeLabel => 'Código de mesa';

  @override
  String get joinTableCodeHint => 'p. ej., ABC12345';

  @override
  String get joinTableJoin => 'Unirse a la mesa';

  @override
  String get joinTableStartNew => 'O crear una nueva mesa';

  @override
  String get joinTableScanHint => 'Apunta la cámara al código QR';

  @override
  String get newTableTitle => 'Nueva mesa';

  @override
  String get newTableHeading => 'Crear una nueva mesa de pedidos';

  @override
  String get newTableSubtitle => 'Crea una mesa e invita a otros a unirse';

  @override
  String get newTableNameLabel => 'Nombre de la mesa';

  @override
  String get newTableNameHint => 'p. ej., Cena del viernes';

  @override
  String get newTableNameRequired =>
      'Por favor, introduce un nombre para la mesa';

  @override
  String get newTableSelectRestaurant => 'Seleccionar restaurante (opcional)';

  @override
  String get newTableNoRestaurants => 'Aún no hay restaurantes guardados';

  @override
  String get newTableNoRestaurantsSubtitle =>
      'Se creará un restaurante automáticamente al iniciar la mesa.';

  @override
  String get newTableAddRestaurant => 'Añadir un restaurante';

  @override
  String newTableMenuItems(int count) {
    return '$count artículos';
  }

  @override
  String get newTableStart => 'Iniciar mesa';

  @override
  String newTableError(String error) {
    return 'Error al crear la mesa: $error';
  }

  @override
  String get restaurantsTitle => 'Restaurantes';

  @override
  String get restaurantsEmpty => 'Aún no hay restaurantes';

  @override
  String get restaurantsEmptySubtitle =>
      'Añade tu primer restaurante para comenzar';

  @override
  String get restaurantsAdd => 'Añadir restaurante';

  @override
  String restaurantDishes(int count) {
    return '$count platos';
  }

  @override
  String restaurantTemplatesCount(int count) {
    return '$count plantillas';
  }

  @override
  String get restaurantDeleteTitle => 'Eliminar restaurante';

  @override
  String restaurantDeleteMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get restaurantAddCoverPhoto => 'Añadir foto de portada';

  @override
  String get restaurantAddTitle => 'Añadir restaurante';

  @override
  String get restaurantNameLabel => 'Nombre del restaurante';

  @override
  String get restaurantAddressLabel => 'Dirección (opcional)';

  @override
  String get restaurantEditTitle => 'Editar restaurante';

  @override
  String get restaurantNotFound => 'Restaurante no encontrado';

  @override
  String get restaurantOrderTemplates => 'Plantillas de pedidos';

  @override
  String get restaurantTemplatesEmpty =>
      'Aún no hay plantillas. Añade una aquí o guarda desde un pedido personal.';

  @override
  String get restaurantMenuSection => 'Menú';

  @override
  String get restaurantScanButton => 'Escanear';

  @override
  String get restaurantMenuMarkYummie => 'Marcar como rico';

  @override
  String get restaurantMenuRemoveYummie => 'Quitar rico';

  @override
  String get restaurantTemplateDeleteTitle => 'Eliminar plantilla';

  @override
  String restaurantTemplateDeleteMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get restaurantTemplateReplaceTitle => 'Reemplazar plantilla';

  @override
  String get restaurantTemplateReplaceMessage =>
      '¿También quieres eliminar la versión anterior?';

  @override
  String get restaurantTemplateNewTitle => 'Nueva plantilla de pedido';

  @override
  String get restaurantTemplateEditTitle => 'Editar plantilla de pedido';

  @override
  String get restaurantTemplateNameLabel => 'Nombre de la plantilla';

  @override
  String get restaurantTemplateSelectDishes =>
      'Selecciona los platos a incluir:';

  @override
  String restaurantTemplateSave(int count) {
    return 'Guardar plantilla ($count artículos)';
  }

  @override
  String get restaurantMenuItemEditTitle => 'Editar elemento del menú';

  @override
  String get restaurantMenuItemAddTitle => 'Añadir elemento al menú';

  @override
  String get restaurantMenuItemNameLabel => 'Nombre del artículo';

  @override
  String get restaurantMenuItemDescLabel => 'Descripción (opcional)';

  @override
  String get restaurantMenuItemNumberLabel => 'Número de artículo';

  @override
  String get sessionTableNotFound => 'Mesa no encontrada';

  @override
  String get sessionShareTooltip => 'Compartir mesa';

  @override
  String get sessionLeaveTableMenu => 'Abandonar la mesa';

  @override
  String get sessionDeleteTableMenu => 'Eliminar mesa';

  @override
  String get sessionCloseTitle => 'Cerrar mesa';

  @override
  String get sessionCloseMessage =>
      '¿Estás seguro? Los participantes no podrán unirse ni pedir.';

  @override
  String get sessionCloseButton => 'Cerrar';

  @override
  String get sessionDeleteMessage2 => '¿Seguro que quieres eliminar esta mesa?';

  @override
  String get sessionClosedBanner =>
      'Esta mesa ha sido abandonada — no se pueden hacer más cambios';

  @override
  String get sessionTabMyOrder => 'Mi pedido';

  @override
  String get sessionTabGroup => 'Grupo';

  @override
  String get sessionTabChecklist => 'Lista de verificación';

  @override
  String get checklistComplete => 'Completo';

  @override
  String get checklistHostSubtitle =>
      'Controla qué ha llegado de todos los pedidos';

  @override
  String get checklistGuestSubtitle => 'Controla qué ha llegado de tus platos';

  @override
  String get checklistNoOrder => 'No hay pedido que seguir';

  @override
  String get checklistNoOrderHint => 'El pedido aún no ha sido enviado';

  @override
  String checklistArrivedOf(int arrived, int total) {
    return '$arrived de $total llegados';
  }

  @override
  String get checklistHostOnly =>
      'Solo el anfitrión puede actualizar el estado de llegada';

  @override
  String checklistOrderLabel(int number) {
    return 'Pedido $number';
  }

  @override
  String checklistItemsCount(int count) {
    return '$count artículos';
  }

  @override
  String get mergedOrderParticipants => 'Participantes';

  @override
  String get mergedOrderWaiting =>
      'Esperando a que todos los participantes bloqueen sus pedidos';

  @override
  String get mergedOrderSend => 'Enviar pedido';

  @override
  String get mergedOrderOpenRound => 'Abrir nueva ronda';

  @override
  String get mergedOrderCurrentEmpty => 'Pedido actual — vacío';

  @override
  String get mergedOrderNoItems => 'Aún no hay artículos';

  @override
  String mergedOrderBy(int count) {
    return 'Por $count participante(s)';
  }

  @override
  String mergedOrderItemsCount(int count) {
    return '$count artículos';
  }

  @override
  String get mergedOrderSendLocked =>
      'Todos los participantes deben bloquear sus pedidos primero';

  @override
  String mergedOrderSent(String label) {
    return '¡$label enviado! Los participantes ya no pueden editar.';
  }

  @override
  String mergedOrderRoundOpened(int number) {
    return '¡Ronda $number abierta! Los participantes pueden añadir nuevos artículos.';
  }

  @override
  String mergedOrderOpenRoundTitle(int number) {
    return 'Abrir ronda $number';
  }

  @override
  String get mergedOrderOpenRoundDescription =>
      'Esto permitirá a los participantes añadir artículos a un nuevo pedido. Los pedidos actuales quedarán bloqueados.';

  @override
  String get mergedOrderOpenRoundButton => 'Abrir ronda';

  @override
  String get mergedParticipantOrderAdded => 'Pedido añadido';

  @override
  String get mergedParticipantNoOrder => 'Aún sin pedido';

  @override
  String get mergedParticipantItemsOrdered => 'Artículos pedidos';

  @override
  String get mergedOrderCurrentOrder => 'Pedido actual';

  @override
  String get personalOrderEmpty => 'Tu pedido está vacío';

  @override
  String get personalOrderEmptyHint =>
      'Toca el botón de abajo para añadir platos';

  @override
  String personalOrderTitle(int count) {
    return 'Tu pedido ($count artículos)';
  }

  @override
  String get personalOrderSaveButton => 'Guardar';

  @override
  String get personalOrderAddFromMenu => 'Añadir desde el menú';

  @override
  String get personalOrderCustomDish => 'Plato personalizado';

  @override
  String get personalOrderUseTemplate => 'Usar plantilla';

  @override
  String get personalOrderFromMenu => 'Desde el menú';

  @override
  String personalOrderAddItemsButton(int count) {
    return 'Añadir $count artículos';
  }

  @override
  String get personalOrderCustomDishName => 'Nombre del plato';

  @override
  String get personalOrderCustomDishDesc => 'Descripción (opcional)';

  @override
  String get personalOrderCustomDishNumber => 'Número de menú (opcional)';

  @override
  String get personalOrderChooseTemplate => 'Elegir una plantilla';

  @override
  String get personalOrderSaveAsTemplate => 'Guardar como plantilla';

  @override
  String get personalOrderTemplateNameLabel => 'Nombre de la plantilla';

  @override
  String personalOrderTemplateSaved(String name) {
    return 'Plantilla \"$name\" guardada';
  }

  @override
  String personalOrderCustomDishAdded(String name) {
    return '\"$name\" añadido al pedido';
  }

  @override
  String personalOrderSaved(int count) {
    return 'Pedido guardado con $count artículos';
  }

  @override
  String get personalOrderLogin => 'Por favor, inicia sesión primero';

  @override
  String get personalOrderRestaurantNotFound => 'Restaurante no encontrado';

  @override
  String get scanMenuTitle => 'Escanear menú';

  @override
  String get scanMenuHeading =>
      'Escanea páginas del menú para añadir artículos';

  @override
  String get scanMenuSubtitle =>
      'Toma fotos o elige de la galería — se admiten varias páginas. La IA extraerá los artículos y fusionará duplicados automáticamente.';

  @override
  String scanMenuPagesScanned(int count) {
    return '$count página(s) escaneada(s)';
  }

  @override
  String get scanMenuTakePhoto => 'Tomar foto';

  @override
  String get scanMenuAddPhoto => 'Añadir foto';

  @override
  String get scanMenuGallery => 'Galería';

  @override
  String get scanMenuAddFromGallery => 'Añadir desde galería';

  @override
  String get scanMenuAnalyzing => 'Analizando página…';

  @override
  String scanMenuItemsFound(int count) {
    return '$count artículo(s) encontrado(s):';
  }

  @override
  String get scanMenuRemoveItem => 'Eliminar';

  @override
  String get scanMenuSaveButton => 'Guardar en el menú';

  @override
  String get scanMenuApiKeyHint =>
      'Requiere una clave API de Google Gemini para el análisis con IA. Añádela en Ajustes > Servicio de IA.';

  @override
  String get scanMenuNoApiKey =>
      'Por favor, añade primero tu clave API de Google Gemini en Ajustes';

  @override
  String get scanMenuStartOver => 'Empezar de nuevo';

  @override
  String get scanMenuUpdated => '¡Menú actualizado correctamente!';

  @override
  String get scanMenuNumberConflicts => 'Conflictos de número';

  @override
  String scanMenuConflictDescription(int count) {
    return '$count artículo(s) comparten número con elementos del menú existentes.';
  }

  @override
  String scanMenuNumberConflictLabel(int number) {
    return 'Conflicto con el número #$number';
  }

  @override
  String get scanMenuConflictExisting => 'Existente';

  @override
  String get scanMenuConflictNew => 'Nuevo';

  @override
  String get scanMenuKeepExisting => 'Conservar el existente';

  @override
  String get scanMenuUseNew => 'Usar el nuevo';

  @override
  String get scanMenuKeepBoth => 'Conservar ambos';

  @override
  String get scanMenuSaveTitle => 'Guardar artículos escaneados';

  @override
  String scanMenuSaveDescription(int count) {
    return 'El menú ya tiene $count artículo(s). ¿Cómo quieres guardar el nuevo escaneo?';
  }

  @override
  String get scanMenuAppend => 'Añadir al menú existente';

  @override
  String get scanMenuReplace => 'Reemplazar todo el menú';

  @override
  String get checklistTitle => 'Lista de verificación';

  @override
  String get leave => 'Abandonar';

  @override
  String get personalOrderAddCustomDishTitle => 'Añadir plato personalizado';
}

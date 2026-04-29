import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/avatar_widget.dart';
import '../../../services/menu_ai_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  static const _key = 'locale';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = Locale(value);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

final _selectedModelProvider = FutureProvider<String?>((ref) async {
  final service = MenuAiService();
  final hasKey = await service.hasApiKey();
  if (!hasKey) return null;
  return service.getModel();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(profileViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsSectionProfile),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return ListTile(
                  title: Text(l10n.settingsNoProfile),
                  subtitle: Text(l10n.settingsNoProfileSubtitle),
                );
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(user.avatarColorValue),
                  child: Icon(
                    IconData(user.avatarIconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                  ),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text('@${user.username}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditProfileSheet(context, ref),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text(l10n.errorMessage(e.toString()))),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionAppearance),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l10n.settingsTheme),
            subtitle: Text(_getThemeModeText(l10n, themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSheet(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_getLocaleText(l10n, locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSheet(context, ref, l10n),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionAiService),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: Text(l10n.settingsGeminiApiKey),
            subtitle: Text(l10n.settingsGeminiApiKeySubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showApiKeySheet(context, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: Text(l10n.settingsAiModel),
            subtitle: ref.watch(_selectedModelProvider).when(
              data: (model) => Text(model ?? 'gemini-2.5-flash-lite'),
              loading: () => Text(l10n.loading),
              error: (_, __) => const Text('gemini-2.5-flash-lite'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showModelSheet(context, ref, l10n),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAppVersion),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
    }
  }

  String _getLocaleText(AppLocalizations l10n, Locale? locale) {
    if (locale == null) return l10n.settingsThemeSystem;
    switch (locale.languageCode) {
      case 'en':
        return l10n.settingsLangEnglish;
      case 'it':
        return l10n.settingsLangItalian;
      case 'es':
        return l10n.settingsLangSpanish;
      case 'fr':
        return l10n.settingsLangFrench;
      case 'de':
        return l10n.settingsLangGerman;
      default:
        return l10n.settingsThemeSystem;
    }
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.settingsTheme,
        children: ThemeMode.values.map((mode) {
          final label = switch (mode) {
            ThemeMode.system => l10n.settingsThemeSystem,
            ThemeMode.light => l10n.settingsThemeLight,
            ThemeMode.dark => l10n.settingsThemeDark,
          };
          return RadioListTile<ThemeMode>(
            title: Text(label),
            value: mode,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setTheme(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLocale = ref.read(localeProvider);
    final options = [
      (null as String?, l10n.settingsThemeSystem),
      ('en', l10n.settingsLangEnglish),
      ('it', l10n.settingsLangItalian),
      ('es', l10n.settingsLangSpanish),
      ('fr', l10n.settingsLangFrench),
      ('de', l10n.settingsLangGerman),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: l10n.settingsLanguage,
        children: options.map(((String? code, String label) opt) {
          final locale = opt.$1 != null ? Locale(opt.$1!) : null;
          return _LanguageOption(
            locale: locale,
            label: opt.$2,
            currentLocale: currentLocale,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(locale);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(profileViewModelProvider).value;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditProfileSheet(user: user, ref: ref),
    );
  }

  void _showApiKeySheet(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    final menuAiService = MenuAiService();

    menuAiService.getApiKey().then((key) {
      if (key != null) controller.text = key;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ApiKeySheet(
        controller: controller,
        menuAiService: menuAiService,
      ),
    );
  }

  void _showModelSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final menuAiService = MenuAiService();
    final hasKey = await menuAiService.hasApiKey();

    if (!hasKey) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsApiKeySetFirst)),
        );
      }
      return;
    }

    final availableModels = await menuAiService.getAvailableModels();
    final currentModel = await menuAiService.getModel();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModelPickerSheet(
        availableModels: availableModels,
        currentModel: currentModel,
        menuAiService: menuAiService,
        onModelSelected: () {
          ref.invalidate(_selectedModelProvider);
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final Locale? locale;
  final String label;
  final Locale? currentLocale;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale?.languageCode == currentLocale?.languageCode;

    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
      selected: isSelected,
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PickerSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final dynamic user;
  final WidgetRef ref;

  const _EditProfileSheet({required this.user, required this.ref});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late AvatarData _avatarData;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _avatarData = AvatarData(
      iconCodePoint: widget.user.avatarIconCodePoint,
      colorValue: widget.user.avatarColorValue,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onAvatarChanged(AvatarData data) {
    setState(() => _avatarData = data);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.settingsEditProfile, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(_avatarData.colorValue),
                      child: Icon(
                        IconData(_avatarData.iconCodePoint, fontFamily: 'MaterialIcons'),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.edit, size: 16, color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l10n.labelUsername,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.labelFirstName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.labelLastName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await widget.ref
                          .read(profileViewModelProvider.notifier)
                          .updateProfile(
                            username: _usernameController.text.trim(),
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                            avatarIconCodePoint: _avatarData.iconCodePoint,
                            avatarColorValue: _avatarData.colorValue,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsProfileUpdated)),
                        );
                      }
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: AvatarSelector(
            initialData: _avatarData,
            onChanged: _onAvatarChanged,
          ),
        ),
      ),
    );
  }
}

class _ApiKeySheet extends StatelessWidget {
  final TextEditingController controller;
  final MenuAiService menuAiService;

  const _ApiKeySheet({
    required this.controller,
    required this.menuAiService,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.settingsGeminiApiKey, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.settingsApiKeyDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.settingsApiKeyLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await menuAiService.deleteApiKey();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.clear),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await menuAiService.setApiKey(controller.text.trim());
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPickerSheet extends StatefulWidget {
  final List<String> availableModels;
  final String currentModel;
  final MenuAiService menuAiService;
  final VoidCallback onModelSelected;

  const _ModelPickerSheet({
    required this.availableModels,
    required this.currentModel,
    required this.menuAiService,
    required this.onModelSelected,
  });

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  late String _selectedModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final models = widget.availableModels.isEmpty
        ? [widget.currentModel]
        : widget.availableModels;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text(l10n.settingsAiModel, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (widget.availableModels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.settingsApiKeyFetchError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),
            const SizedBox(height: 8),
            ListView(
              shrinkWrap: true,
              children: models
                  .map((model) => RadioListTile<String>(
                        title: Text(model, overflow: TextOverflow.ellipsis),
                        value: model,
                        groupValue: _selectedModel,
                        onChanged: widget.availableModels.isEmpty
                            ? null
                            : (value) {
                                setState(() => _selectedModel = value!);
                              },
                      ))
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isLoading || _selectedModel == widget.currentModel
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await widget.menuAiService.setModel(_selectedModel);
                            widget.onModelSelected();
                            if (context.mounted) Navigator.pop(context);
                          },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

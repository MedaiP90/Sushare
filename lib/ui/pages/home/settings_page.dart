import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/profile_viewmodel.dart';
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

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
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

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
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
    final userAsync = ref.watch(profileViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Profile'),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return const ListTile(
                  title: Text('No profile'),
                  subtitle: Text('Create a profile to get started'),
                );
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(user.avatarColorValue),
                  backgroundImage: user.profilePicturePath != null
                      ? FileImage(File(user.profilePicturePath!))
                      : null,
                  child: user.profilePicturePath == null
                      ? Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text('@${user.username}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditProfileSheet(context, ref),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),
          const Divider(),
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeText(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSheet(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_getLocaleText(locale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSheet(context, ref),
          ),
          const Divider(),
          const _SectionHeader(title: 'AI Service'),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('Google Gemini API Key'),
            subtitle: const Text('For menu scanning'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showApiKeySheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('AI Model'),
            subtitle: ref.watch(_selectedModelProvider).when(
              data: (model) => Text(model ?? 'gemini-2.0-flash'),
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('gemini-2.0-flash'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showModelSheet(context, ref),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getLocaleText(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italian';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: 'Theme',
        children: ThemeMode.values.map((mode) {
          final label = switch (mode) {
            ThemeMode.system => 'System default',
            ThemeMode.light => 'Light',
            ThemeMode.dark => 'Dark',
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

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    const options = [
      ('en', 'English'),
      ('it', 'Italian'),
      ('es', 'Spanish'),
      ('fr', 'French'),
      ('de', 'German'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => _PickerSheet(
        title: 'Language',
        children: options.map(((String code, String label) opt) {
          return _LanguageOption(
            locale: Locale(opt.$1),
            label: opt.$2,
            currentLocale: currentLocale,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(Locale(opt.$1));
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

  void _showApiKeySheet(BuildContext context) {
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

  void _showModelSheet(BuildContext context, WidgetRef ref) async {
    final menuAiService = MenuAiService();
    final hasKey = await menuAiService.hasApiKey();

    if (!hasKey) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set your API key first')),
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
  final Locale locale;
  final String label;
  final Locale currentLocale;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale.languageCode == currentLocale.languageCode;

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
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _profilePicturePath = widget.user.profilePicturePath;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _profilePicturePath = saved.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

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
            Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(widget.user.avatarColorValue),
                      backgroundImage: _profilePicturePath != null
                          ? FileImage(File(_profilePicturePath!))
                          : null,
                      child: _profilePicturePath == null
                          ? Text(
                              _firstNameController.text.isNotEmpty
                                  ? _firstNameController.text[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 36, color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.edit, size: 16,
                            color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
                            profilePicturePath: _profilePicturePath,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated!')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
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
            Text('Google Gemini API Key',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter your Google Gemini API key for menu scanning functionality.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
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
                  child: const Text('Clear'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    if (controller.text.trim().isNotEmpty) {
                      await menuAiService.setApiKey(controller.text.trim());
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
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
                  Text('AI Model',
                      style: Theme.of(context).textTheme.titleLarge),
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
                  'Could not fetch models from API. Using default.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
              ),
            const SizedBox(height: 8),
            ListView(
              shrinkWrap: true,
              children: models.map((model) => RadioListTile<String>(
                  title: Text(model, overflow: TextOverflow.ellipsis),
                  value: model,
                  groupValue: _selectedModel,
                  onChanged: widget.availableModels.isEmpty
                      ? null
                      : (value) {
                          setState(() => _selectedModel = value!);
                        },
              )).toList(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isLoading ||
                            _selectedModel == widget.currentModel
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await widget.menuAiService.setModel(_selectedModel);
                            widget.onModelSelected();
                            if (context.mounted) Navigator.pop(context);
                          },
                    child: const Text('Save'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/avatar_widget.dart';
import '../home/settings_page.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late AvatarData _avatarData;
  Locale? _selectedLocale;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _avatarData = AvatarData.defaultAvatar;
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

  void _onUsernameChanged(String value) {
    if (value.isNotEmpty && _usernameController.text == value) {
      setState(() {
        _avatarData = AvatarData.generateFromUsername(value);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileViewModelProvider.notifier).createProfile(
            username: _usernameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            avatarIconCodePoint: _avatarData.iconCodePoint,
            avatarColorValue: _avatarData.colorValue,
          );
      await ref.read(localeProvider.notifier).setLocale(_selectedLocale);
      if (mounted) {
        context.go('/home/sessions');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingProfile(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  l10n.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileSetupSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Center(
                  child: GestureDetector(
                    onTap: () => _showAvatarPicker(context),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(_avatarData.colorValue),
                      ),
                      child: Icon(
                        IconData(_avatarData.iconCodePoint, fontFamily: 'MaterialIcons'),
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tapToChooseAvatar,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    labelText: l10n.labelUsername,
                    hintText: l10n.hintUsername,
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationUsernameRequired;
                    }
                    if (value.trim().length < 3) {
                      return l10n.validationUsernameMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: l10n.labelFirstName,
                    hintText: l10n.hintFirstName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationFirstNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: l10n.labelLastName,
                    hintText: l10n.hintLastName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationLastNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Locale?>(
                  value: _selectedLocale,
                  decoration: InputDecoration(
                    labelText: l10n.settingsLanguage,
                    prefixIcon: const Icon(Icons.language),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.settingsThemeSystem),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(l10n.settingsLangEnglish),
                    ),
                    DropdownMenuItem(
                      value: const Locale('it'),
                      child: Text(l10n.settingsLangItalian),
                    ),
                    DropdownMenuItem(
                      value: const Locale('es'),
                      child: Text(l10n.settingsLangSpanish),
                    ),
                    DropdownMenuItem(
                      value: const Locale('fr'),
                      child: Text(l10n.settingsLangFrench),
                    ),
                    DropdownMenuItem(
                      value: const Locale('de'),
                      child: Text(l10n.settingsLangGerman),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedLocale = value),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(l10n.getStarted),
                  ),
                ),
              ],
            ),
          ),
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

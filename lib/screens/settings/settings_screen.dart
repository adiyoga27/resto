import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProv = context.watch<LanguageProvider>();
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Tampilan',
            children: [
              SwitchListTile(
                title: Text(l10n.darkMode),
                subtitle: Text(themeProv.isDarkMode ? 'Aktif' : 'Nonaktif'),
                value: themeProv.isDarkMode,
                onChanged: (_) => themeProv.toggleTheme(),
                secondary: Icon(
                  themeProv.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: l10n.language,
            children: [
              ListTile(
                leading: Radio<String>(
                  value: 'id',
                  groupValue: langProv.locale.languageCode,
                  onChanged: (v) => langProv.setLocale(const Locale('id')),
                ),
                title: const Text('Bahasa Indonesia'),
                subtitle: const Text('Indonesia'),
                onTap: () => langProv.setLocale(const Locale('id')),
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'en',
                  groupValue: langProv.locale.languageCode,
                  onChanged: (v) => langProv.setLocale(const Locale('en')),
                ),
                title: const Text('English'),
                subtitle: const Text('English'),
                onTap: () => langProv.setLocale(const Locale('en')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsSection(
            title: l10n.about,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Resto POS'),
                subtitle: const Text('Versi 1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Dibuat dengan Flutter'),
                subtitle: const Text('Cross-platform POS Solution'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                )),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

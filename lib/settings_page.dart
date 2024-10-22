import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';
import 'main_layout.dart';
import 'translation_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotificationsEnabled = true;
  final TranslationService _translationService = TranslationService();
  String _translatedText = 'Settings';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load other settings if necessary
  }

  Future<void> _translate(String text, String language) async {
    try {
      String translated = await _translationService.translate(text, language);
      setState(() {
        _translatedText = translated;
      });
    } catch (e) {
      print('Translation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLanguage = context.watch<LanguageNotifier>().currentLanguage;

    return MainLayout(
      headerText: _translatedText,
      selectedIndex: 2,
      profileImage: '',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('General Settings'),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.green),
            title: const Text('Push Notifications'),
            trailing: Switch(
              value: _pushNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _pushNotificationsEnabled = value;
                });
                // Save preference here
              },
              activeColor: Colors.green,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.green),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: context.watch<ThemeNotifier>().isDarkMode,
              onChanged: (value) {
                context.read<ThemeNotifier>().toggleTheme(value);
              },
              activeColor: Colors.green,
            ),
          ),
          const Divider(),
          _buildSectionTitle('Language & Region'),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: currentLanguage,
              items: ['en', 'es', 'fr', 'de'].map((String language) {
                return DropdownMenuItem(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  context.read<LanguageNotifier>().changeLanguage(value);
                  _translate('Settings', value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}

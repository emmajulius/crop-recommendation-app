import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/theme_notifier.dart';
import '../providers/language_provider.dart';
import '../utils/translator.dart';
import 'manage_account.dart'; // Make sure this file exists!

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  // Supported languages
  final Map<String, String> supportedLanguages = {
    'en': 'English',
    'sw': 'Swahili',
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    // Load from local storage or Firebase if applicable
    setState(() {
      _notificationsEnabled = true;
    });
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          translate(context, 'settings'),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),

        // Dark Mode toggle
        SwitchListTile(
          title: Text(translate(context, 'dark_mode')),
          value: themeNotifier.isDarkMode,
          activeColor: Colors.green.shade700,
          onChanged: themeNotifier.toggleTheme,
        ),
        const Divider(),

        // Notifications toggle
        SwitchListTile(
          title: Text(translate(context, 'enable_notifications')),
          value: _notificationsEnabled,
          activeColor: Colors.green.shade700,
          onChanged: _toggleNotifications,
        ),
        const Divider(),

        // Language dropdown
        ListTile(
          title: Text(translate(context, 'app_language')),
          trailing: DropdownButton<String>(
            value: languageProvider.selectedLanguage,
            icon: const Icon(Icons.language),
            underline: const SizedBox(),
            items: supportedLanguages.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                languageProvider.setLanguage(newValue);
              }
            },
          ),
        ),
        const Divider(),

        // Manage account
        ListTile(
          title: Text(translate(context, 'manage_account')),
          trailing: const Icon(Icons.person),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageAccountScreen()),
            );
          },
        ),
        const Divider(),

        // App version
        ListTile(
          title: Text(translate(context, 'app_version')),
          trailing: const Text('v1.0.0'),
        ),
      ],
    );
  }
}

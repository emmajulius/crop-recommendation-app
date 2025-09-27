import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationProvider() {
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (_notificationsEnabled) {
      await NotificationService.subscribeToTopic('all');
    } else {
      await NotificationService.unsubscribeFromTopic('all');
    }

    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = enabled;
    await prefs.setBool('notifications_enabled', enabled);

    if (enabled) {
      await NotificationService.subscribeToTopic('all');
    } else {
      await NotificationService.unsubscribeFromTopic('all');
    }

    notifyListeners();
  }
}

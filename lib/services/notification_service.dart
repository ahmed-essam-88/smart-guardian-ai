import 'package:flutter/services.dart';

/// High-priority local notifications, implemented natively in the Android
/// MainActivity (channel `smart_guardian/notifications`) so the app has no
/// third-party notification dependency.
class NotificationService {
  static const _channel = MethodChannel('smart_guardian/notifications');

  static const int flameAlertId = 1001;
  static const int riskAlertId = 1002;

  Future<void> ensureChannel() async {
    try {
      await _channel.invokeMethod('ensureChannel');
    } on PlatformException {
      // Notifications unsupported; the in-app alert log still records events.
    }
  }

  Future<bool> show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      return await _channel.invokeMethod<bool>(
            'show',
            {'id': id, 'title': title, 'body': body},
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_guardian_ai/data/settings_store.dart';

void main() {
  test('resetAll restores defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.load();
    await s.setEmergencyNumber('123');
    await s.setDemoMode(true);
    await s.setNotificationsEnabled(false);
    expect(s.emergencyNumber, '123');
    await s.resetAll();
    expect(s.emergencyNumber, '180');
    expect(s.demoMode, false);
    expect(s.notificationsEnabled, true);
    expect(s.thresholds.tempMax, 50);
  });
}

import 'package:shared_preferences/shared_preferences.dart';

import '../services/risk_engine.dart';

/// App preferences persisted with shared_preferences.
class SettingsStore {
  static const _kTemp = 'threshold_temp';
  static const _kSmoke = 'threshold_smoke';
  static const _kGas = 'threshold_gas';
  static const _kNotifications = 'notifications_enabled';
  static const _kAutoReconnect = 'auto_reconnect';
  static const _kDemoMode = 'demo_mode';
  static const _kDemoInterval = 'demo_interval_sec';
  static const _kUserName = 'user_name';
  static const _kEmergencyNumber = 'emergency_number';
  static const _kSosMessage = 'sos_message';
  static const _kShareLocation = 'share_location';
  static const _kLanguage = 'language';

  final SharedPreferences _prefs;
  SettingsStore(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore(await SharedPreferences.getInstance());

  RiskThresholds get thresholds => RiskThresholds(
        tempMax: _prefs.getDouble(_kTemp) ?? 50,
        smokeMax: _prefs.getDouble(_kSmoke) ?? 100,
        gasMax: _prefs.getDouble(_kGas) ?? 100,
      );

  Future<void> setThresholds(RiskThresholds t) async {
    await _prefs.setDouble(_kTemp, t.tempMax);
    await _prefs.setDouble(_kSmoke, t.smokeMax);
    await _prefs.setDouble(_kGas, t.gasMax);
  }

  /// Removes every saved preference so all getters return their defaults.
  Future<void> resetAll() => _prefs.clear();

  bool get notificationsEnabled => _prefs.getBool(_kNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool(_kNotifications, v);

  bool get autoReconnect => _prefs.getBool(_kAutoReconnect) ?? true;
  Future<void> setAutoReconnect(bool v) => _prefs.setBool(_kAutoReconnect, v);

  bool get demoMode => _prefs.getBool(_kDemoMode) ?? false;
  Future<void> setDemoMode(bool v) => _prefs.setBool(_kDemoMode, v);

  int get demoIntervalSec => _prefs.getInt(_kDemoInterval) ?? 2;
  Future<void> setDemoIntervalSec(int v) => _prefs.setInt(_kDemoInterval, v);

  String get userName => _prefs.getString(_kUserName) ?? '';
  Future<void> setUserName(String v) => _prefs.setString(_kUserName, v);

  /// Egypt fire brigade by default; user-configurable.
  String get emergencyNumber => _prefs.getString(_kEmergencyNumber) ?? '180';
  Future<void> setEmergencyNumber(String v) =>
      _prefs.setString(_kEmergencyNumber, v);

  String get sosMessage =>
      _prefs.getString(_kSosMessage) ??
      'EMERGENCY: Possible fire detected at my location. Please help.';
  /// Saved custom SOS text, or the default in the given language.
  String sosMessageFor(String lang) =>
      _prefs.getString(_kSosMessage) ??
      (lang == 'ar'
          ? 'استغاثة: يوجد احتمال حريق في مكاني. أرجو المساعدة.'
          : 'EMERGENCY: Possible fire detected at my location. Please help.');

  Future<void> setSosMessage(String v) => _prefs.setString(_kSosMessage, v);

  /// The SOS screen offers to attach a Google Maps link with the device
  /// location. The runtime permission is always requested first.
  bool get shareLocation => _prefs.getBool(_kShareLocation) ?? true;
  Future<void> setShareLocation(bool v) => _prefs.setBool(_kShareLocation, v);

  /// 'ar', 'en', or null = not chosen yet (English).
  String? get language => _prefs.getString(_kLanguage);
  Future<void> setLanguage(String v) => _prefs.setString(_kLanguage, v);
}

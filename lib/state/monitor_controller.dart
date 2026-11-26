import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../data/settings_store.dart';
import '../services/auth_service.dart';
import '../services/bluetooth_service.dart';
import '../services/demo_mode.dart';
import '../services/notification_service.dart';
import '../services/risk_engine.dart';

/// Central state: ties sensor input (real Bluetooth or Demo Mode) to the
/// rule-based risk engine, persistence, alerts and notifications.
class MonitorController extends ChangeNotifier {
  final SettingsStore settings;
  final AppDatabase _db = AppDatabase.instance;
  final BluetoothService _bt = BluetoothService();
  final NotificationService _notifications = NotificationService();
  final RiskEngine _engine = const RiskEngine();
  final DemoDataGenerator _demo = DemoDataGenerator();

  final AuthApi auth;

  MonitorController(this.settings, this.auth);

  /// Sign out and return to the login screen.
  Future<void> signOut() async {
    await auth.signOut();
    notifyListeners();
  }

  // ---- Live state ----
  SensorReading? currentReading;
  RiskAssessment? currentAssessment;
  BtConnectionState connectionState = BtConnectionState.disconnected;
  String? connectedDeviceName;
  DateTime? lastRealUpdate;
  bool demoActive = false;
  DemoScenario demoScenario = DemoScenario.normal;
  String? lastInvalidDataNotice;

  StreamSubscription? _btSub;
  Timer? _demoTimer;
  Timer? _reconnectTimer;
  String? _pendingReconnectAddress;

  /// Duplicate-alert prevention: remember what we last alerted on and when.
  String? _lastAlertedLevel;
  DateTime? _lastAlertAt;
  static const _alertCooldown = Duration(seconds: 60);

  /// App language: the saved choice, English by default.
  String get languageCode => settings.language ?? 'en';

  Future<void> setLanguage(String code) async {
    await settings.setLanguage(code);
    notifyListeners();
  }

  RiskThresholds get thresholds => settings.thresholds;

  /// Lets settings screens trigger a UI refresh after preference changes.
  void notify() => notifyListeners();

  bool get isShowingDemo =>
      demoActive && currentReading?.source == ReadingSource.demo;

  Future<void> init() async {
    await _notifications.ensureChannel();
    if (settings.demoMode) {
      await setDemoMode(true, persist: false);
    }
  }

  // ---------------- Demo Mode ----------------

  Future<void> setDemoMode(bool enabled, {bool persist = true}) async {
    if (persist) await settings.setDemoMode(enabled);
    demoActive = enabled;
    _demoTimer?.cancel();
    if (enabled) {
      _demoTimer = Timer.periodic(
        Duration(seconds: settings.demoIntervalSec.clamp(1, 60)),
        (_) => _ingest(_demo.next(demoScenario)),
      );
      _ingest(_demo.next(demoScenario));
    } else if (currentReading?.source == ReadingSource.demo) {
      currentReading = null;
      currentAssessment = null;
    }
    notifyListeners();
  }

  void setDemoScenario(DemoScenario scenario) {
    demoScenario = scenario;
    notifyListeners();
  }

  // ---------------- Bluetooth ----------------

  Future<bool> connectTo(String address, {String? name}) async {
    connectionState = BtConnectionState.connecting;
    notifyListeners();
    _listenBt();
    final ok = await _bt.connect(address);
    connectionState =
        ok ? BtConnectionState.connected : BtConnectionState.disconnected;
    connectedDeviceName = ok ? (name ?? address) : null;
    _pendingReconnectAddress = ok ? address : null;
    if (!ok) {
      await _logAlert(
          'CONNECTION', 'WARNING', 'Failed to connect to ${name ?? address}.');
    }
    notifyListeners();
    return ok;
  }

  Future<void> disconnect() async {
    _pendingReconnectAddress = null;
    _reconnectTimer?.cancel();
    await _bt.disconnect();
    connectionState = BtConnectionState.disconnected;
    connectedDeviceName = null;
    notifyListeners();
  }

  void _listenBt() {
    _btSub ??= _bt.events().listen((event) async {
      switch (event['event']) {
        case 'line':
          final reading = BluetoothService.parseSensorLine(
              (event['data'] ?? '').toString());
          if (reading == null) {
            lastInvalidDataNotice =
                'Ignored invalid sensor data: ${event['data']}';
          } else {
            lastRealUpdate = DateTime.now();
            lastInvalidDataNotice = null;
            await _ingest(reading);
          }
          notifyListeners();
          break;
        case 'state':
          if (event['data'] == 'disconnected') {
            connectionState = BtConnectionState.disconnected;
            connectedDeviceName = null;
            _maybeReconnect();
          } else if (event['data'] == 'connected') {
            connectionState = BtConnectionState.connected;
          }
          notifyListeners();
          break;
        case 'error':
          lastInvalidDataNotice = 'Bluetooth error: ${event['data']}';
          notifyListeners();
          break;
      }
    });
  }

  void _maybeReconnect() {
    final address = _pendingReconnectAddress;
    if (!settings.autoReconnect || address == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 8), () async {
      if (connectionState == BtConnectionState.disconnected) {
        await connectTo(address);
      }
    });
  }

  // ---------------- Ingestion, risk, alerts ----------------

  Future<void> _ingest(SensorReading reading) async {
    final assessment = _engine.assess(reading, thresholds);
    final stored = reading.copyWith(
      riskScore: assessment.score,
      riskLevel: assessment.level,
    );
    currentReading = stored;
    currentAssessment = assessment;
    await _db.insertReading(stored);
    await _handleAlerts(assessment);
    notifyListeners();
  }

  Future<void> _handleAlerts(RiskAssessment a) async {
    // Flame: immediate high-priority warning, independent of score.
    if (a.flameAlert) {
      await _raiseAlert(
        type: 'FLAME',
        severity: 'CRITICAL',
        message: 'Flame detected by sensor. Immediate attention required.',
        notifyTitle: 'FLAME DETECTED',
        notifyBody: 'Flame sensor triggered. Check the area now.',
        notificationId: NotificationService.flameAlertId,
        bypassCooldown: true,
      );
    }

    // Risk-level transition detection with duplicate prevention.
    if (a.level != _lastAlertedLevel &&
        a.level != RiskEngine.safe &&
        _cooldownElapsed()) {
      final severity = a.level == RiskEngine.critical
          ? 'CRITICAL'
          : (a.level == RiskEngine.high ? 'HIGH' : 'WARNING');
      await _raiseAlert(
        type: 'RISK_LEVEL',
        severity: severity,
        message:
            'Risk level changed to ${a.level} (${a.score.toStringAsFixed(0)}%). ${a.explanation}',
        notifyTitle: 'Risk level: ${a.level}',
        notifyBody: a.explanation,
        notificationId: NotificationService.riskAlertId,
      );
      _lastAlertedLevel = a.level;
    } else if (a.level == RiskEngine.safe) {
      _lastAlertedLevel = RiskEngine.safe;
    }
  }

  bool _cooldownElapsed() =>
      _lastAlertAt == null ||
      DateTime.now().difference(_lastAlertAt!) > _alertCooldown;

  Future<void> _raiseAlert({
    required String type,
    required String severity,
    required String message,
    required String notifyTitle,
    required String notifyBody,
    required int notificationId,
    bool bypassCooldown = false,
  }) async {
    if (!bypassCooldown && !_cooldownElapsed()) return;
    _lastAlertAt = DateTime.now();
    await _logAlert(type, severity, message);
    if (settings.notificationsEnabled) {
      await _notifications.show(
          id: notificationId, title: notifyTitle, body: notifyBody);
    }
  }

  Future<void> _logAlert(String type, String severity, String message) async {
    await _db.insertAlert(AlertRecord(
      type: type,
      severity: severity,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> updateThresholds(RiskThresholds t) async {
    await settings.setThresholds(t);
    // Re-assess the current reading against the new thresholds immediately.
    final r = currentReading;
    if (r != null) {
      currentAssessment = _engine.assess(r, t);
    }
    notifyListeners();
  }

  /// Bumped on every factory reset so screens holding local state rebuild.
  int resetCount = 0;

  /// Factory reset: stops demo/Bluetooth, restores every setting to its
  /// default and deletes stored readings and alerts.
  Future<void> resetToDefaults() async {
    await setDemoMode(false, persist: false);
    await disconnect();
    await settings.resetAll();
    await _db.clearReadings();
    await _db.clearAlerts();
    currentReading = null;
    currentAssessment = null;
    lastRealUpdate = null;
    lastInvalidDataNotice = null;
    demoScenario = DemoScenario.normal;
    _lastAlertedLevel = null;
    _lastAlertAt = null;
    resetCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _reconnectTimer?.cancel();
    _btSub?.cancel();
    super.dispose();
  }
}

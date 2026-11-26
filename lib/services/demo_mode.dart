import 'dart:math';

import '../data/models.dart';

/// Demo scenarios used by Demo Mode. The user picks what to simulate so all
/// four risk levels can be exercised without hardware. The emergency
/// simulation is a test scenario only; it never contacts real emergency
/// services.
enum DemoScenario {
  normal,
  elevatedTemp,
  smokeWarning,
  gasWarning,
  highRisk,
  emergency,
}

/// Display labels keyed by scenario (English; Arabic via l10n lookup).
const Map<DemoScenario, String> demoScenarioLabels = {
  DemoScenario.normal: 'Normal conditions',
  DemoScenario.elevatedTemp: 'Elevated temperature',
  DemoScenario.smokeWarning: 'Smoke warning',
  DemoScenario.gasWarning: 'Gas warning',
  DemoScenario.highRisk: 'High risk conditions',
  DemoScenario.emergency: 'Emergency simulation',
};

/// Generates realistic sample readings for Demo Mode.
///
/// Every generated reading is tagged [ReadingSource.demo]; simulated data is
/// never presented as real hardware data, and the UI shows a DEMO indicator
/// whenever Demo Mode produces the values on screen.
class DemoDataGenerator {
  final Random _random = Random();

  double _jitter(double base, double range) =>
      base + (_random.nextDouble() * 2 - 1) * range;

  SensorReading next(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.normal:
        return _reading(
          temperature: _jitter(27, 2.5),
          humidity: _jitter(48, 6).clamp(0, 100),
          smoke: _jitter(18, 8).clamp(0, double.infinity),
          gas: _jitter(15, 7).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(220, 4),
        );
      case DemoScenario.elevatedTemp:
        // Only temperature crosses its threshold -> MEDIUM.
        return _reading(
          temperature: _jitter(58, 3),
          humidity: _jitter(36, 5).clamp(0, 100),
          smoke: _jitter(30, 10).clamp(0, double.infinity),
          gas: _jitter(22, 8).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(219, 5),
        );
      case DemoScenario.smokeWarning:
        // Only smoke crosses its threshold -> MEDIUM.
        return _reading(
          temperature: _jitter(30, 3),
          humidity: _jitter(44, 6).clamp(0, 100),
          smoke: _jitter(135, 15).clamp(0, double.infinity),
          gas: _jitter(24, 8).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(220, 4),
        );
      case DemoScenario.gasWarning:
        // Only gas crosses its threshold -> MEDIUM.
        return _reading(
          temperature: _jitter(30, 3),
          humidity: _jitter(45, 6).clamp(0, 100),
          smoke: _jitter(26, 10).clamp(0, double.infinity),
          gas: _jitter(135, 15).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(220, 4),
        );
      case DemoScenario.highRisk:
        // Temperature and smoke both high -> HIGH.
        return _reading(
          temperature: _jitter(62, 4),
          humidity: _jitter(28, 5).clamp(0, 100),
          smoke: _jitter(122, 12).clamp(0, double.infinity),
          gas: _jitter(45, 12).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(218, 6),
        );
      case DemoScenario.emergency:
        // Full emergency simulation (test only): CRITICAL + flame alerts.
        return _reading(
          temperature: _jitter(74, 8),
          humidity: _jitter(20, 5).clamp(0, 100),
          smoke: _jitter(160, 25).clamp(0, double.infinity),
          gas: _jitter(145, 25).clamp(0, double.infinity),
          flame: _random.nextDouble() > 0.25,
          electricity: _jitter(216, 7),
        );
    }
  }

  SensorReading _reading({
    required double temperature,
    required double humidity,
    required double smoke,
    required double gas,
    required bool flame,
    required double electricity,
  }) =>
      SensorReading(
        timestamp: DateTime.now(),
        temperature: temperature,
        humidity: humidity,
        smoke: smoke,
        gas: gas,
        flameDetected: flame,
        electricity: electricity,
        source: ReadingSource.demo,
      );
}

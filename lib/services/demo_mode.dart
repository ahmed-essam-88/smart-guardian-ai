import 'dart:math';

import '../data/models.dart';

/// Demo scenarios used by Demo Mode. The user picks what to simulate so all
/// four risk levels can be exercised without hardware.
enum DemoScenario { normal, elevated, fire }

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
      case DemoScenario.elevated:
        return _reading(
          temperature: _jitter(56, 4),
          humidity: _jitter(33, 5).clamp(0, 100),
          smoke: _jitter(88, 20).clamp(0, double.infinity),
          gas: _jitter(70, 18).clamp(0, double.infinity),
          flame: false,
          electricity: _jitter(219, 5),
        );
      case DemoScenario.fire:
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

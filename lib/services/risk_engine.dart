import '../data/models.dart';

/// Configurable thresholds for the rule-based risk engine.
///
/// IMPORTANT: these are initial demonstration parameters, not certified
/// fire-safety thresholds. Real deployments require sensor calibration and
/// validation. The risk score is NOT a scientifically validated probability
/// of fire.
class RiskThresholds {
  final double tempMax; // °C
  final double smokeMax; // raw sensor value
  final double gasMax; // raw sensor value

  const RiskThresholds({
    this.tempMax = 50,
    this.smokeMax = 100,
    this.gasMax = 100,
  });

  RiskThresholds copyWith({double? tempMax, double? smokeMax, double? gasMax}) =>
      RiskThresholds(
        tempMax: tempMax ?? this.tempMax,
        smokeMax: smokeMax ?? this.smokeMax,
        gasMax: gasMax ?? this.gasMax,
      );
}

/// Rule-based fire risk assessment engine (initial version).
///
/// Scoring rules (demonstration parameters, clamped to 0..100):
///   temperature above threshold: +25
///   smoke above threshold:       +25
///   gas above threshold:         +25
///   flame detected:              +25
///
/// Levels: 0-24 SAFE, 25-49 MEDIUM, 50-74 HIGH, 75-100 CRITICAL.
///
/// This engine is deliberately separate from any future machine-learning
/// engine (see `FutureAiEngine`). The app never claims trained-AI behavior.
class RiskEngine {
  const RiskEngine();

  static const String safe = 'SAFE';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static String levelFor(double score) {
    if (score >= 75) return critical;
    if (score >= 50) return high;
    if (score >= 25) return medium;
    return safe;
  }

  RiskAssessment assess(SensorReading r, RiskThresholds t) {
    var score = 0;
    final factors = <String>[];

    final temp = r.temperature;
    if (temp != null && temp > t.tempMax) {
      score += 25;
      factors.add(
          'Temperature ${temp.toStringAsFixed(1)}°C above ${t.tempMax.toStringAsFixed(0)}°C threshold');
    }
    final smoke = r.smoke;
    if (smoke != null && smoke > t.smokeMax) {
      score += 25;
      factors.add(
          'Smoke reading ${smoke.toStringAsFixed(0)} above ${t.smokeMax.toStringAsFixed(0)} threshold');
    }
    final gas = r.gas;
    if (gas != null && gas > t.gasMax) {
      score += 25;
      factors.add(
          'Gas reading ${gas.toStringAsFixed(0)} above ${t.gasMax.toStringAsFixed(0)} threshold');
    }
    if (r.flameDetected) {
      score += 25;
      factors.add('Flame detected by sensor');
    }

    final clamped = score.clamp(0, 100).toDouble();
    final level = levelFor(clamped);

    final String explanation;
    if (factors.isEmpty) {
      explanation = 'All monitored values are within configured thresholds.';
    } else {
      explanation = factors.join('. ');
    }

    return RiskAssessment(
      score: clamped,
      level: level,
      explanation: explanation,
      factors: factors,
      timestamp: DateTime.now(),
      flameAlert: r.flameDetected,
    );
  }
}

/// Placeholder boundary for a future machine-learning engine.
///
/// The future engine will analyze historical readings for abnormal pattern
/// detection, time-series analysis and ML-based risk classification. It is
/// intentionally not implemented yet; nothing in the app displays fake AI
/// predictions or unvalidated accuracy claims.
abstract class FutureAiEngine {
  // Future: load a validated on-device model, evaluate it on historical
  // data, and report measured performance before enabling predictions.
}

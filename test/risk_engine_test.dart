import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guardian_ai/data/models.dart';
import 'package:smart_guardian_ai/services/risk_engine.dart';

SensorReading r({double t = 25, double s = 10, double g = 10, bool f = false}) =>
    SensorReading(
        timestamp: DateTime(2026),
        temperature: t,
        humidity: 40,
        smoke: s,
        gas: g,
        flameDetected: f,
        source: ReadingSource.real);

void main() {
  const engine = RiskEngine();
  const th = RiskThresholds();

  test('no triggers is SAFE 0', () {
    final a = engine.assess(r(), th);
    expect(a.score, 0);
    expect(a.level, 'SAFE');
  });
  test('one trigger is MEDIUM 25', () {
    final a = engine.assess(r(t: 60), th);
    expect(a.score, 25);
    expect(a.level, 'MEDIUM');
  });
  test('two triggers is HIGH 50', () {
    final a = engine.assess(r(t: 60, s: 150), th);
    expect(a.score, 50);
    expect(a.level, 'HIGH');
  });
  test('three triggers is CRITICAL 75', () {
    final a = engine.assess(r(t: 60, s: 150, g: 150), th);
    expect(a.score, 75);
    expect(a.level, 'CRITICAL');
  });
  test('all four is CRITICAL 100 and clamped', () {
    final a = engine.assess(r(t: 60, s: 150, g: 150, f: true), th);
    expect(a.score, 100);
    expect(a.level, 'CRITICAL');
  });
  test('flame alone flags flameAlert regardless of score', () {
    final a = engine.assess(r(f: true), th);
    expect(a.score, 25);
    expect(a.flameAlert, isTrue);
  });
  test('threshold boundary: exactly at threshold does not trigger', () {
    final a = engine.assess(r(t: 50, s: 100, g: 100), th);
    expect(a.score, 0);
  });
  test('custom thresholds apply', () {
    final a = engine.assess(r(t: 40), const RiskThresholds(tempMax: 35));
    expect(a.score, 25);
  });
  test('missing values add nothing', () {
    final a = engine.assess(
        SensorReading(timestamp: DateTime(2026), source: ReadingSource.real),
        th);
    expect(a.score, 0);
  });
  test('level boundaries', () {
    expect(RiskEngine.levelFor(24), 'SAFE');
    expect(RiskEngine.levelFor(25), 'MEDIUM');
    expect(RiskEngine.levelFor(49), 'MEDIUM');
    expect(RiskEngine.levelFor(50), 'HIGH');
    expect(RiskEngine.levelFor(74), 'HIGH');
    expect(RiskEngine.levelFor(75), 'CRITICAL');
  });
}

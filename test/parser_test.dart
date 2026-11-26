import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guardian_ai/data/models.dart';
import 'package:smart_guardian_ai/services/bluetooth_service.dart';
import 'package:smart_guardian_ai/services/demo_mode.dart';

void main() {
  test('valid 5-field line', () {
    final x = BluetoothService.parseCsvLine('32,45,12,0,0')!;
    expect(x.temperature, 32);
    expect(x.humidity, 45);
    expect(x.smoke, 12);
    expect(x.flameDetected, false);
    expect(x.gas, 0);
    expect(x.electricity, isNull);
    expect(x.source, ReadingSource.real);
  });
  test('valid 6-field line with electricity and flame', () {
    final x = BluetoothService.parseCsvLine(' 80.5,20,150,1,140,219.5 \r')!;
    expect(x.flameDetected, true);
    expect(x.electricity, 219.5);
  });
  test('rejects wrong field counts', () {
    expect(BluetoothService.parseCsvLine('1,2,3,4'), isNull);
    expect(BluetoothService.parseCsvLine('1,2,3,4,5,6,7'), isNull);
    expect(BluetoothService.parseCsvLine(''), isNull);
  });
  test('rejects non-numeric, NaN and infinity', () {
    expect(BluetoothService.parseCsvLine('a,45,12,0,0'), isNull);
    expect(BluetoothService.parseCsvLine('32,45,NaN,0,0'), isNull);
    expect(BluetoothService.parseCsvLine('32,45,inf,0,0'), isNull);
  });
  test('rejects out-of-range values', () {
    expect(BluetoothService.parseCsvLine('500,45,12,0,0'), isNull);
    expect(BluetoothService.parseCsvLine('32,150,12,0,0'), isNull);
    expect(BluetoothService.parseCsvLine('32,45,-5,0,0'), isNull);
  });
  test('demo readings are always tagged demo', () {
    final g = DemoDataGenerator();
    for (final s in DemoScenario.values) {
      for (var i = 0; i < 20; i++) {
        expect(g.next(s).source, ReadingSource.demo);
      }
    }
  });

  group('JSON payload parsing (ESP32 schema)', () {
    // UTC reference so the Z-suffixed payload timestamps line up on any
    // machine timezone.
    final now = DateTime.utc(2026, 11, 26, 12, 0, 0);

    test('valid full payload', () {
      final x = BluetoothService.parseSensorLine(
          '{"device_id":"SG-001","mode":"LIVE","temperature":32.0,'
          '"humidity":45.0,"smoke":12.0,"gas":0.0,"flame":0,'
          '"electricity":220.0,"timestamp":"2026-11-26T11:59:00Z"}',
          now: now)!;
      expect(x.deviceId, 'SG-001');
      expect(x.temperature, 32.0);
      expect(x.flameDetected, false);
      expect(x.electricity, 220.0);
      expect(x.source, ReadingSource.real);
      expect(x.timestamp, DateTime.parse('2026-11-26T11:59:00Z').toLocal());
    });

    test('missing sensor fields stay missing, never zero', () {
      final x = BluetoothService.parseSensorLine(
          '{"device_id":"SG-001","mode":"LIVE","temperature":31.5}',
          now: now)!;
      expect(x.temperature, 31.5);
      expect(x.humidity, isNull);
      expect(x.smoke, isNull);
      expect(x.gas, isNull);
      expect(x.electricity, isNull);
      expect(x.timestamp, now);
    });

    test('rejects missing device_id, bad mode, bad json', () {
      expect(BluetoothService.parseSensorLine('{"temperature":32}', now: now),
          isNull);
      expect(
          BluetoothService.parseSensorLine(
              '{"device_id":"SG-1","mode":"BOGUS"}',
              now: now),
          isNull);
      expect(BluetoothService.parseSensorLine('{not json', now: now), isNull);
      expect(BluetoothService.parseSensorLine('[1,2,3]', now: now), isNull);
    });

    test('rejects invalid timestamps', () {
      expect(
          BluetoothService.parseSensorLine(
              '{"device_id":"SG-1","timestamp":"not-a-date"}',
              now: now),
          isNull);
      // more than 10 minutes in the future
      expect(
          BluetoothService.parseSensorLine(
              '{"device_id":"SG-1","timestamp":"2026-11-26T10:30:00"}',
              now: DateTime(2026, 11, 26, 9, 0, 0)),
          isNull);
    });

    test('rejects out-of-range and non-numeric fields', () {
      expect(
          BluetoothService.parseSensorLine(
              '{"device_id":"SG-1","temperature":500}',
              now: now),
          isNull);
      expect(
          BluetoothService.parseSensorLine(
              '{"device_id":"SG-1","humidity":"abc"}',
              now: now),
          isNull);
      expect(
          BluetoothService.parseSensorLine('{"device_id":"SG-1","flame":3}',
              now: now),
          isNull);
    });

    test('DEMO mode payload is tagged as simulated', () {
      final x = BluetoothService.parseSensorLine(
          '{"device_id":"SG-001","mode":"DEMO","temperature":32.0}',
          now: now)!;
      expect(x.source, ReadingSource.demo);
    });

    test('auto-detection keeps CSV working', () {
      final x = BluetoothService.parseSensorLine('32,45,12,0,0')!;
      expect(x.temperature, 32);
      expect(x.source, ReadingSource.real);
    });
  });
}

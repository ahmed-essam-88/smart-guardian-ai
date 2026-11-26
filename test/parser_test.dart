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
}

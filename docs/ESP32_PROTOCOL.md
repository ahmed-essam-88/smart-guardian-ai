# ESP32 communication protocol

Transport: Bluetooth Classic, SPP (serial port profile, UUID 00001101-0000-1000-8000-00805F9B34FB).
Device name the app prefers: `FireGuard_ESP32`. Pair the board in Android Bluetooth settings first, then pick it in the app.

## Line format
One reading per line, ASCII, terminated by `\n` (`\r\n` also works).

    Temperature,Humidity,Smoke,Flame,Gas[,Electricity]

Example: `32,45,12,0,0` or `32,45,12,0,0,220.4`

| Field | Unit | Accepted range |
|---|---|---|
| Temperature | °C | -40 to 125 |
| Humidity | % | 0 to 100 |
| Smoke | raw sensor value | 0 to 100000 |
| Flame | 0 or 1 (>= 0.5 means detected) | any number |
| Gas | raw sensor value | 0 to 100000 |
| Electricity (optional) | volts | 0 to 1000 |

A line with the wrong number of fields, a non-numeric value, NaN/infinity, or an out-of-range value is dropped. The app shows "Ignored invalid sensor data" and never records it. Lines longer than 200 characters are discarded.

## Arduino sketch (ESP32)

    #include "BluetoothSerial.h"
    BluetoothSerial SerialBT;
    void setup() { SerialBT.begin("FireGuard_ESP32"); }
    void loop() {
      float t = 32, h = 45; int smoke = 12, flame = 0, gas = 0;  // replace with real sensor reads
      SerialBT.printf("%.1f,%.0f,%d,%d,%d\n", t, h, smoke, flame, gas);
      delay(1000);
    }

## Behaviour
- Disconnected: the dashboard shows "NO DATA" and "--". The app never invents hardware readings.
- Auto-reconnect (Settings) retries after 8 seconds when the link drops.

# ESP32 communication protocol

Transport: Bluetooth Classic, SPP (serial port profile, UUID 00001101-0000-1000-8000-00805F9B34FB).
Device name the app prefers: `FireGuard_ESP32`. Pair the board in Android Bluetooth settings first, then pick it in the app.

The app accepts two wire formats, auto-detected per line. JSON is preferred
(self-describing, carries the device id and timestamp); CSV is the legacy
compact format.

## JSON format (preferred)
One JSON object per line, terminated by `\n`.

    {"device_id":"SG-001","mode":"LIVE","temperature":32.0,"humidity":45.0,"smoke":12.0,"gas":0.0,"flame":0,"electricity":220.0,"timestamp":"2026-11-26T12:00:00Z"}

Validation rules (a payload that breaks any rule is dropped, never shown):
- `device_id` is required, non-empty string. It is stored with the reading.
- `mode` is optional; when present it must be `LIVE` or `DEMO`. `DEMO`
  payloads are stored as simulated data and can never appear as live data.
- `timestamp` is optional; when present it must be valid ISO-8601 and not
  more than 10 minutes in the future. Missing timestamps fall back to the
  arrival time.
- Sensor fields are optional: a missing field stays missing (the dashboard
  shows NO DATA). Missing data is never coerced to zero.
- A present field must be numeric and inside the plausibility ranges below;
  `flame` accepts 0/1 or true/false only.

## CSV format (legacy)
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

## Arduino sketch (ESP32, JSON)

    #include "BluetoothSerial.h"
    BluetoothSerial SerialBT;
    void setup() { SerialBT.begin("FireGuard_ESP32"); }
    void loop() {
      float t = 32, h = 45; int smoke = 12, flame = 0, gas = 0;  // replace with real sensor reads
      SerialBT.printf("{\"device_id\":\"SG-001\",\"mode\":\"LIVE\",\"temperature\":%.1f,"
                      "\"humidity\":%.0f,\"smoke\":%d,\"gas\":%d,\"flame\":%d}\n",
                      t, h, smoke, gas, flame);
      delay(1000);
    }

## Behaviour
- Disconnected: the dashboard shows "NO DATA" and "--". The app never invents hardware readings.
- Auto-reconnect (Settings) retries after 8 seconds when the link drops.

## Future transport: REST / MQTT
The ingestion boundary (`BluetoothService.parseSensorLine`) is transport-
agnostic: any future REST endpoint or MQTT subscription can feed the same
JSON schema through the same validation. No app redesign is needed to move
from Bluetooth to networked ESP32 fleets.

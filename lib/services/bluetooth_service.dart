import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/models.dart';

class BluetoothDeviceInfo {
  final String name;
  final String address;
  const BluetoothDeviceInfo({required this.name, required this.address});

  factory BluetoothDeviceInfo.fromMap(Map<dynamic, dynamic> m) =>
      BluetoothDeviceInfo(
        name: (m['name'] as String?) ?? 'Unknown device',
        address: (m['address'] as String?) ?? '',
      );
}

enum BtConnectionState { disconnected, connecting, connected }

/// Bluetooth Classic (SPP) client for ESP32 boards such as FireGuard_ESP32.
///
/// Platform work lives in the Android MainActivity (MethodChannel +
/// EventChannels). This class adds safe CSV parsing and validation on top.
///
/// Accepted wire formats (auto-detected per line):
///
/// CSV (legacy, compact):
///   Temperature,Humidity,Smoke,Flame,Gas[,Electricity]
///   Example: 32,45,12,0,0
///
/// JSON (preferred, self-describing):
///   {"device_id": "SG-001", "mode": "LIVE", "temperature": 32.0,
///    "humidity": 45.0, "smoke": 12.0, "gas": 0.0, "flame": 0,
///    "electricity": 220.0, "timestamp": "2026-11-26T12:00:00Z"}
///
/// JSON validation: device_id is required; mode must be LIVE or DEMO when
/// present; a present timestamp must be valid ISO-8601 and not in the
/// future; sensor fields that are missing stay missing (never coerced to
/// zero); present values must be numeric and inside plausibility ranges.
class BluetoothService {
  static const _method = MethodChannel('smart_guardian/bluetooth');
  static const _dataEvents = EventChannel('smart_guardian/bluetooth_data');
  static const _scanEvents = EventChannel('smart_guardian/bluetooth_scan');

  /// Preferred device name for the companion hardware.
  static const expectedDeviceName = 'FireGuard_ESP32';

  Stream<dynamic>? _dataStream;
  Stream<dynamic>? _scanStream;

  Future<bool> isBluetoothEnabled() async {
    try {
      return await _method.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BluetoothDeviceInfo>> getPairedDevices() async {
    try {
      final list = await _method.invokeMethod<List<dynamic>>('getPaired');
      return (list ?? [])
          .map((e) => BluetoothDeviceInfo.fromMap(e as Map))
          .where((d) => d.address.isNotEmpty)
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Streams discovered devices; completes when discovery finishes.
  Stream<BluetoothDeviceInfo> scan() {
    _scanStream ??= _scanEvents.receiveBroadcastStream();
    return _scanStream!
        .where((e) => e is Map && e['event'] == 'device')
        .map((e) => BluetoothDeviceInfo.fromMap(e as Map));
  }

  Future<void> stopScan() async {
    try {
      await _method.invokeMethod('stopDiscovery');
    } on PlatformException {
      // Already stopped.
    }
  }

  Future<bool> connect(String address) async {
    try {
      return await _method
              .invokeMethod<bool>('connect', {'address': address}) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _method.invokeMethod('disconnect');
    } on PlatformException {
      // Nothing to disconnect.
    }
  }

  Future<bool> isConnected() async {
    try {
      return await _method.invokeMethod<bool>('isConnected') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Raw stream of events from the platform side:
  ///   {event: 'line',  data: '32,45,12,0,0'}
  ///   {event: 'state', data: 'connected' | 'disconnected'}
  ///   {event: 'error', data: '...'}
  Stream<Map<dynamic, dynamic>> events() {
    _dataStream ??= _dataEvents.receiveBroadcastStream();
    return _dataStream!.where((e) => e is Map).cast<Map<dynamic, dynamic>>();
  }

  /// Parses one incoming line from the ESP32, auto-detecting JSON vs CSV.
  /// Returns null for invalid data. Invalid data is never shown as a real
  /// reading.
  static SensorReading? parseSensorLine(String line, {DateTime? now}) {
    final trimmed = line.trim();
    if (trimmed.startsWith('{')) {
      return parseJsonPayload(trimmed, now: now);
    }
    return parseCsvLine(trimmed);
  }

  /// Parses one JSON payload from the ESP32 into a validated
  /// [SensorReading]. See the class docs for the schema and rules.
  static SensorReading? parseJsonPayload(String payload, {DateTime? now}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final m = decoded.cast<String, Object?>();

    // Device identification is mandatory for JSON payloads.
    final deviceId = m['device_id'];
    if (deviceId is! String || deviceId.trim().isEmpty) return null;

    // Mode: LIVE readings are real hardware data; DEMO payloads stay tagged
    // as simulated so they never masquerade as live data.
    final mode = m['mode'];
    if (mode != null && mode is! String) return null;
    final modeUp = (mode as String?)?.toUpperCase();
    if (modeUp != null && modeUp != 'LIVE' && modeUp != 'DEMO') return null;

    double? numField(String key, double min, double max) {
      final v = m[key];
      if (v == null) return null; // missing stays missing, never zero
      final d = v is num ? v.toDouble() : double.tryParse('$v');
      if (d == null || d.isNaN || d.isInfinite) return null;
      if (d < min || d > max) return null;
      return d;
    }

    bool invalid = false;
    double? checked(String key, double min, double max) {
      final v = numField(key, min, max);
      if (v == null && m.containsKey(key) && m[key] != null) {
        invalid = true; // present but not a plausible number
      }
      return v;
    }

    final temperature = checked('temperature', -40, 125);
    final humidity = checked('humidity', 0, 100);
    final smoke = checked('smoke', 0, 100000);
    final gas = checked('gas', 0, 100000);
    final electricity = checked('electricity', 0, 1000);
    if (invalid) return null;

    final flameRaw = m['flame'];
    bool flame = false;
    if (flameRaw is bool) {
      flame = flameRaw;
    } else if (flameRaw is num) {
      if (flameRaw != 0 && flameRaw != 1) return null;
      flame = flameRaw == 1;
    } else if (flameRaw != null) {
      return null;
    }

    // Timestamp validation: optional, but when present it must be valid
    // ISO-8601 and not more than 10 minutes in the future. Missing
    // timestamps fall back to the arrival time.
    final reference = now ?? DateTime.now();
    var timestamp = reference;
    final tsRaw = m['timestamp'];
    if (tsRaw != null) {
      if (tsRaw is! String) return null;
      final parsed = DateTime.tryParse(tsRaw);
      if (parsed == null) return null;
      if (parsed.isAfter(reference.add(const Duration(minutes: 10)))) {
        return null;
      }
      timestamp = parsed.toLocal();
    }

    return SensorReading(
      timestamp: timestamp,
      temperature: temperature,
      humidity: humidity,
      smoke: smoke,
      flameDetected: flame,
      gas: gas,
      electricity: electricity,
      deviceId: deviceId.trim(),
      source: modeUp == 'DEMO' ? ReadingSource.demo : ReadingSource.real,
    );
  }

  /// Parses one CSV line from the ESP32 into a validated [SensorReading].
  /// Returns null for invalid data (wrong field count, non-numeric values,
  /// out-of-range values). Invalid data is never shown as a real reading.
  static SensorReading? parseCsvLine(String line) {
    final parts = line.trim().split(',');
    if (parts.length < 5 || parts.length > 6) return null;

    double? num(String s) {
      final v = double.tryParse(s.trim());
      if (v == null || v.isNaN || v.isInfinite) return null;
      return v;
    }

    final temp = num(parts[0]);
    final humidity = num(parts[1]);
    final smoke = num(parts[2]);
    final flameRaw = num(parts[3]);
    final gas = num(parts[4]);
    final electricity = parts.length == 6 ? num(parts[5]) : null;

    if (temp == null ||
        humidity == null ||
        smoke == null ||
        flameRaw == null ||
        gas == null) {
      return null;
    }
    // Plausibility ranges guard against corrupted serial data.
    if (temp < -40 || temp > 125) return null;
    if (humidity < 0 || humidity > 100) return null;
    if (smoke < 0 || smoke > 100000) return null;
    if (gas < 0 || gas > 100000) return null;
    if (electricity != null && (electricity < 0 || electricity > 1000)) {
      return null;
    }

    return SensorReading(
      timestamp: DateTime.now(),
      temperature: temp,
      humidity: humidity,
      smoke: smoke,
      flameDetected: flameRaw >= 0.5,
      gas: gas,
      electricity: electricity,
      source: ReadingSource.real,
    );
  }
}

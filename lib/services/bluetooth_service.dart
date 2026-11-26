import 'dart:async';

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
/// Expected CSV line format:
///   Temperature,Humidity,Smoke,Flame,Gas[,Electricity]
/// Example: 32,45,12,0,0
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
      return await _method.invokeMethod<bool>('connect', {'address': address}) ??
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

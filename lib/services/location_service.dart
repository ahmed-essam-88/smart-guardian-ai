import 'package:flutter/services.dart';

class DeviceLocation {
  final double lat;
  final double lon;
  final double accuracyMeters;
  final int ageSeconds;
  const DeviceLocation(this.lat, this.lon, this.accuracyMeters, this.ageSeconds);

  /// Free Google Maps link, no API key needed.
  String get mapsUrl =>
      'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
}

/// Reads the device location through Android's own LocationManager
/// (GPS/network). No Google services, maps key or paid API.
class LocationService {
  static const _channel = MethodChannel('smart_guardian/location');

  Future<DeviceLocation?> current() async {
    try {
      final m = await _channel.invokeMapMethod<String, dynamic>('getLocation');
      if (m == null) return null;
      return DeviceLocation(
        (m['lat'] as num).toDouble(),
        (m['lon'] as num).toDouble(),
        (m['accuracy'] as num).toDouble(),
        (m['ageSec'] as num).toInt(),
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

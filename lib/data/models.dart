/// Data models for SMART GUARDIAN AI.
library;

/// Where a reading came from. Simulated readings are never mixed with real
/// hardware readings: every record carries its source.
enum ReadingSource { real, demo }

ReadingSource sourceFromString(String? v) =>
    v == 'demo' ? ReadingSource.demo : ReadingSource.real;

class SensorReading {
  final int? id;
  final DateTime timestamp;
  final double? temperature; // °C
  final double? humidity; // %
  final double? smoke; // raw sensor value
  final bool flameDetected;
  final double? gas; // raw sensor value
  final double? electricity; // volts, optional
  final String? deviceId; // ESP32 device identifier, when known
  final ReadingSource source;

  /// Risk results computed at capture time and stored with the record.
  final double? riskScore;
  final String? riskLevel;

  const SensorReading({
    this.id,
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.smoke,
    this.flameDetected = false,
    this.gas,
    this.electricity,
    this.deviceId,
    required this.source,
    this.riskScore,
    this.riskLevel,
  });

  SensorReading copyWith({
    int? id,
    double? riskScore,
    String? riskLevel,
  }) =>
      SensorReading(
        id: id ?? this.id,
        timestamp: timestamp,
        temperature: temperature,
        humidity: humidity,
        smoke: smoke,
        flameDetected: flameDetected,
        gas: gas,
        electricity: electricity,
        deviceId: deviceId,
        source: source,
        riskScore: riskScore ?? this.riskScore,
        riskLevel: riskLevel ?? this.riskLevel,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'temperature': temperature,
        'humidity': humidity,
        'smoke': smoke,
        'flame': flameDetected ? 1 : 0,
        'gas': gas,
        'electricity': electricity,
        'device_id': deviceId,
        'source': source.name,
        'risk_score': riskScore,
        'risk_level': riskLevel,
      };

  factory SensorReading.fromMap(Map<String, Object?> m) => SensorReading(
        id: m['id'] as int?,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        temperature: (m['temperature'] as num?)?.toDouble(),
        humidity: (m['humidity'] as num?)?.toDouble(),
        smoke: (m['smoke'] as num?)?.toDouble(),
        flameDetected: (m['flame'] as num? ?? 0) == 1,
        gas: (m['gas'] as num?)?.toDouble(),
        electricity: (m['electricity'] as num?)?.toDouble(),
        deviceId: m['device_id'] as String?,
        source: sourceFromString(m['source'] as String?),
        riskScore: (m['risk_score'] as num?)?.toDouble(),
        riskLevel: m['risk_level'] as String?,
      );
}

class RiskAssessment {
  final double score; // 0..100
  final String level; // SAFE / MEDIUM / HIGH / CRITICAL
  final String explanation;
  final List<String> factors;
  final DateTime timestamp;

  /// A flame event raises an immediate high-priority warning regardless of
  /// the accumulated score.
  final bool flameAlert;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.explanation,
    required this.factors,
    required this.timestamp,
    this.flameAlert = false,
  });
}

class AlertRecord {
  final int? id;
  final String type; // RISK_LEVEL / FLAME / CONNECTION / SYSTEM
  final String severity; // INFO / WARNING / HIGH / CRITICAL
  final String message;
  final DateTime timestamp;
  final bool acknowledged;

  const AlertRecord({
    this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.acknowledged = false,
  });

  AlertRecord copyWith({int? id, bool? acknowledged}) => AlertRecord(
        id: id ?? this.id,
        type: type,
        severity: severity,
        message: message,
        timestamp: timestamp,
        acknowledged: acknowledged ?? this.acknowledged,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'severity': severity,
        'message': message,
        'ts': timestamp.millisecondsSinceEpoch,
        'acknowledged': acknowledged ? 1 : 0,
      };

  factory AlertRecord.fromMap(Map<String, Object?> m) => AlertRecord(
        id: m['id'] as int?,
        type: m['type'] as String,
        severity: m['severity'] as String,
        message: m['message'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        acknowledged: (m['acknowledged'] as num? ?? 0) == 1,
      );
}

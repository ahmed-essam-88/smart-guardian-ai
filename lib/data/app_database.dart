import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Local persistence (sqflite). Readings keep their computed risk score and
/// level so history queries stay simple. Schema is versioned to leave room
/// for future cloud synchronization.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'smart_guardian.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts INTEGER NOT NULL,
            temperature REAL,
            humidity REAL,
            smoke REAL,
            flame INTEGER NOT NULL DEFAULT 0,
            gas REAL,
            electricity REAL,
            device_id TEXT,
            source TEXT NOT NULL DEFAULT 'real',
            risk_score REAL,
            risk_level TEXT
          )
        ''');
        await d.execute('CREATE INDEX idx_readings_ts ON readings(ts)');
        await d.execute('''
          CREATE TABLE alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            severity TEXT NOT NULL,
            message TEXT NOT NULL,
            ts INTEGER NOT NULL,
            acknowledged INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await d.execute('CREATE INDEX idx_alerts_ts ON alerts(ts)');
      },
      onUpgrade: (d, oldV, newV) async {
        if (oldV < 2) {
          // v2: readings gain the originating ESP32 device id (nullable).
          await d.execute('ALTER TABLE readings ADD COLUMN device_id TEXT');
        }
      },
    );
  }

  // ---------------- Readings ----------------

  Future<int> insertReading(SensorReading r) async {
    final d = await db;
    return d.insert('readings', r.toMap());
  }

  Future<List<SensorReading>> getReadings({
    DateTime? since,
    DateTime? until,
    String? riskLevel,
    String? search,
    bool newestFirst = true,
    int? limit,
  }) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (since != null) {
      where.add('ts >= ?');
      args.add(since.millisecondsSinceEpoch);
    }
    if (until != null) {
      where.add('ts <= ?');
      args.add(until.millisecondsSinceEpoch);
    }
    if (riskLevel != null && riskLevel.isNotEmpty) {
      where.add('risk_level = ?');
      args.add(riskLevel);
    }
    if (search != null && search.trim().isNotEmpty) {
      // Search matches the risk level or source text.
      where.add('(risk_level LIKE ? OR source LIKE ?)');
      final q = '%${search.trim()}%';
      args.addAll([q, q]);
    }
    final rows = await d.query(
      'readings',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'ts ${newestFirst ? 'DESC' : 'ASC'}',
      limit: limit,
    );
    return rows.map(SensorReading.fromMap).toList();
  }

  Future<int> deleteReading(int id) async {
    final d = await db;
    return d.delete('readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearReadings() async {
    final d = await db;
    return d.delete('readings');
  }

  Future<Map<String, Object?>> stats({DateTime? since}) async {
    final d = await db;
    final where = since != null ? 'WHERE ts >= ?' : '';
    final args = since != null ? [since.millisecondsSinceEpoch] : null;
    final rows = await d.rawQuery('''
      SELECT COUNT(*) AS total,
             AVG(risk_score) AS avg_risk,
             MAX(risk_score) AS max_risk
      FROM readings $where
    ''', args);
    return rows.first;
  }

  // ---------------- Alerts ----------------

  Future<int> insertAlert(AlertRecord a) async {
    final d = await db;
    return d.insert('alerts', a.toMap());
  }

  Future<List<AlertRecord>> getAlerts({int? limit}) async {
    final d = await db;
    final rows = await d.query('alerts', orderBy: 'ts DESC', limit: limit);
    return rows.map(AlertRecord.fromMap).toList();
  }

  Future<int> acknowledgeAlert(int id) async {
    final d = await db;
    return d.update('alerts', {'acknowledged': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> acknowledgeAll() async {
    final d = await db;
    return d.update('alerts', {'acknowledged': 1});
  }

  Future<int> clearAlerts() async {
    final d = await db;
    return d.delete('alerts');
  }

  Future<int> alertCount() async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) AS c FROM alerts');
    return (r.first['c'] as num).toInt();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

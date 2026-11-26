import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/models.dart';
import '../widgets/gradient_card.dart';
import '../widgets/status_chip.dart';

/// Historical records and alert log. Records persist locally across
/// restarts (sqflite). Supports search, risk-level filter, sorting,
/// details, delete with confirmation and CSV export.
class HistoryScreen extends StatefulWidget {
  /// 0 = readings, 1 = alert log.
  final int initialTab;
  const HistoryScreen({super.key, this.initialTab = 0});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(
      length: 2, vsync: this, initialIndex: widget.initialTab);
  final _search = TextEditingController();
  String? _levelFilter;
  bool _newestFirst = true;
  List<SensorReading> _readings = [];
  List<AlertRecord> _alerts = [];
  bool _loading = true;

  static const _levels = ['SAFE', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = AppDatabase.instance;
    final readings = await db.getReadings(
      riskLevel: _levelFilter,
      search: _search.text,
      newestFirst: _newestFirst,
      limit: 500,
    );
    final alerts = await db.getAlerts(limit: 300);
    if (mounted) {
      setState(() {
        _readings = readings;
        _alerts = alerts;
        _loading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_readings.isEmpty) return;
    final buf = StringBuffer()
      ..writeln(
          'id,date,time,temperature_c,humidity_pct,smoke,flame,gas,electricity_v,source,risk_score,risk_level');
    for (final r in _readings) {
      final d = DateFormat('yyyy-MM-dd').format(r.timestamp);
      final t = DateFormat('HH:mm:ss').format(r.timestamp);
      buf.writeln([
        r.id ?? '',
        d,
        t,
        r.temperature?.toStringAsFixed(1) ?? '',
        r.humidity?.toStringAsFixed(0) ?? '',
        r.smoke?.toStringAsFixed(0) ?? '',
        r.flameDetected ? 1 : 0,
        r.gas?.toStringAsFixed(0) ?? '',
        r.electricity?.toStringAsFixed(1) ?? '',
        r.source.name,
        r.riskScore?.toStringAsFixed(0) ?? '',
        r.riskLevel ?? '',
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/smart_guardian_readings_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Smart Guardian AI readings export');
  }

  Future<void> _deleteReading(SensorReading r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text(
            'Delete the reading from ${DateFormat('MMM d, HH:mm').format(r.timestamp)}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.critical),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && r.id != null) {
      await AppDatabase.instance.deleteReading(r.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'HISTORY',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 2.0,
              ),
            ),
          ),
          TabBar(
            controller: _tab,
            labelColor: AppColors.electricBlue,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.electricBlue,
            tabs: const [Tab(text: 'Readings'), Tab(text: 'Alert log')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildReadingsTab(),
                _buildAlertsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => _load(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: tr(context, 'Search by level or source...'),
              hintStyle:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _levelFilter == null,
                  onSelected: (_) {
                    _levelFilter = null;
                    _load();
                  },
                  selectedColor: AppColors.electricBlue.withOpacity(0.2),
                  side: const BorderSide(color: AppColors.cardBorder),
                  backgroundColor: AppColors.surface,
                  labelStyle:
                      const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              ),
              for (final level in _levels)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(level),
                    selected: _levelFilter == level,
                    onSelected: (_) {
                      _levelFilter = _levelFilter == level ? null : level;
                      _load();
                    },
                    selectedColor:
                        AppColors.forRiskLevel(level).withOpacity(0.2),
                    side: BorderSide(
                        color: _levelFilter == level
                            ? AppColors.forRiskLevel(level)
                            : AppColors.cardBorder),
                    backgroundColor: AppColors.surface,
                    labelStyle: const TextStyle(
                        fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ActionChip(
                avatar: Icon(
                  _newestFirst
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(_newestFirst ? 'Newest' : 'Oldest'),
                onPressed: () {
                  setState(() => _newestFirst = !_newestFirst);
                  _load();
                },
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.cardBorder),
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.ios_share,
                    size: 14, color: AppColors.electricBlue),
                label: const Text('Export CSV'),
                onPressed: _readings.isEmpty ? null : _exportCsv,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.cardBorder),
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _readings.isEmpty
                  ? const _EmptyHistory()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.electricBlue,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _readings.length,
                        itemBuilder: (context, i) =>
                            _ReadingTile(
                          reading: _readings[i],
                          onDelete: () =>
                              _deleteReading(_readings[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return _alerts.isEmpty
        ? const _EmptyHistory(
            icon: Icons.notifications_none,
            title: 'No alerts yet',
            subtitle:
                'Risk-level changes and flame events are logged here with timestamps.')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: _alerts.length,
            itemBuilder: (context, i) => _AlertTile(alert: _alerts[i]),
          );
  }
}

class _ReadingTile extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback onDelete;
  const _ReadingTile({required this.reading, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final levelColor = AppColors.forRiskLevel(r.riskLevel ?? 'SAFE');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientCard(
        padding: const EdgeInsets.all(12),
        onTap: () => _showDetails(context),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  r.riskScore == null
                      ? '--'
                      : r.riskScore!.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: levelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d - HH:mm:ss')
                        .format(r.timestamp),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.temperature?.toStringAsFixed(1) ?? '--'}°C · smoke ${r.smoke?.toStringAsFixed(0) ?? '--'} · gas ${r.gas?.toStringAsFixed(0) ?? '--'} · flame ${r.flameDetected ? 'YES' : 'no'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                StatusChip(
                  label: r.riskLevel ?? '--',
                  color: levelColor,
                ),
                const SizedBox(height: 4),
                Text(
                  r.source == ReadingSource.demo ? 'DEMO' : 'REAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: r.source == ReadingSource.demo
                        ? AppColors.medium
                        : AppColors.electricBlue,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textMuted),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final r = reading;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final rows = [
          ('Date', DateFormat('EEEE, MMMM d, yyyy').format(r.timestamp)),
          ('Time', DateFormat('HH:mm:ss').format(r.timestamp)),
          ('Temperature',
              r.temperature == null ? '--' : '${r.temperature!.toStringAsFixed(1)} °C'),
          ('Humidity',
              r.humidity == null ? '--' : '${r.humidity!.toStringAsFixed(0)} %'),
          ('Smoke', r.smoke?.toStringAsFixed(0) ?? '--'),
          ('Gas', r.gas?.toStringAsFixed(0) ?? '--'),
          ('Flame', r.flameDetected ? 'Detected' : 'Not detected'),
          ('Electricity',
              r.electricity == null ? '--' : '${r.electricity!.toStringAsFixed(1)} V'),
          ('Risk score',
              r.riskScore == null ? '--' : '${r.riskScore!.toStringAsFixed(0)}%'),
          ('Risk level', r.riskLevel ?? '--'),
          ('Source',
              r.source == ReadingSource.demo ? 'Simulated (Demo Mode)' : 'Real hardware'),
        ];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ),
                      Text(value,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertRecord alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      'CRITICAL' => AppColors.critical,
      'HIGH' => AppColors.high,
      'WARNING' => AppColors.medium,
      _ => AppColors.electricBlue,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientCard(
        padding: const EdgeInsets.all(12),
        borderColor: color.withOpacity(0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              alert.type == 'FLAME'
                  ? Icons.local_fire_department
                  : Icons.notifications_active_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy - HH:mm:ss')
                        .format(alert.timestamp),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyHistory({
    this.icon = Icons.history,
    this.title = 'No records yet',
    this.subtitle =
        'Readings are stored locally as they arrive and stay available after restarting the app.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.electricBlue),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

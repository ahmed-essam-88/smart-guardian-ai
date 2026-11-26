import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/models.dart';
import '../../services/report_service.dart';
import '../widgets/gradient_card.dart';

enum AnalyticsRange { today, week, month }

/// Analytics dashboard: totals, averages, and interactive trend charts with
/// date ranges. Empty states are shown when no historical readings exist.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.today;
  List<SensorReading> _readings = [];
  List<AlertRecord> _alerts = [];
  Map<String, Object?> _stats = const {};
  int _alertCount = 0;
  bool _loading = true;

  String get _rangeLabel {
    switch (_range) {
      case AnalyticsRange.today:
        return 'Today';
      case AnalyticsRange.week:
        return 'Last 7 days';
      case AnalyticsRange.month:
        return 'Last 30 days';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime get _since {
    final now = DateTime.now();
    switch (_range) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.week:
        return now.subtract(const Duration(days: 7));
      case AnalyticsRange.month:
        return now.subtract(const Duration(days: 30));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = AppDatabase.instance;
    final readings = await db.getReadings(since: _since, newestFirst: false);
    final stats = await db.stats(since: _since);
    final alerts = await db.getAlerts();
    final cutoff = _since;
    if (mounted) {
      setState(() {
        _readings = readings;
        _alerts = alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();
        _stats = stats;
        _alertCount = _alerts.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.electricBlue,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Title(),
            const SizedBox(height: 12),
            _RangePicker(
              range: _range,
              onChanged: (r) {
                setState(() => _range = r);
                _load();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _readings.isEmpty
                        ? null
                        : () => ReportService.shareMonitoringReport(
                              rangeLabel: _rangeLabel,
                              readings: _readings,
                              alerts: _alerts,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: Text(tr(context, 'Export PDF report'),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.electricBlue,
                      side: const BorderSide(color: AppColors.electricBlueDim),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_readings.isEmpty)
              const _EmptyState()
            else ...[
              _StatsRow(
                  stats: _stats,
                  alertCount: _alertCount,
                  total: _readings.length),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Temperature over time',
                color: AppColors.high,
                spots: _spots((r) => r.temperature),
                unit: '°C',
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: 'Smoke readings over time',
                color: AppColors.cyan,
                spots: _spots((r) => r.smoke),
                unit: '',
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: 'Risk score over time',
                color: AppColors.electricBlue,
                spots: _spots((r) => r.riskScore),
                unit: '%',
                maxY: 100,
              ),
              const SizedBox(height: 12),
              _ComparisonCard(latest: _readings.last),
            ],
          ],
        ),
      ),
    );
  }

  List<FlSpot> _spots(double? Function(SensorReading) pick) {
    final spots = <FlSpot>[];
    for (var i = 0; i < _readings.length; i++) {
      final v = pick(_readings[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    return spots;
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ANALYTICS',
      style: TextStyle(
        fontFamily: 'Orbitron',
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _RangePicker extends StatelessWidget {
  final AnalyticsRange range;
  final ValueChanged<AnalyticsRange> onChanged;
  const _RangePicker({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (label, value) in [
          ('Today', AnalyticsRange.today),
          ('7 Days', AnalyticsRange.week),
          ('30 Days', AnalyticsRange.month),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: range == value,
              onSelected: (_) => onChanged(value),
              selectedColor: AppColors.electricBlue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: range == value
                    ? AppColors.electricBlue
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: BorderSide(
                color: range == value
                    ? AppColors.electricBlue
                    : AppColors.cardBorder,
              ),
              backgroundColor: AppColors.surface,
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, Object?> stats;
  final int alertCount;
  final int total;
  const _StatsRow(
      {required this.stats, required this.alertCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final avg = (stats['avg_risk'] as num?)?.toDouble();
    final max = (stats['max_risk'] as num?)?.toDouble();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _StatTile(
            label: 'Total Readings', value: '$total', icon: Icons.sensors),
        _StatTile(
            label: 'Total Alerts',
            value: '$alertCount',
            icon: Icons.notifications_active_outlined),
        _StatTile(
            label: 'Average Risk',
            value: avg == null ? '--' : '${avg.toStringAsFixed(1)}%',
            icon: Icons.trending_up),
        _StatTile(
            label: 'Highest Risk',
            value: max == null ? '--' : '${max.toStringAsFixed(0)}%',
            icon: Icons.priority_high),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.electricBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<FlSpot> spots;
  final String unit;
  final double? maxY;

  const _ChartCard({
    required this.title,
    required this.color,
    required this.spots,
    required this.unit,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: spots.isEmpty
                ? const Center(
                    child: Text('No data for this sensor in range',
                        style: TextStyle(color: AppColors.textMuted)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.cardBorder,
                          strokeWidth: 0.6,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceAlt,
                          getTooltipItems: (items) => [
                            for (final s in items)
                              LineTooltipItem(
                                '${s.y.toStringAsFixed(1)}$unit',
                                const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: color,
                          barWidth: 2.4,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final SensorReading latest;
  const _ComparisonCard({required this.latest});

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Temp', latest.temperature, AppColors.high),
      ('Humidity', latest.humidity, AppColors.electricBlue),
      ('Smoke', latest.smoke, AppColors.cyan),
      ('Gas', latest.gas, AppColors.medium),
    ];
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor comparison - latest reading (${DateFormat.Hm().format(latest.timestamp)})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            entries[i].$1,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].$2 ?? 0,
                          color: entries[i].$3,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const GradientCard(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.query_stats, size: 44, color: AppColors.electricBlue),
          SizedBox(height: 12),
          Text(
            'No readings in this range yet',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Charts appear here once the app records sensor readings. Enable Demo Mode to generate sample data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

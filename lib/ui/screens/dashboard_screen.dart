import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../main.dart';
import '../../services/bluetooth_service.dart';
import '../../services/risk_engine.dart';
import '../../state/monitor_controller.dart';
import '../widgets/connection_panel.dart';
import '../widgets/demo_banner.dart';
import '../widgets/gradient_card.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_chip.dart';
import 'emergency_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(controller: c)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _staggered([
                      if (c.isShowingDemo) ...[
                        const DemoBanner(),
                        const SizedBox(height: 12),
                      ],
                      _RiskCard(controller: c),
                      const SizedBox(height: 20),
                      const SectionHeader('SENSOR MONITORING'),
                      const SizedBox(height: 10),
                      _SensorGrid(controller: c),
                      const SizedBox(height: 20),
                      const SectionHeader('DEVICE CONNECTION'),
                      const SizedBox(height: 10),
                      ConnectionPanel(controller: c),
                      const SizedBox(height: 20),
                      const SectionHeader('EMERGENCY'),
                      const SizedBox(height: 10),
                      _EmergencySection(controller: c),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Staggered entrance animation for dashboard sections (built-in only).
  List<Widget> _staggered(List<Widget> children) {
    return [
      for (var i = 0; i < children.length; i++)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + (i ~/ 2) * 60),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - v)),
              child: child,
            ),
          ),
          child: children[i],
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  final MonitorController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final online = c.currentReading != null;
    final btConnected = c.connectionState == BtConnectionState.connected;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMART GUARDIAN EGYPT',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusChip(
                      label: online ? 'SYSTEM ONLINE' : 'SYSTEM IDLE',
                      color: online ? AppColors.safe : AppColors.textMuted,
                      pulse: online,
                    ),
                    const SizedBox(width: 6),
                    StatusChip(
                      label: btConnected ? 'BT LINKED' : 'BT OFF',
                      color: btConnected
                          ? AppColors.electricBlue
                          : AppColors.textMuted,
                      icon: Icons.bluetooth,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final MonitorController controller;
  const _RiskCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final a = c.currentAssessment;
    final reading = c.currentReading;

    if (reading == null || a == null) {
      return GradientCard(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.radar,
                size: 42, color: AppColors.electricBlue.withOpacity(0.7)),
            const SizedBox(height: 12),
            const Text(
              'No sensor data yet',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect a FireGuard_ESP32 device or enable Demo Mode in Settings to see the risk engine in action.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    final color = AppColors.forRiskLevel(a.level);
    return GradientCard(
      borderColor: color.withOpacity(0.45),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Center(
            child: RiskGauge(
              score: a.score,
              level: a.level,
              demo: reading.source == ReadingSource.demo,
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              a.explanation,
              key: ValueKey(a.explanation),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          if (a.flameAlert) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.critical.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.critical.withOpacity(0.6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.critical, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'FLAME DETECTED - ACT NOW',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                      color: AppColors.critical,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  final MonitorController controller;
  const _SensorGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final r = c.currentReading;
    final t = c.thresholds;

    String fmt(double? v, {int digits = 1}) =>
        v == null ? '--' : v.toStringAsFixed(digits);

    (String, Color) band(double? v, double max) {
      if (v == null) return ('NO DATA', AppColors.textMuted);
      if (v > max) return ('CRITICAL', AppColors.critical);
      if (v > max * 0.8) return ('WARNING', AppColors.medium);
      return ('NORMAL', AppColors.safe);
    }

    final tempBand = band(r?.temperature, t.tempMax);
    final smokeBand = band(r?.smoke, t.smokeMax);
    final gasBand = band(r?.gas, t.gasMax);
    final flame = r?.flameDetected ?? false;
    final hasElec = r?.electricity != null;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        SensorCard(
          icon: Icons.thermostat,
          title: 'Temperature',
          value: fmt(r?.temperature),
          unit: '°C',
          status: tempBand.$1,
          statusColor: tempBand.$2,
        ),
        SensorCard(
          icon: Icons.water_drop_outlined,
          title: 'Humidity',
          value: fmt(r?.humidity, digits: 0),
          unit: '%',
          status: r?.humidity == null ? 'NO DATA' : 'MONITORING',
          statusColor: r?.humidity == null
              ? AppColors.textMuted
              : AppColors.electricBlue,
        ),
        SensorCard(
          icon: Icons.cloud_outlined,
          title: 'Smoke',
          value: fmt(r?.smoke, digits: 0),
          unit: '',
          status: smokeBand.$1,
          statusColor: smokeBand.$2,
        ),
        SensorCard(
          icon: Icons.local_fire_department_outlined,
          title: 'Flame',
          value: r == null ? '--' : (flame ? 'YES' : 'NO'),
          unit: '',
          status: r == null ? 'NO DATA' : (flame ? 'DETECTED' : 'CLEAR'),
          statusColor: r == null
              ? AppColors.textMuted
              : (flame ? AppColors.critical : AppColors.safe),
        ),
        SensorCard(
          icon: Icons.air,
          title: 'Gas',
          value: fmt(r?.gas, digits: 0),
          unit: '',
          status: gasBand.$1,
          statusColor: gasBand.$2,
        ),
        SensorCard(
          icon: Icons.electric_bolt_outlined,
          title: 'Electricity',
          value: fmt(r?.electricity, digits: 0),
          unit: 'V',
          status: hasElec ? 'NORMAL' : 'NO DATA',
          statusColor: hasElec ? AppColors.safe : AppColors.textMuted,
        ),
      ],
    );
  }
}

class _EmergencySection extends StatelessWidget {
  final MonitorController controller;
  const _EmergencySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final a = c.currentAssessment;
    final inEmergency =
        a != null && (a.level == RiskEngine.critical || a.flameAlert);
    final color = inEmergency ? AppColors.critical : AppColors.safe;

    return GradientCard(
      borderColor: color.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                inEmergency
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  inEmergency
                      ? 'EMERGENCY CONDITION ACTIVE'
                      : 'No active emergency',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                    AppTheme.pageRoute(const HistoryScreen(initialTab: 1))),
                child: const Text('Alert log'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context)
                .push(AppTheme.pageRoute(const EmergencyScreen())),
            icon: const Icon(Icons.emergency_outlined),
            label: const Text(
              'EMERGENCY ASSISTANCE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

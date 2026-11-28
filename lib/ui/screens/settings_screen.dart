import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../main.dart';
import '../../services/demo_mode.dart';
import '../../services/risk_engine.dart';
import '../../state/monitor_controller.dart';
import '../widgets/gradient_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final s = c.settings;
          return ListView(
            key: ValueKey(c.resetCount),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              _ProfileCard(controller: c),
              const SizedBox(height: 12),
              _LanguageCard(controller: c),
              const SizedBox(height: 12),
              _ThresholdsCard(controller: c),
              const SizedBox(height: 12),
              _TogglesCard(controller: c),
              const SizedBox(height: 12),
              _DemoCard(controller: c),
              const SizedBox(height: 12),
              _EmergencyCard(controller: c),
              const SizedBox(height: 12),
              _DataCard(onChanged: () => setState(() {})),
              const SizedBox(height: 12),
              _ResetCard(controller: c),
              const SizedBox(height: 12),
              const _AboutCard(),
              const SizedBox(height: 16),
              if (s.demoMode)
                Text(
                  'Demo Mode is ON - dashboard values are simulated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.medium.withOpacity(0.9)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final MonitorController controller;
  const _ProfileCard({required this.controller});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late final TextEditingController _name =
      TextEditingController(text: widget.controller.settings.userName);

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.person_outline, title: 'User profile'),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            style: const TextStyle(fontSize: 13.5),
            decoration: _inputDecoration(context, 'Your name'),
            onChanged: (v) =>
                widget.controller.settings.setUserName(v.trim()),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final MonitorController controller;
  const _LanguageCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.language, title: 'Language'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'ar', label: m.Text('العربية')),
                ButtonSegment(value: 'en', label: m.Text('English')),
              ],
              selected: {controller.languageCode},
              onSelectionChanged: (v) => controller.setLanguage(v.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdsCard extends StatefulWidget {
  final MonitorController controller;
  const _ThresholdsCard({required this.controller});

  @override
  State<_ThresholdsCard> createState() => _ThresholdsCardState();
}

class _ThresholdsCardState extends State<_ThresholdsCard> {
  late RiskThresholds _t = widget.controller.thresholds;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.tune, title: 'Risk thresholds (rule-based engine)'),
          const SizedBox(height: 6),
          const Text(
            'Demonstration parameters only - not certified fire-safety thresholds. Real deployments require sensor calibration and validation.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          _slider(
            label: 'Temperature threshold',
            value: _t.tempMax,
            min: 30,
            max: 90,
            unit: '°C',
            onChanged: (v) => _apply(_t.copyWith(tempMax: v)),
          ),
          _slider(
            label: 'Smoke threshold',
            value: _t.smokeMax,
            min: 20,
            max: 300,
            unit: '',
            onChanged: (v) => _apply(_t.copyWith(smokeMax: v)),
          ),
          _slider(
            label: 'Gas threshold',
            value: _t.gasMax,
            min: 20,
            max: 300,
            unit: '',
            onChanged: (v) => _apply(_t.copyWith(gasMax: v)),
          ),
        ],
      ),
    );
  }

  void _apply(RiskThresholds t) {
    setState(() => _t = t);
    widget.controller.updateThresholds(t);
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ),
            Text(
              '${value.toStringAsFixed(0)}$unit',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.electricBlue,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.electricBlue,
          inactiveColor: AppColors.cardBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TogglesCard extends StatelessWidget {
  final MonitorController controller;
  const _TogglesCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = controller.settings;
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.notifications_outlined,
              title: 'Notifications & Bluetooth'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Emergency notifications',
                style: TextStyle(fontSize: 13.5)),
            subtitle: const Text(
                'High-priority local alerts for flame and risk-level changes',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: s.notificationsEnabled,
            activeColor: AppColors.electricBlue,
            onChanged: (v) async {
              await s.setNotificationsEnabled(v);
              controller.notify();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Automatic reconnection',
                style: TextStyle(fontSize: 13.5)),
            subtitle: const Text(
                'Try to reconnect to the ESP32 when the link drops',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: s.autoReconnect,
            activeColor: AppColors.electricBlue,
            onChanged: (v) async {
              await s.setAutoReconnect(v);
              controller.notify();
            },
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final MonitorController controller;
  const _DemoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.science_outlined, title: 'Demo Mode'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Demo Mode',
                style: TextStyle(fontSize: 13.5)),
            subtitle: const Text(
                'Simulated readings, clearly marked DEMO everywhere',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: c.demoActive,
            activeColor: AppColors.medium,
            onChanged: (v) => c.setDemoMode(v),
          ),
          if (c.demoActive) ...[
            const Text('Simulated condition',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (label, scenario) in [
                  ('Normal', DemoScenario.normal),
                  ('Elevated', DemoScenario.elevated),
                  ('Fire emergency', DemoScenario.fire),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: c.demoScenario == scenario,
                    onSelected: (_) => c.setDemoScenario(scenario),
                    selectedColor: AppColors.medium.withOpacity(0.2),
                    side: BorderSide(
                      color: c.demoScenario == scenario
                          ? AppColors.medium
                          : AppColors.cardBorder,
                    ),
                    backgroundColor: AppColors.surface,
                    labelStyle: const TextStyle(
                        fontSize: 11.5, color: AppColors.textPrimary),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatefulWidget {
  final MonitorController controller;
  const _EmergencyCard({required this.controller});

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard> {
  late final TextEditingController _number = TextEditingController(
      text: widget.controller.settings.emergencyNumber);
  late final TextEditingController _sos = TextEditingController(
      text: widget.controller.settings
          .sosMessageFor(widget.controller.languageCode));

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.settings;
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.emergency_outlined, title: 'Emergency assistance'),
          const SizedBox(height: 8),
          TextField(
            controller: _number,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 13.5),
            decoration:
                _inputDecoration(context, 'Emergency number (default: 180 Egypt fire)'),
            onChanged: (v) => s.setEmergencyNumber(v.trim()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _sos,
            maxLines: 2,
            style: const TextStyle(fontSize: 13.5),
            decoration: _inputDecoration(context, 'WhatsApp SOS message'),
            onChanged: (v) => s.setSosMessage(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Attach location to SOS',
                style: TextStyle(fontSize: 13.5)),
            subtitle: const Text(
                'Only attached after your explicit permission request',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            value: s.shareLocation,
            activeColor: AppColors.electricBlue,
            onChanged: (v) async {
              await s.setShareLocation(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final VoidCallback onChanged;
  const _DataCard({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.storage_outlined, title: 'Data management'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmClear(
                      context, 'Delete all stored readings?', () async {
                    await AppDatabase.instance.clearReadings();
                  }),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Clear readings',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmClear(
                      context, 'Delete the alert log?', () async {
                    await AppDatabase.instance.clearAlerts();
                  }),
                  icon: const Icon(Icons.notification_important_outlined,
                      size: 16),
                  label: const Text('Clear alerts',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, String title,
      Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await action();
      onChanged();
    }
  }
}

class _ResetCard extends StatelessWidget {
  final MonitorController controller;
  const _ResetCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.restart_alt_rounded, title: 'Reset app'),
          const SizedBox(height: 6),
          const Text(
            'Restore every setting to its default and delete all stored '
            'readings and alerts.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.critical,
                  side: BorderSide(color: AppColors.critical)),
              onPressed: () => _confirm(context),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset to defaults'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset the whole app?'),
        content: const Text(
            'This restores all settings (thresholds, emergency number, SOS '
            'message, toggles, Demo Mode) to defaults, disconnects '
            'Bluetooth and deletes all readings and alerts. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.resetToDefaults();
      messenger.showSnackBar(
          const SnackBar(content: Text('App reset to defaults.')));
    }
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.info_outline, title: 'About Smart Guardian AI'),
          SizedBox(height: 8),
          Text(
            'Version 1.0.0\n'
            'Intelligent Fire Risk Monitoring & Early Warning System.\n\n'
            'The current risk engine is rule-based with configurable demonstration thresholds. '
            'Machine-learning risk classification is planned as a future upgrade and is not active in this version.\n\n'
            'This app is a supplementary monitoring tool. It is not a replacement for certified smoke alarms, '
            'certified fire detection systems, or professional emergency services.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            'Developer · المطوّر: احمد عصام محمد توفيق حسن',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.electricBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hint) =>
    InputDecoration(
      hintText: tr(context, hint),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
    );

import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../main.dart';
import '../../services/location_service.dart';
import 'safety_screen.dart';
import '../widgets/gradient_card.dart';

/// Emergency assistance: dialer (never auto-calls), WhatsApp SOS draft that
/// the user reviews before sending, and fire-safety guidance.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late final TextEditingController _msg;
  bool _init = false;
  bool _includeLocation = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final c = AppScope.of(context);
      _msg = TextEditingController(
          text: c.settings.sosMessageFor(c.languageCode));
      _includeLocation = c.settings.shareLocation;
      _init = true;
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _dial([String? override]) async {
    final number = override ?? AppScope.of(context).settings.emergencyNumber;
    final uri = Uri(scheme: 'tel', path: number);
    // The dialer opens with the number filled in. The user presses call.
    if (!await launchUrl(uri)) _snack('Could not open the phone dialer.');
  }

  Future<void> _sendWhatsApp() async {
    setState(() => _busy = true);
    var text = _msg.text.trim();
    if (text.isEmpty) {
      _snack('Write a message first.');
      setState(() => _busy = false);
      return;
    }
    if (_includeLocation) {
      final status = await Permission.locationWhenInUse.request();
      if (!mounted) return;
      if (status.isGranted) {
        _snack(tr(context, 'Getting your location...'));
        final loc = await LocationService().current();
        if (!mounted) return;
        if (loc != null) {
          final ar = isArabicContext(context);
          text += ar
              ? '\nموقعي: ${loc.mapsUrl}\n(الدقة حوالي ${loc.accuracyMeters.round()} متر)'
              : '\nMy location: ${loc.mapsUrl}\n(accuracy about ${loc.accuracyMeters.round()} m)';
        } else {
          _snack(tr(context,
              'Could not get your location. Turn on GPS and try again, or send without it.'));
        }
      } else {
        _snack(tr(context,
            'Location permission denied. Message sent without location.'));
      }
    }
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    // Opens WhatsApp with the text prefilled. The user chooses the contact
    // and presses send.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack('Could not open WhatsApp.');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final number = AppScope.of(context).settings.emergencyNumber;
    return Scaffold(
      appBar: AppBar(title: const Text('EMERGENCY')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            borderColor: AppColors.critical.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Emergency call',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'Opens the phone dialer with $number. The call is never started automatically.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.critical,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => _dial(),
                  icon: const Icon(Icons.phone),
                  label: Text('OPEN DIALER ($number)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Egypt emergency numbers',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Tap a number to open the dialer with it filled in. '
                  'You press call yourself.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.critical,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _dial('180'),
                        icon: const Icon(Icons.local_fire_department),
                        label: const Text('Fire 180'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.high,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _dial('123'),
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Ambulance 123'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _dial('122'),
                  icon: const Icon(Icons.local_police_outlined, size: 18),
                  label: const Text('Police 122'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GradientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('WhatsApp SOS',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _msg,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include my location',
                      style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                      'Sends a Google Maps link with your GPS position. Asks permission now.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  value: _includeLocation,
                  activeColor: AppColors.electricBlue,
                  onChanged: (v) => setState(() => _includeLocation = v),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _sendWhatsApp,
                  icon: const Icon(Icons.send),
                  label: const Text('REVIEW IN WHATSAPP'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'WhatsApp opens with your text. You pick the contact and press send.',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GradientCard(
            borderColor: AppColors.electricBlue.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('How to protect yourself',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Quick steps and what to do for fire, gas leaks and electrical hazards, in Arabic and English.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SafetyScreen())),
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Open safety guide'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

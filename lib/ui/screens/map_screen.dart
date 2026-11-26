import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../data/demo_sites.dart';
import '../../main.dart';
import '../../state/monitor_controller.dart';
import '../widgets/gradient_card.dart';
import '../widgets/status_chip.dart';

/// Smart Map: building, device and alert markers over OpenStreetMap.
///
/// All sites are DEMO LOCATIONS (sample data). The Smouha tower mirrors the
/// live dashboard risk level so the map reacts to Demo Mode scenarios.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) => _buildBody(c),
      ),
    );
  }

  Widget _buildBody(MonitorController c) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'SMART MAP',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              StatusChip(
                label: tr(context, 'DEMO LOCATIONS'),
                color: AppColors.medium,
                icon: Icons.science_outlined,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(30.35, 30.55),
                    initialZoom: 6.6,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.smartguardian.smart_guardian_ai',
                      tileBuilder: darkModeTileBuilder,
                    ),
                    MarkerLayer(markers: _buildMarkers(c)),
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution(
                          '© OpenStreetMap contributors',
                          textStyle: TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: _Legend(),
        ),
      ],
    );
  }

  String _siteStatus(DemoSite site, MonitorController c) {
    if (site.linkedToLive) {
      final a = c.currentAssessment;
      return a?.level ?? 'NO DATA';
    }
    return site.status ?? 'SAFE';
  }

  List<Marker> _buildMarkers(MonitorController c) {
    final markers = <Marker>[];
    for (final site in kDemoSites) {
      final status = _siteStatus(site, c);
      final color = status == 'NO DATA'
          ? AppColors.textMuted
          : AppColors.forRiskLevel(status);
      markers.add(
        Marker(
          point: LatLng(site.lat, site.lng),
          width: 46,
          height: 46,
          child: GestureDetector(
            onTap: () => _showSite(site, status),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2.4),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.35), blurRadius: 8),
                    ],
                  ),
                  child: Icon(Icons.apartment, color: color, size: 17),
                ),
                if (status == 'HIGH' || status == 'CRITICAL')
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.critical, size: 12),
              ],
            ),
          ),
        ),
      );
      // Device markers: small cyan dots offset near the building.
      for (var i = 0; i < site.deviceIds.length; i++) {
        markers.add(
          Marker(
            point: LatLng(site.lat + 0.012 * (i + 1), site.lng - 0.014),
            width: 18,
            height: 18,
            child: Tooltip(
              message: site.deviceIds[i],
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: const Icon(Icons.memory,
                    size: 9, color: AppColors.background),
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  void _showSite(DemoSite site, String status) {
    final color = status == 'NO DATA'
        ? AppColors.textMuted
        : AppColors.forRiskLevel(status);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      site.name,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  StatusChip(label: tr(context, status), color: color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${site.city} · ${site.deviceIds.length} ${tr(context, 'devices')} (${site.deviceIds.join(', ')})',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              if (site.linkedToLive) ...[
                const SizedBox(height: 8),
                Text(
                  tr(context,
                      'This site mirrors the live dashboard risk level. Run a Demo Mode scenario to watch it change.'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.medium.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.medium.withOpacity(0.35)),
                ),
                child: Text(
                  tr(context,
                      'DEMO LOCATION - sample site, not a real monitored building. No real emergencies are reported.'),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.medium, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (label, color) in [
            ('SAFE', AppColors.safe),
            ('MEDIUM', AppColors.medium),
            ('HIGH', AppColors.high),
            ('CRITICAL', AppColors.critical),
          ])
            _LegendItem(label: tr(context, label), color: color),
          _LegendItem(
              label: tr(context, 'Device'),
              color: AppColors.cyan,
              icon: Icons.memory),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _LegendItem({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null
            ? Icon(icon, size: 12, color: color)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

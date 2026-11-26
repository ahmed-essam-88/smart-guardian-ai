/// Demo sites for the Smart Map.
///
/// Every site here is SAMPLE DATA, clearly labeled DEMO LOCATION in the UI.
/// None of these are real monitored buildings. When real ESP32 devices are
/// deployed, a site registry can replace this list without changing the map
/// screen.
class DemoSite {
  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;

  /// SAFE / MEDIUM / HIGH / CRITICAL, or null when the site is linked to the
  /// live monitor state instead of a fixed demo status.
  final String? status;
  final List<String> deviceIds;

  /// True for the one site that mirrors the live dashboard risk level.
  final bool linkedToLive;

  const DemoSite({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.status,
    required this.deviceIds,
    this.linkedToLive = false,
  });
}

const List<DemoSite> kDemoSites = [
  DemoSite(
    id: 'site-alex-01',
    name: 'Demo Tower - Smouha',
    city: 'Alexandria',
    lat: 31.2156,
    lng: 29.9436,
    status: null,
    deviceIds: ['SG-001', 'SG-002'],
    linkedToLive: true,
  ),
  DemoSite(
    id: 'site-alex-02',
    name: 'Demo Warehouse - Borg El Arab',
    city: 'Alexandria',
    lat: 30.8481,
    lng: 29.6116,
    status: 'SAFE',
    deviceIds: ['SG-003'],
  ),
  DemoSite(
    id: 'site-alex-03',
    name: 'Demo Factory - Agami',
    city: 'Alexandria',
    lat: 31.0959,
    lng: 29.7604,
    status: 'MEDIUM',
    deviceIds: ['SG-004'],
  ),
  DemoSite(
    id: 'site-cai-01',
    name: 'Demo Office - Nasr City',
    city: 'Cairo',
    lat: 30.0566,
    lng: 31.3300,
    status: 'SAFE',
    deviceIds: ['SG-005'],
  ),
  DemoSite(
    id: 'site-cai-02',
    name: 'Demo Mall - New Cairo',
    city: 'Cairo',
    lat: 30.0300,
    lng: 31.4700,
    status: 'HIGH',
    deviceIds: ['SG-006', 'SG-007'],
  ),
  DemoSite(
    id: 'site-cai-03',
    name: 'Demo Hotel - Zamalek',
    city: 'Cairo',
    lat: 30.0626,
    lng: 31.2197,
    status: 'SAFE',
    deviceIds: ['SG-008'],
  ),
];

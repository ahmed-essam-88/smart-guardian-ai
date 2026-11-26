import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../services/bluetooth_service.dart';
import '../../state/monitor_controller.dart';
import 'gradient_card.dart';
import 'status_chip.dart';

/// ESP32 connection card: pick a paired/discovered device, connect,
/// disconnect, see status and last data update. No fake connection states:
/// every label reflects the real Bluetooth state.
class ConnectionPanel extends StatefulWidget {
  final MonitorController controller;

  const ConnectionPanel({super.key, required this.controller});

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final _bt = BluetoothService();
  List<BluetoothDeviceInfo> _devices = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final devices = await _bt.getPairedDevices();
    // Put the expected ESP32 device name first.
    devices.sort((a, b) {
      final aHit = a.name.contains(BluetoothService.expectedDeviceName) ? 0 : 1;
      final bHit = b.name.contains(BluetoothService.expectedDeviceName) ? 0 : 1;
      return aHit.compareTo(bHit);
    });
    if (mounted) {
      setState(() {
        _devices = devices;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final state = c.connectionState;
    final (label, color) = switch (state) {
      BtConnectionState.connected => ('CONNECTED', AppColors.safe),
      BtConnectionState.connecting => ('CONNECTING', AppColors.medium),
      BtConnectionState.disconnected => ('DISCONNECTED', AppColors.textMuted),
    };

    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth, color: AppColors.electricBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ESP32 Connection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusChip(
                  label: label,
                  color: color,
                  pulse: state == BtConnectionState.connected),
            ],
          ),
          const SizedBox(height: 12),
          if (state == BtConnectionState.connected)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Linked to ${c.connectedDeviceName ?? 'device'}'
                '${c.lastRealUpdate != null ? ' - last data ${_timeText(c.lastRealUpdate!)}' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          if (c.lastInvalidDataNotice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                c.lastInvalidDataNotice!,
                style: const TextStyle(fontSize: 11, color: AppColors.medium),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceAlt,
                      hint: Text(
                        _loading
                            ? 'Loading paired devices...'
                            : (_devices.isEmpty
                                ? 'No paired devices - pair FireGuard_ESP32 first'
                                : 'Select ESP32'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: [
                        for (final d in _devices)
                          DropdownMenuItem(
                            value: d.address,
                            child: Text(
                              '${d.name} (${d.address})',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: state == BtConnectionState.connecting
                          ? null
                          : (address) async {
                              if (address == null) return;
                              final device = _devices
                                  .firstWhere((d) => d.address == address);
                              await c.connectTo(device.address,
                                  name: device.name);
                            },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: tr(context, 'Refresh devices'),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, color: AppColors.electricBlue),
              ),
              if (state != BtConnectionState.disconnected)
                IconButton(
                  tooltip: tr(context, 'Disconnect'),
                  onPressed: c.disconnect,
                  icon: const Icon(Icons.link_off, color: AppColors.critical),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeText(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

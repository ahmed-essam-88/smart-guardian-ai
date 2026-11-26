import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import 'account_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation shell with animated tab transitions.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    MapScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
    SettingsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _tabs[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: tr(context, 'Home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.map_outlined),
                activeIcon: const Icon(Icons.map),
                label: tr(context, 'Map')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.insights_outlined),
                activeIcon: const Icon(Icons.insights),
                label: tr(context, 'Analytics')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.history_outlined),
                activeIcon: const Icon(Icons.history),
                label: tr(context, 'History')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: tr(context, 'Settings')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle_outlined),
                activeIcon: const Icon(Icons.account_circle),
                label: tr(context, 'My account')),
          ],
        ),
      ),
    );
  }
}

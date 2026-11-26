import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../main.dart';
import 'auth_gate.dart';

/// First-run onboarding: three short pages, shown once, then sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppScope.of(context).settings.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(AppTheme.pageRoute(const AuthGate()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_PageData>[
      _PageData(
        image: true,
        title: 'Welcome to Smart Guardian Egypt',
        body:
            'Smart safety and environmental monitoring for your buildings, in one place.',
      ),
      _PageData(
        icon: Icons.radar,
        title: 'Early fire-risk warning',
        body:
            'Six sensors feed a transparent, rule-based risk engine. Every score comes with a clear explanation - no black boxes.',
      ),
      _PageData(
        icon: Icons.science_outlined,
        title: 'Try it now, connect hardware later',
        body:
            'Demo Mode simulates realistic scenarios, always clearly labeled as simulated. ESP32 sensors can feed live data over Bluetooth when you are ready.',
      ),
    ];
    final last = _page == pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGlow),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pager,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _Page(data: pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.electricBlue
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  tr(context,
                      'Smart Guardian Egypt supplements - never replaces - certified fire alarms and emergency services.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: last
                        ? _finish
                        : () => _pager.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    child: Text(
                      last ? tr(context, 'Get started') : tr(context, 'Next'),
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final IconData? icon;
  final bool image;
  final String title;
  final String body;
  const _PageData({
    this.icon,
    this.image = false,
    required this.title,
    required this.body,
  });
}

class _Page extends StatelessWidget {
  final _PageData data;
  const _Page({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.image)
            Image.asset('assets/brand/logo_transparent.png',
                width: 150, height: 150)
          else
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(data.icon, size: 52, color: AppColors.cyan),
            ),
          const SizedBox(height: 30),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w700,
              fontSize: 19,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';
import '../../main.dart';
import 'auth_gate.dart';
import 'onboarding_screen.dart';

/// Splash screen: brand mark, app name, subtitle and an elegant loading
/// animation, then a smooth transition into the dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      final seen = AppScope.of(context).settings.onboardingSeen;
      Navigator.of(context).pushReplacement(AppTheme.pageRoute(
          seen ? const AuthGate() : const OnboardingScreen()));
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _entry, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _entry, curve: Curves.easeIn);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGlow),
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween(begin: 0.82, end: 1.0).animate(scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final ring = 1.0 + _pulse.value * 0.35;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - _pulse.value) * 0.35,
                            child: Transform.scale(
                              scale: ring,
                              child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.electricBlue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: Image.asset('assets/brand/logo_transparent.png',
                        width: 150, height: 150),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SMART GUARDIAN EGYPT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Intelligence That Protects. Technology That Builds the Future.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: AppColors.cardBorder,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.electricBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'v1.1.0',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

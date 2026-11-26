import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import '../../core/l10n.dart';

import '../../core/theme.dart';

/// Large animated circular risk indicator.
///
/// The sweep angle and color animate between states with built-in Flutter
/// animation (TweenAnimationBuilder), so every score change reads as a
/// smooth gauge movement.
class RiskGauge extends StatelessWidget {
  final double score; // 0..100
  final String level;
  final bool demo;
  final double size;

  const RiskGauge({
    super.key,
    required this.score,
    required this.level,
    this.demo = false,
    this.size = 230,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forRiskLevel(level);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.clamp(0, 100)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _GaugePainter(
                  progress: animatedScore / 100,
                  color: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      '${animatedScore.toStringAsFixed(0)}%',
                      key: ValueKey(animatedScore.round()),
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: size * 0.21,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RISK SCORE',
                    style: TextStyle(
                      fontSize: size * 0.05,
                      letterSpacing: 2.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.6)),
                    ),
                    child: Text(
                      demo ? '$level · DEMO' : level,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w600,
                        fontSize: size * 0.055,
                        letterSpacing: 1.6,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    const startAngle = math.pi * 0.75; // 135°
    const sweepTotal = math.pi * 1.5; // 270°

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cardBorder.withOpacity(0.55);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..color = color.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress,
        false,
        glowPaint,
      );

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepTotal,
          colors: [color.withOpacity(0.55), color],
          transform:
              GradientRotation(startAngle - math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}

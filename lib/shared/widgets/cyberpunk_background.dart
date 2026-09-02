import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CyberpunkBackground extends StatefulWidget {
  final Widget child;
  const CyberpunkBackground({super.key, required this.child});

  @override
  State<CyberpunkBackground> createState() => _CyberpunkBackgroundState();
}

class _CyberpunkBackgroundState extends State<CyberpunkBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Full-screen BackdropFilter + continuous repaint is very expensive on
  // mobile GPUs and can cause ANR on low-end devices. Keep it static there.
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!_isMobile) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Container(
        color: AppColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _OrbPainter(
                  progress: 0.25,
                  orbColors: AppColors.orbColors,
                  orbOpacity: AppColors.orbOpacity,
                ),
                size: Size.infinite,
              ),
            ),
            widget.child,
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          color: AppColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Animated orbs via CustomPainter
              CustomPaint(
                painter: _OrbPainter(
                  progress: _controller.value,
                  orbColors: AppColors.orbColors,
                  orbOpacity: AppColors.orbOpacity,
                ),
                size: Size.infinite,
              ),
              // Layer 2: BackdropFilter blur — blends overlapping orbs
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
              // Layer 3: Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final List<Color> orbColors;
  final double orbOpacity;

  _OrbPainter({
    required this.progress,
    required this.orbColors,
    required this.orbOpacity,
  });

  // Orb configs: [baseSize, speedX, speedY, ampX, ampY, phaseX, phaseY, colorIndex, colorBlend]
  static const _orbDefs = [
    _OrbDef(size: 360, speedX: 0.7, speedY: 0.5, ampX: 0.18, ampY: 0.15, phaseX: 0.0, phaseY: 0.3, ci: 0, blend: 0.0),
    _OrbDef(size: 260, speedX: 0.5, speedY: 0.8, ampX: 0.15, ampY: 0.18, phaseX: 1.5, phaseY: 0.8, ci: 1, blend: 0.3),
    _OrbDef(size: 150, speedX: 1.0, speedY: 0.9, ampX: 0.22, ampY: 0.20, phaseX: 3.0, phaseY: 1.2, ci: 0, blend: 0.6),
    _OrbDef(size: 120, speedX: 1.2, speedY: 1.1, ampX: 0.20, ampY: 0.25, phaseX: 4.5, phaseY: 2.0, ci: 1, blend: 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;

    for (final def in _orbDefs) {
      // Position using sin/cos for smooth floating orbits
      final cx = size.width * (0.5 + def.ampX * sin(t * def.speedX + def.phaseX));
      final cy = size.height * (0.5 + def.ampY * cos(t * def.speedY + def.phaseY));

      // Pick and blend orb color
      final c1 = orbColors[def.ci.clamp(0, orbColors.length - 1)];
      final c2 = orbColors[(def.ci + 1).clamp(0, orbColors.length - 1)];
      final orbColor = Color.lerp(c1, c2, def.blend) ?? c1;

      final radius = def.size * 0.5;

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            orbColor.withValues(alpha: orbOpacity),
            orbColor.withValues(alpha: orbOpacity * 0.35),
            orbColor.withValues(alpha: 0.0),
          ],
          [0.0, 0.4, 1.0],
        );

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.progress != progress;
}

class _OrbDef {
  final double size;
  final double speedX, speedY;
  final double ampX, ampY;
  final double phaseX, phaseY;
  final int ci;
  final double blend;

  const _OrbDef({
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.ampX,
    required this.ampY,
    required this.phaseX,
    required this.phaseY,
    required this.ci,
    required this.blend,
  });
}

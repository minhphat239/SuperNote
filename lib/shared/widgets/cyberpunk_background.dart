import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_theme.dart';

class CyberpunkBackground extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool showOrbs;
  const CyberpunkBackground({super.key, required this.child, this.backgroundColor, this.showOrbs = true});

  @override
  State<CyberpunkBackground> createState() => _CyberpunkBackgroundState();
}

class _CyberpunkBackgroundState extends State<CyberpunkBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    final useOrbs = widget.showOrbs && AppColors.hasDetailedOrbs;
    final effect = AppColors.backgroundEffect;

    // ===== Simple / solid background with optional effect =====
    if (!useOrbs) {
      if (effect == BackgroundEffect.none) {
        return Container(
          color: widget.backgroundColor ?? AppColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black.withValues(alpha: 0.4)),
              widget.child,
            ],
          ),
        );
      }

      // Has a background effect — animate it
      if (_isMobile) {
        return Container(
          color: widget.backgroundColor ?? AppColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: _buildEffectPainter(effect, 0.25)),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              widget.child,
            ],
          ),
        );
      }

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            color: widget.backgroundColor ?? AppColors.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildEffectPainter(effect, _controller.value),
                Container(color: Colors.black.withValues(alpha: 0.35)),
                widget.child,
              ],
            ),
          );
        },
      );
    }

    // ===== Detailed orb background =====
    if (_isMobile) {
      return Container(
        color: widget.backgroundColor ?? AppColors.background,
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
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: Colors.transparent),
            ),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            widget.child,
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          color: widget.backgroundColor ?? AppColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _OrbPainter(
                  progress: _controller.value,
                  orbColors: AppColors.orbColors,
                  orbOpacity: AppColors.orbOpacity,
                ),
                size: Size.infinite,
              ),
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildEffectPainter(BackgroundEffect effect, double progress) {
    switch (effect) {
      case BackgroundEffect.rain:
        return CustomPaint(
          painter: _RainPainter(progress: progress),
          size: Size.infinite,
        );
      case BackgroundEffect.sunrise:
        return CustomPaint(
          painter: _SunrisePainter(progress: progress),
          size: Size.infinite,
        );
      case BackgroundEffect.none:
        return const SizedBox.shrink();
    }
  }
}

// ===================================================================
// RAIN EFFECT — falling droplets with subtle splash at bottom
// ===================================================================

class _RainPainter extends CustomPainter {
  final double progress;
  static const _dropCount = 80;

  _RainPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final t = progress * 2 * pi;

    for (var i = 0; i < _dropCount; i++) {
      // Deterministic per-drop seed
      final seed = i * 1.618033988749895;
      final x = (rng.nextDouble() * size.width);
      final speed = 0.6 + rng.nextDouble() * 0.8;
      final length = 12.0 + rng.nextDouble() * 28.0;
      final opacity = 0.08 + rng.nextDouble() * 0.18;
      final width = 0.8 + rng.nextDouble() * 0.8;

      // Y position cycles through screen
      final yOffset = (t * speed * 300 + seed * 500) % (size.height + length * 2);
      final y = yOffset - length;

      final paint = Paint()
        ..color = const Color(0xFF88CCFF).withValues(alpha: opacity)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      // Draw raindrop as a thin line
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1.5, y + length),
        paint,
      );
    }

    // Subtle misty glow at the bottom
    final mistPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.85),
        Offset(0, size.height),
        [
          const Color(0x00000000),
          const Color(0x0D4488CC),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      mistPaint,
    );
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.progress != progress;
}

// ===================================================================
// SUNRISE EFFECT — glowing orb rising from bottom + warm gradient
// ===================================================================

class _SunrisePainter extends CustomPainter {
  final double progress;

  _SunrisePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;

    // Sun orb rises from bottom to ~40% of screen height
    final sunY = size.height * (0.95 - 0.55 * (0.5 + 0.5 * sin(t - pi / 2)));
    final sunX = size.width * 0.5;
    final sunRadius = size.width * 0.18;

    // --- Sky gradient (warm sunrise colors) ---
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          const Color(0xFF0A0612).withValues(alpha: 0.9),
          const Color(0xFF1A0A20).withValues(alpha: 0.7),
          Color.lerp(const Color(0xFF2D1B40), const Color(0xFFFF6B35), 0.5 + 0.5 * sin(t - 0.5))!.withValues(alpha: 0.6),
          Color.lerp(const Color(0xFFFF8C42), const Color(0xFFFFD700), 0.5 + 0.5 * sin(t))!.withValues(alpha: 0.7),
        ],
        [0.0, 0.3, 0.7, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // --- Sun glow halo (large, soft) ---
    final haloPaint = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        Offset(sunX, sunY),
        sunRadius * 4,
        [
          const Color(0x40FFAA33).withValues(alpha: 0.3 + 0.15 * sin(t * 2)),
          const Color(0x20FF6600).withValues(alpha: 0.15),
          const Color(0x00FF4400),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 4, haloPaint);

    // --- Sun core ---
    final corePaint = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        Offset(sunX, sunY),
        sunRadius,
        [
          const Color(0xFFFFEE88),
          const Color(0xFFFFCC33),
          const Color(0xFFFF8800).withValues(alpha: 0.0),
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, corePaint);

    // --- Light rays ---
    final rayPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + t * 0.3;
      final innerR = sunRadius * 1.3;
      final outerR = sunRadius * (2.2 + 0.4 * sin(t + i));
      final rayOpacity = 0.06 + 0.04 * sin(t * 2 + i);
      rayPaint.color = const Color(0xFFFFDD66).withValues(alpha: rayOpacity);
      canvas.drawLine(
        Offset(sunX + cos(angle) * innerR, sunY + sin(angle) * innerR),
        Offset(sunX + cos(angle) * outerR, sunY + sin(angle) * outerR),
        rayPaint,
      );
    }

    // --- Horizon glow line ---
    final horizonY = size.height * 0.92;
    final horizonPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, horizonY - 30),
        Offset(0, horizonY + 30),
        [
          const Color(0x00FF8800),
          const Color(0x30FFAA44).withValues(alpha: 0.2 + 0.1 * sin(t)),
          const Color(0x00FF6600),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 30, size.width, 60),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(_SunrisePainter old) => old.progress != progress;
}

// ===================================================================
// ORB PAINTERS (existing — unchanged)
// ===================================================================

class _OrbPainter extends CustomPainter {
  final double progress;
  final List<Color> orbColors;
  final double orbOpacity;

  _OrbPainter({
    required this.progress,
    required this.orbColors,
    required this.orbOpacity,
  });

  static const _orbDefs = [
    _OrbDef(size: 360, speedX: 0.7, speedY: 0.5, ampX: 0.18, ampY: 0.15, phaseX: 0.0, phaseY: 0.3, ci: 0, blend: 0.0),
    _OrbDef(size: 260, speedX: 0.5, speedY: 0.8, ampX: 0.15, ampY: 0.18, phaseX: 1.5, phaseY: 0.8, ci: 1, blend: 0.3),
    _OrbDef(size: 150, speedX: 1.0, speedY: 0.9, ampX: 0.22, ampY: 0.20, phaseX: 3.0, phaseY: 1.2, ci: 0, blend: 0.6),
    _OrbDef(size: 120, speedX: 1.2, speedY: 1.1, ampX: 0.20, ampY: 0.25, phaseX: 4.5, phaseY: 2.0, ci: 1, blend: 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
    final t = progress * 2 * pi;

    for (final def in _orbDefs) {
      final cx = size.width * (0.5 + def.ampX * sin(t * def.speedX + def.phaseX));
      final cy = size.height * (0.5 + def.ampY * cos(t * def.speedY + def.phaseY));

      final c1 = orbColors[def.ci.clamp(0, orbColors.length - 1)];
      final c2 = orbColors[(def.ci + 1).clamp(0, orbColors.length - 1)];
      final orbColor = Color.lerp(c1, c2, def.blend) ?? c1;

      final radius = def.size * 0.5;

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
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
    canvas.restore();
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

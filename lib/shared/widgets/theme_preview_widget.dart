import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';

/// Widget preview theme với hiệu ứng nhẹ cho các theme minimalist
class ThemePreviewWidget extends StatefulWidget {
  final GlassTheme theme;
  final bool isSelected;
  final double size;

  const ThemePreviewWidget({
    super.key,
    required this.theme,
    required this.isSelected,
    this.size = 32,
  });

  @override
  State<ThemePreviewWidget> createState() => _ThemePreviewWidgetState();
}

class _ThemePreviewWidgetState extends State<ThemePreviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Hiệu ứng tỏa sáng (breathing glow)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Hiệu ứng xoay gradient
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Hiệu ứng pulse nhẹ
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ áp dụng hiệu ứng cho 3 theme minimalist
    final hasEffect = !widget.theme.hasDetailedOrbs;

    if (!hasEffect) {
      return _buildStaticPreview();
    }

    return _buildAnimatedPreview();
  }

  Widget _buildStaticPreview() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.theme.borderStart, widget.theme.borderEnd],
        ),
        shape: BoxShape.circle,
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.theme.accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: widget.isSelected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildAnimatedPreview() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _rotateController, _pulseController]),
      builder: (context, child) {
        final glowValue = _glowController.value;
        final rotateValue = _rotateController.value;
        final pulseValue = _pulseController.value;

        // Tính toán các giá trị hiệu ứng
        final glowAlpha = 0.15 + (glowValue * 0.2); // 0.15 -> 0.35
        final pulseScale = 1.0 + (pulseValue * 0.08); // 1.0 -> 1.08
        final rotationAngle = rotateValue * 2 * pi;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Glow effect chính
                BoxShadow(
                  color: widget.theme.accent.withValues(alpha: glowAlpha),
                  blurRadius: 12 + (glowValue * 4), // 12 -> 16
                  spreadRadius: glowValue * 2,
                ),
                // Glow effect phụ
                BoxShadow(
                  color: widget.theme.secondary.withValues(alpha: glowAlpha * 0.5),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gradient circle xoay
                Transform.rotate(
                  angle: rotationAngle,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.theme.borderStart,
                          widget.theme.accent,
                          widget.theme.borderEnd,
                          widget.theme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Inner glow circle
                Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15 + (glowValue * 0.1)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Mini floating particles
                ..._buildMiniParticles(rotateValue),
                // Check icon
                if (widget.isSelected)
                  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMiniParticles(double progress) {
    final particles = <Widget>[];
    final random = Random(widget.theme.id.hashCode);

    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * pi) + (i * 2 * pi / 3);
      final radius = widget.size * 0.25;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      final particleSize = 2.0 + (random.nextDouble() * 2);
      final alpha = 0.3 + (sin(progress * 2 * pi + i) * 0.2);

      particles.add(
        Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}

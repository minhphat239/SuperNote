import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiEffect extends StatefulWidget {
  final Offset origin;
  final VoidCallback? onComplete;
  final int particleCount;
  final Color? color;

  const ConfettiEffect({
    super.key,
    required this.origin,
    this.onComplete,
    this.particleCount = 20,
    this.color,
  });

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40 + _random.nextDouble() * 80;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: 2 + _random.nextDouble() * 4,
        color: widget.color ?? _randomColor(),
      ));
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  Color _randomColor() {
    final colors = [
      Colors.amber,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            origin: widget.origin,
            progress: _controller.value,
            particles: _particles,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final List<_Particle> particles;

  _ParticlePainter({
    required this.origin,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = Curves.easeOut.transform(progress);
      final dx = origin.dx + cos(p.angle) * p.speed * t;
      final dy = origin.dy + sin(p.angle) * p.speed * t + 20 * t * t;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}


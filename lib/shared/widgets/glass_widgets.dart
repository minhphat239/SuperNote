import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ===== GLASSMORPHISM CONTAINER =====
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.15,
    this.tintColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (tintColor ?? AppColors.surface).withValues(alpha: opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
              border: border ?? Border.all(
                color: AppColors.borderLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ===== PULSE GLOW (for FAB) =====
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color? color;
  final double radius;

  PulseGlow({
    super.key,
    required this.child,
    this.color,
    this.radius = 30,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.color ?? AppColors.primary).withValues(alpha: 0.3 * _anim.value),
                blurRadius: widget.radius * _anim.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

// ===== SCALE ON TAP =====
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScaleOnTap({super.key, required this.child, this.onTap, this.scale = 0.95});

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) { setState(() => _pressing = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ===== SLIDE-IN ANIMATION =====
class SlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const SlideIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 400)});

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _offsetAnim, child: widget.child),
    );
  }
}

// ===== BOUNCE CHECKMARK =====
class BounceCheck extends StatefulWidget {
  final bool isChecked;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const BounceCheck({super.key, required this.isChecked, this.color = AppColors.success, this.size = 24, this.onTap});

  @override
  State<BounceCheck> createState() => _BounceCheckState();
}

class _BounceCheckState extends State<BounceCheck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isChecked) _controller.forward();
  }

  @override
  void didUpdateWidget(BounceCheck old) {
    super.didUpdateWidget(old);
    if (widget.isChecked && !old.isChecked) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (ctx, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Icon(
            widget.isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: widget.size,
            color: widget.isChecked ? widget.color : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AiChatButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool showPulse;

  const AiChatButton({
    super.key,
    required this.onTap,
    this.showPulse = true,
  });

  @override
  State<AiChatButton> createState() => _AiChatButtonState();
}

class _AiChatButtonState extends State<AiChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    if (widget.showPulse) _rippleController.repeat();
  }

  @override
  void didUpdateWidget(AiChatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_rippleController.isAnimating) {
      _rippleController.repeat();
    } else if (!widget.showPulse && _rippleController.isAnimating) {
      _rippleController.stop();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple glow
          if (widget.showPulse)
            AnimatedBuilder(
              animation: _rippleAnim,
              builder: (ctx, child) {
                return Container(
                  width: 52 + (20 * _rippleAnim.value),
                  height: 52 + (20 * _rippleAnim.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: 0.3 * (1 - _rippleAnim.value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          // Main button
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradient.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MeshGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color> glowColors;

  const MeshGradientBackground({
    super.key,
    required this.child,
    required this.glowColors,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGlow = glowColors.isNotEmpty ? glowColors[0] : const Color(0xFFFF9F0A);
    final secondaryGlow = glowColors.length > 1 ? glowColors[1] : primaryGlow.withOpacity(0.5);

    return Container(
      color: const Color(0xFF09090B), // Nền đen chủ đạo
      child: Stack(
        children: [
          // Quầng sáng Top (Phía trên)
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGlow.withOpacity(0.22), // Opacity mờ dịu
                    primaryGlow.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Quầng sáng Bottom (Phía dưới)
          Positioned(
            bottom: -50,
            left: MediaQuery.of(context).size.width * 0.2,
            right: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryGlow.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Nội dung chính của App
          child,
        ],
      ),
    );
  }
}

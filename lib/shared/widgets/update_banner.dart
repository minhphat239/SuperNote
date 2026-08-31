import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UpdateBanner extends StatelessWidget {
  final String version;
  final VoidCallback? onUpdate;
  final VoidCallback? onDismiss;

  const UpdateBanner({super.key, required this.version, this.onUpdate, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: AppGradient.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'v$version is available',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          if (onUpdate != null)
            TextButton(
              onPressed: onUpdate,
              child: const Text('UPDATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }
}

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
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
              'Phiên bản v$version đã sẵn sàng',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          if (onUpdate != null)
            TextButton(
              onPressed: onUpdate,
              child: Text('CẬP NHẬT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.6)),
            ),
        ],
      ),
    );
  }
}

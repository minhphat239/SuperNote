import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/auto_update_service.dart';
import '../services/feedback_service.dart';

class UpdateCheckDialog extends StatefulWidget {
  final AutoUpdateService updateService;

  const UpdateCheckDialog({super.key, required this.updateService});

  @override
  State<UpdateCheckDialog> createState() => _UpdateCheckDialogState();
}

class _UpdateCheckDialogState extends State<UpdateCheckDialog> {
  bool _downloading = false;
  bool _complete = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final update = widget.updateService.pendingUpdate;
    if (update == null) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: update.isCritical
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: update.isCritical
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon + Header
                if (_complete)
                  _buildCompleteState()
                else if (_downloading)
                  _buildDownloadingState()
                else if (_error != null)
                  _buildErrorState()
                else
                  _buildAvailableState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableState() {
    final update = widget.updateService.pendingUpdate!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: update.isCritical
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.15),
            border: Border.all(
              color: update.isCritical
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            update.isCritical
                ? Icons.warning_amber_rounded
                : Icons.system_update_rounded,
            size: 28,
            color: update.isCritical ? AppColors.error : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          update.isCritical ? 'Cập nhật quan trọng!' : 'Có phiên bản mới',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: update.isCritical ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),

        // Version info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'v${widget.updateService.pendingUpdate?.version ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'v${update.version}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Release notes preview
        if (update.body.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                update.body.length > 200
                    ? '${update.body.substring(0, 200)}...'
                    : update.body,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ),
        if (update.body.isNotEmpty) const SizedBox(height: 20),

        // Asset info
        if (update.hasAsset)
          Text(
            '📦 ${update.getRecommendedAsset()?.name ?? 'Update file'}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        if (update.hasAsset) const SizedBox(height: 16),

        // Buttons
        Row(
          children: [
            Expanded(
              child: _buildBtn(
                label: 'Bỏ qua',
                color: AppColors.textMuted,
                onTap: () {
                  FeedbackService().trigger(FeedbackType.tap);
                  widget.updateService.skipVersion(update.version);
                  Navigator.pop(context, 'skip');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildBtn(
                label: 'Cập nhật ngay',
                color: update.isCritical ? AppColors.error : AppColors.primary,
                onTap: () async {
                  FeedbackService().trigger(FeedbackType.tap);
                  setState(() => _downloading = true);
                  final success = await widget.updateService.startDownload();
                  if (!mounted) return;
                  if (success) {
                    setState(() {
                      _downloading = false;
                      _complete = true;
                    });
                  } else {
                    setState(() {
                      _downloading = false;
                      _error = widget.updateService.error;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadingState() {
    final progress = widget.updateService.downloadProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Đang tải bản cập nhật...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Đừng đóng app trong khi tải nhé!',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 28,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Tải xong rồi!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          'Bấm 1 lần để cài đặt phiên bản mới',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildBtn(
                label: 'Để sau',
                color: AppColors.textMuted,
                onTap: () {
                  FeedbackService().trigger(FeedbackType.tap);
                  Navigator.pop(context, 'later');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildBtn(
                label: 'Cài đặt ngay',
                color: AppColors.success,
                onTap: () async {
                  FeedbackService().trigger(FeedbackType.tap);
                  await widget.updateService.installUpdate();
                  if (!mounted) return;
                  Navigator.pop(context, 'installing');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 28,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Tải xuống thất bại',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          _error ?? 'Lỗi không xác định',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildBtn(
                label: 'Đóng',
                color: AppColors.textMuted,
                onTap: () {
                  FeedbackService().trigger(FeedbackType.tap);
                  Navigator.pop(context, 'close');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBtn(
                label: 'Thử lại',
                color: AppColors.primary,
                onTap: () async {
                  FeedbackService().trigger(FeedbackType.tap);
                  setState(() {
                    _downloading = true;
                    _error = null;
                  });
                  final success = await widget.updateService.startDownload();
                  if (!mounted) return;
                  if (success) {
                    setState(() {
                      _downloading = false;
                      _complete = true;
                    });
                  } else {
                    setState(() {
                      _downloading = false;
                      _error = widget.updateService.error;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
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

  AppLocalizations? get _l10n => AppLocalizations.of(context);

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
    final displayText = update.changelog.isNotEmpty ? update.changelog : update.body;
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
          update.forceUpdate
              ? 'Bắt buộc cập nhật!'
              : update.isCritical
                  ? (_l10n?.updateTitle ?? 'Important Update!')
                  : (_l10n?.updateNewVersion ?? 'New version available'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: (update.forceUpdate || update.isCritical) ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Description with version
        Text(
          _l10n?.updateDescription(update.version) ?? 'A new version ${update.version} is available.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Release notes preview
        if (displayText.isNotEmpty)
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
                displayText.length > 200
                    ? '${displayText.substring(0, 200)}...'
                    : displayText,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ),
        if (displayText.isNotEmpty) const SizedBox(height: 20),

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
            if (!update.forceUpdate) ...[
              Expanded(
                child: _buildBtn(
                  label: 'Để sau',
                  color: AppColors.textMuted,
                  onTap: () {
                    FeedbackService().trigger(FeedbackType.tap);
                    Navigator.pop(context, 'dismiss');
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: update.forceUpdate ? 1 : 2,
              child: _buildBtn(
                label: _l10n?.updateNow ?? 'Cập nhật',
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
        SizedBox(
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
          _l10n?.updateDownloading ?? 'Downloading update...',
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
          _l10n?.updateDontClose ?? "Don't close the app while downloading!",
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
          child: Icon(
            Icons.check_circle_rounded,
            size: 28,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          _l10n?.updateReady ?? 'Download complete!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          _l10n?.updateInstallHint ?? 'Tap once to install the new version',
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
                label: _l10n?.updateLater ?? 'Later',
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
                label: _l10n?.updateInstall ?? 'Install now',
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
          child: Icon(
            Icons.error_outline_rounded,
            size: 28,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          _l10n?.updateFailed ?? 'Download failed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 4),

        Text(
          _error ?? (_l10n?.updateUnknownError ?? 'Unknown error'),
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
                label: _l10n?.updateClose ?? 'Close',
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
                label: _l10n?.updateRetry ?? 'Retry',
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

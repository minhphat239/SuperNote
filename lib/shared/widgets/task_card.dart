import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'glass_widgets.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? categoryColor;
  final bool isDone;
  final bool isOverdue;
  final bool hasNote;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;
  final Widget? trailing;

  const TaskCard({
    super.key,
    required this.title,
    this.subtitle = '',
    this.categoryColor,
    this.isDone = false,
    this.isOverdue = false,
    this.hasNote = false,
    this.onTap,
    this.onToggle,
    this.onDelete,
    this.onSnooze,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 2),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: AppColors.splash,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: BounceCheck(
                      isChecked: isDone,
                      color: AppColors.success,
                      size: 24,
                      onTap: onToggle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppColors.textMuted
                              : (isOverdue
                                  ? AppColors.error
                                  : AppColors.textPrimary),
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          height: 1.3,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasNote && !isDone)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.note_alt_outlined,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.6)),
                  ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: trailing,
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg)),
                  color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 3),
                  onSelected: (v) {
                    if (v == 'snooze') onSnooze?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (!isDone)
                      PopupMenuItem(
                          value: 'snooze',
                          child: Row(children: [
                            Icon(Icons.snooze_rounded,
                                size: 18, color: AppColors.orange),
                            const SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.snooze),
                          ])),
                    PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text(AppLocalizations.of(context)!.delete,
                              style:
                                  TextStyle(color: AppColors.error)),
                        ])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

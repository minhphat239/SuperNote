import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'glass_widgets.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color categoryColor;
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
    this.categoryColor = AppColors.primary,
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
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: AppColors.splash,
          highlightColor: Colors.transparent,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Bounce check
                BounceCheck(
                  isChecked: isDone,
                  color: AppColors.success,
                  size: 22,
                  onTap: onToggle,
                ),
                const SizedBox(width: 12),

                // Title + subtitle
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
                              color:
                                  AppColors.textMuted.withOpacity(0.7),
                              height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),

                // Note icon indicator
                if (hasNote && !isDone)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.note_alt_outlined,
                        size: 14,
                        color: AppColors.primary.withOpacity(0.6)),
                  ),

                // More menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textMuted.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md)),
                  color: AppColors.surfaceLight,
                  onSelected: (v) {
                    if (v == 'snooze') onSnooze?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (!isDone)
                      const PopupMenuItem(
                          value: 'snooze',
                          child: Row(children: [
                            Icon(Icons.snooze_rounded,
                                size: 18, color: AppColors.orange),
                            SizedBox(width: 10),
                            Text('Snooze'),
                          ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text('Delete',
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

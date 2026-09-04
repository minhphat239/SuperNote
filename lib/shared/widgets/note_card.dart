import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String content;
  final String timeLabel;
  final List<String> tags;
  final Color? accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.title,
    required this.content,
    required this.timeLabel,
    this.tags = const [],
    this.accentColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Skip rendering if title is empty (hidden empty notes)
    if (title.trim().isEmpty && content.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 2.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.splash,
          highlightColor: Colors.white.withValues(alpha: 0.03),
          hoverColor: Colors.white.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category accent strip
                if (accentColor != null) ...[
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: accentColor!.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: -1)],
                    ),
                  ),
                ],

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),

                      // Content preview
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                        ),
                      ],

                      // Tags + time
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (tags.isNotEmpty) ...[
                            ...tags.take(3).map((tag) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _getTagColor(tag).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: _getTagColor(tag).withValues(alpha: 0.2)),
                              ),
                              child: Text('#$tag', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _getTagColor(tag))),
                            )),
                            const SizedBox(width: 4),
                          ],
                          Icon(Icons.access_time_rounded, size: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(timeLabel, style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('work') || lower.contains('cv') || lower.contains('việc')) return AppColors.blue;
    if (lower.contains('study') || lower.contains('hoc') || lower.contains('học')) return AppColors.green;
    if (lower.contains('exam') || lower.contains('thi')) return AppColors.red;
    if (lower.contains('personal') || lower.contains('canhan')) return AppColors.purple;
    return AppColors.teal;
  }
}

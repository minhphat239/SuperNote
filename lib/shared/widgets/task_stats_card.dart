import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskStatsCard extends StatefulWidget {
  final TaskService taskService;

  const TaskStatsCard({super.key, required this.taskService});

  @override
  State<TaskStatsCard> createState() => _TaskStatsCardState();
}

class _TaskStatsCardState extends State<TaskStatsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final allTasks = widget.taskService.tasks;
    final total = allTasks.length;
    final pending = widget.taskService.pendingTasks.length;
    final done = widget.taskService.completedTasks.length;
    final overdue = allTasks.where((t) => t.isOverdue).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact summary row (always visible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Tổng $total · Đang chờ $pending · Hoàn thành $done',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  if (overdue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Quá hạn $overdue',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(allTasks, total),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(List<Task> allTasks, int total) {
    final classCount =
        allTasks.where((t) => t.category == TaskCategory.class_).length;
    final examCount =
        allTasks.where((t) => t.category == TaskCategory.exam).length;
    final assignmentCount =
        allTasks.where((t) => t.category == TaskCategory.assignment).length;
    final personalCount =
        allTasks.where((t) => t.category == TaskCategory.personal).length;

    final maxCategory = [
      classCount,
      examCount,
      assignmentCount,
      personalCount
    ].reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Stat items row
          Row(
            children: [
              _buildStatItem(
                  label: 'Tổng', count: total, icon: Icons.list_rounded),
              _buildStatItem(
                  label: 'Chờ', count: total - classCount - examCount - assignmentCount - personalCount, icon: Icons.pending_actions_rounded),
              _buildStatItem(
                  label: 'Xong',
                  count: allTasks.where((t) => t.isDone).length,
                  icon: Icons.check_circle_outline_rounded),
              _buildStatItem(
                  label: 'Quá hạn',
                  count: allTasks.where((t) => t.isOverdue).length,
                  icon: Icons.warning_amber_rounded),
            ],
          ),

          if (maxCategory > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Phân loại',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryBar(
                label: 'Lớp học',
                count: classCount,
                total: total,
                color: TaskCategory.class_.color,
                maxCount: maxCategory),
            const SizedBox(height: 4),
            _buildCategoryBar(
                label: 'Kỳ thi',
                count: examCount,
                total: total,
                color: TaskCategory.exam.color,
                maxCount: maxCategory),
            const SizedBox(height: 4),
            _buildCategoryBar(
                label: 'Bài tập',
                count: assignmentCount,
                total: total,
                color: TaskCategory.assignment.color,
                maxCount: maxCategory),
            const SizedBox(height: 4),
            _buildCategoryBar(
                label: 'Cá nhân',
                count: personalCount,
                total: total,
                color: TaskCategory.personal.color,
                maxCount: maxCategory),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar({
    required String label,
    required int count,
    required int total,
    required Color color,
    required int maxCount,
  }) {
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    final percentage = total > 0 ? ((count / total) * 100).round() : 0;

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$count ($percentage%)',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/nlp_dual_stage.dart';
import '../widgets/glass_widgets.dart';

class NlpInputBar extends StatefulWidget {
  final Function(DualStageResult) onSubmit;
  final String hintText;

  const NlpInputBar({super.key, required this.onSubmit, this.hintText = 'Add a task...'});

  @override
  State<NlpInputBar> createState() => _NlpInputBarState();
}

class _NlpInputBarState extends State<NlpInputBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DualStageResult? _preview;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _preview = value.trim().isEmpty ? null : NlpDualStageParser.parse(value);
    });
  }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    final result = NlpDualStageParser.parse(_ctrl.text);
    widget.onSubmit(result);
    _ctrl.clear();
    setState(() => _preview = null);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input row
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: AppColors.textMuted.withOpacity(0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 13.5, height: 1.4),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      gradient: AppGradient.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Dual-stage preview chips
          if (_preview != null && _preview!.hasTime) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _buildDualStagePreview(_preview!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDualStagePreview(DualStageResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intent badge
        Row(
          children: [
            _intentBadge(result.intent),
            if (result.targetTime != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted.withOpacity(0.6)),
              const SizedBox(width: 3),
              Text(
                _formatDateTime(result.targetTime!),
                style: TextStyle(fontSize: 11, color: AppColors.textMuted.withOpacity(0.7)),
              ),
            ],
            if (result.tags.isNotEmpty) ...[
              const SizedBox(width: 6),
              ...result.tags.take(2).map((t) => _miniTag(t)),
            ],
          ],
        ),

        // Dual-stage reminder chips
        if (result.hasStage1 || result.hasStage2) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (result.hasStage1)
                _reminderChip(
                  icon: Icons.notifications_active_rounded,
                  time: result.stage1Time!,
                  label: result.stage1Label,
                  color: AppColors.orange,
                ),
              if (result.hasStage1 && result.hasStage2) ...[
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted.withOpacity(0.4)),
                const SizedBox(width: 6),
              ],
              if (result.hasStage2)
                _reminderChip(
                  icon: result.intent == TaskIntent.event ? Icons.event_rounded : Icons.flag_rounded,
                  time: result.stage2Time!,
                  label: result.stage2Label,
                  color: result.intent == TaskIntent.event ? AppColors.primary : AppColors.error,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _intentBadge(TaskIntent intent) {
    String label;
    IconData icon;
    Color color;

    switch (intent) {
      case TaskIntent.event:
        label = 'Sự kiện';
        icon = Icons.event_rounded;
        color = AppColors.primary;
        break;
      case TaskIntent.deadline:
        label = 'Deadline';
        icon = Icons.flag_rounded;
        color = AppColors.error;
        break;
      case TaskIntent.reminder:
        label = 'Nhắc nhở';
        icon = Icons.notifications_rounded;
        color = AppColors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _reminderChip({
    required IconData icon,
    required DateTime time,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _miniTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text('#$tag', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.purple)),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    String dateStr = '';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      dateStr = 'Hôm nay';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
      dateStr = 'Ngày mai';
    } else {
      dateStr = '${dt.day}/${dt.month}';
    }
    return '$dateStr ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskEditorScreen extends StatefulWidget {
  final TaskService taskService;
  final Task? task; // null = create new, non-null = edit existing

  const TaskEditorScreen({super.key, required this.taskService, this.task});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late TaskCategory _category;
  DateTime? _dueDate;
  DateTime? _dueTime;
  String? _repeatRule;
  DateTime? _repeatEndDate;
  Set<int> _weeklyDays = {}; // 1=Mon..7=Sun
  int? _preReminderOffset;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task != null;
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _category = widget.task?.category ?? TaskCategory.personal;
    _dueDate = widget.task?.dueDate;
    _dueTime = widget.task?.dueTime;
    _repeatRule = widget.task?.repeatRule;
    _repeatEndDate = widget.task?.repeatEndDate;
    _preReminderOffset = widget.task?.preReminderOffset;
    _parseWeeklyDays();
  }

  void _parseWeeklyDays() {
    if (_repeatRule != null && _repeatRule!.startsWith('weekly:')) {
      final daysStr = _repeatRule!.substring(7);
      _weeklyDays = daysStr.split(',').map(int.parse).toSet();
    } else {
      _weeklyDays = {};
    }
  }

  String? _buildRepeatRule() {
    if (_repeatRule == null) return null;
    if (_repeatRule == 'weekly' && _weeklyDays.isNotEmpty) {
      final sorted = _weeklyDays.toList()..sort();
      return 'weekly:${sorted.join(',')}';
    }
    return _repeatRule;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ===== SAVE =====
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    if (_isEditing) {
      await widget.taskService.updateTask(
        widget.task!.id,
        title: title,
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        dueTime: _dueTime,
        category: _category,
        repeatRule: _buildRepeatRule(),
        repeatEndDate: _repeatEndDate,
        preReminderOffset: _preReminderOffset,
      );
    } else {
      await widget.taskService.addTask(
        title: title,
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        dueTime: _dueTime,
        category: _category,
        repeatRule: _buildRepeatRule(),
        repeatEndDate: _repeatEndDate,
        preReminderOffset: _preReminderOffset,
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  // ===== DATE PICKER =====
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  // ===== TIME PICKER =====
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime != null
          ? TimeOfDay(hour: _dueTime!.hour, minute: _dueTime!.minute)
          : TimeOfDay.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueTime = DateTime(2000, 1, 1, picked.hour, picked.minute));
    }
  }

  // ===== DELETE =====
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete Task'),
        content: Text('Delete "${_titleCtrl.text}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && _isEditing) {
      await widget.taskService.deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ===== TITLE =====
            _buildLabel('Title'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: _inputDecoration('What needs to be done?'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ===== DESCRIPTION =====
            _buildLabel('Description (optional)'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              decoration: _inputDecoration('Add details...'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ===== CATEGORY =====
            _buildLabel('Category'),
            const SizedBox(height: AppSpacing.sm),
            _buildCategoryPicker(),
            const SizedBox(height: AppSpacing.xl),

            // ===== DATE =====
            _buildLabel('Due Date'),
            const SizedBox(height: AppSpacing.sm),
            _buildDateRow(),
            const SizedBox(height: AppSpacing.xl),

            // ===== TIME =====
            _buildLabel('Due Time'),
            const SizedBox(height: AppSpacing.sm),
            _buildTimeRow(),
            const SizedBox(height: AppSpacing.xl),

            // ===== REPEAT =====
            _buildLabel('Repeat'),
            const SizedBox(height: AppSpacing.sm),
            _buildRepeatPicker(),
            const SizedBox(height: AppSpacing.xl),

            // ===== PRE-REMINDER =====
            _buildLabel('Remind Me'),
            const SizedBox(height: AppSpacing.sm),
            _buildPreReminderPicker(),
            const SizedBox(height: AppSpacing.xxl),

            // ===== DELETE BUTTON (edit mode only) =====
            if (_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _delete,
                  child: const Text('Delete Task', style: TextStyle(color: AppColors.red, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  // ===== CATEGORY PICKER =====
  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TaskCategory.values.map((cat) {
        final selected = _category == cat;
        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cat.color.withOpacity(0.15) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: selected ? cat.color : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(cat.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? cat.color : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== DATE ROW =====
  Widget _buildDateRow() {
    final now = DateTime.now();
    String dateLabel;
    if (_dueDate == null) {
      dateLabel = 'No date set';
    } else if (_dueDate!.year == now.year && _dueDate!.month == now.month && _dueDate!.day == now.day) {
      dateLabel = 'Today';
    } else if (_dueDate!.year == now.year && _dueDate!.month == now.month && _dueDate!.day == now.day + 1) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEE, MMM d, yyyy').format(_dueDate!);
    }

    return Row(
      children: [
        Expanded(
          child: _buildOptionTile(
            icon: Icons.calendar_today_rounded,
            label: dateLabel,
            color: _dueDate != null ? AppColors.primary : AppColors.textMuted,
            onTap: _pickDate,
          ),
        ),
        if (_dueDate != null) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _dueDate = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
            ),
          ),
        ],
      ],
    );
  }

  // ===== TIME ROW =====
  Widget _buildTimeRow() {
    String timeLabel;
    if (_dueTime == null) {
      timeLabel = 'No time set';
    } else {
      timeLabel = '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        Expanded(
          child: _buildOptionTile(
            icon: Icons.schedule_rounded,
            label: timeLabel,
            color: _dueTime != null ? AppColors.green : AppColors.textMuted,
            onTap: _pickTime,
          ),
        ),
        if (_dueTime != null) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _dueTime = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
            ),
          ),
        ],
      ],
    );
  }

  // ===== REPEAT PICKER =====
  Widget _buildRepeatPicker() {
    final options = [
      {'label': 'None', 'value': null, 'icon': Icons.repeat_rounded},
      {'label': 'Daily', 'value': 'daily', 'icon': Icons.today_rounded},
      {'label': 'Weekly', 'value': 'weekly', 'icon': Icons.view_week_rounded},
      {'label': 'Monthly', 'value': 'monthly', 'icon': Icons.date_range_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((opt) {
            final selected = _repeatRule == opt['value'];
            return GestureDetector(
              onTap: () => setState(() {
                _repeatRule = opt['value'] as String?;
                if (_repeatRule == 'weekly' && _weeklyDays.isEmpty) {
                  // Default: select current weekday
                  _weeklyDays = {DateTime.now().weekday};
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.purple.withOpacity(0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: selected ? AppColors.purple : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt['icon'] as IconData, size: 14, color: selected ? AppColors.purple : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(opt['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppColors.purple : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Weekly day picker
        if (_repeatRule == 'weekly') ...[
          const SizedBox(height: AppSpacing.md),
          _buildWeekdaySelector(),
        ],

        // Repeat end date
        if (_repeatRule != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildRepeatEndDateRow(),
        ],
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayNum = i + 1; // 1=Mon..7=Sun
        final selected = _weeklyDays.contains(dayNum);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _weeklyDays.remove(dayNum);
            } else {
              _weeklyDays.add(dayNum);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: selected ? AppColors.purple : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: selected ? AppColors.purple : AppColors.border),
            ),
            child: Center(
              child: Text(
                days[i].substring(0, 1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRepeatEndDateRow() {
    String label;
    if (_repeatEndDate == null) {
      label = 'No end date';
    } else {
      label = 'Until ${DateFormat('MMM d, yyyy').format(_repeatEndDate!)}';
    }

    return Row(
      children: [
        Expanded(
          child: _buildOptionTile(
            icon: Icons.event_repeat_rounded,
            label: label,
            color: _repeatEndDate != null ? AppColors.purple : AppColors.textMuted,
            onTap: _pickRepeatEndDate,
          ),
        ),
        if (_repeatEndDate != null) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _repeatEndDate = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickRepeatEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _repeatEndDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.purple),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _repeatEndDate = picked);
  }

  // ===== PRE-REMINDER PICKER =====
  Widget _buildPreReminderPicker() {
    final options = [
      {'label': 'None', 'value': null},
      {'label': 'At time', 'value': 0},
      {'label': '10 min', 'value': 10},
      {'label': '30 min', 'value': 30},
      {'label': '1 hr', 'value': 60},
      {'label': '1 day', 'value': 1440},
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((opt) {
        final selected = _preReminderOffset == opt['value'];
        return GestureDetector(
          onTap: () => setState(() => _preReminderOffset = opt['value'] as int?),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.teal.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: selected ? AppColors.teal : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_rounded, size: 13, color: selected ? AppColors.teal : AppColors.textMuted),
                const SizedBox(width: 4),
                Text(opt['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppColors.teal : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== OPTION TILE (reusable) =====
  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

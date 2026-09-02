import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;
  final NoteService noteService;

  const NoteEditorScreen({super.key, required this.note, required this.noteService});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _hasChanges = false;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);

    // Auto-focus title if empty, else content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.note.title.isEmpty) {
        _titleFocus.requestFocus();
      }
    });
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Auto-delete empty notes
    if (title.isEmpty && content.isEmpty) {
      await widget.noteService.deleteNote(widget.note.noteId);
      if (mounted) Navigator.pop(context, true);
      return;
    }

    await widget.noteService.updateNote(
      widget.note.noteId,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    // Auto-save if content exists
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isNotEmpty || content.isNotEmpty) {
      await _save();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.pop(context, false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ===== TOP BAR (Minimal) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () async {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted) Navigator.pop(context, false);
                      },
                    ),
                    const Spacer(),
                    if (_hasChanges)
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppGradient.primary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    if (!_hasChanges)
                      Icon(Icons.check_rounded, size: 18, color: AppColors.success.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              // ===== BORDERLESS CANVAS =====
              Expanded(
                child: GestureDetector(
                  onTap: () => _contentFocus.requestFocus(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title - 22px bold, no border
                        TextField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Untitled',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.3),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (_) => _onChanged(),
                        ),

                        const SizedBox(height: 4),

                        // Timestamp
                        Text(
                          _formatTimestamp(widget.note.updatedAt),
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        ),

                        const SizedBox(height: 16),

                        // Content - borderless, fill remaining height
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.7,
                            ),
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Start writing...\n\nNo borders. No limits. Just your thoughts.',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.25),
                                fontSize: 15,
                                height: 1.7,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => _onChanged(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== BOTTOM TOOLBAR (Minimal) =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text('${_contentController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.4))),
                    const Spacer(),
                    Text(_formatTimestamp(widget.note.updatedAt),
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

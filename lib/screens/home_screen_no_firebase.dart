import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';
import '../models/update_info.dart';
import '../shared/widgets/note_card.dart';
import '../shared/widgets/glass_widgets.dart';
import 'note_editor_screen.dart';

class HomeScreenNoFirebase extends StatefulWidget {
  final NoteService noteService;
  final SyncService syncService;

  const HomeScreenNoFirebase({super.key, required this.noteService, required this.syncService});

  @override
  State<HomeScreenNoFirebase> createState() => _HomeScreenNoFirebaseState();
}

class _HomeScreenNoFirebaseState extends State<HomeScreenNoFirebase> {
  List<Note> _notes = [];
  bool _isLoading = true;
  UpdateInfo? _updateInfo;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _checkForUpdate();
  }

  Future<void> _loadNotes() async {
    final notes = await widget.noteService.getAllNotes();
    if (mounted) setState(() { _notes = notes; _isLoading = false; });
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (mounted) setState(() { _updateInfo = update; _showBanner = update != null; });
  }

  void _quickAdd(String input) async {
    if (input.trim().isEmpty) return;
    await widget.noteService.createNote(title: input.trim());
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Added: ${input.trim()}', style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _createNote() async {
    final note = await widget.noteService.createNote();
    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note, noteService: widget.noteService)),
      );
      if (result == true) _loadNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note, noteService: widget.noteService)),
    );
    if (result == true) _loadNotes();
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        backgroundColor: AppColors.surface,
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) { await widget.noteService.deleteNote(note.noteId); _loadNotes(); }
  }

  List<String> _extractTags(Note note) {
    final tagPattern = RegExp(r'#([\w-]+)');
    final allText = '${note.title} ${note.content}';
    final tags = <String>[];
    for (final m in tagPattern.allMatches(allText)) {
      final tag = m.group(1)!;
      if (!tags.contains(tag)) tags.add(tag);
    }
    return tags.take(3).toList();
  }

  // Filter out empty/untitled notes
  List<Note> get _validNotes => _notes.where((n) => n.title.trim().isNotEmpty || n.content.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final validNotes = _validNotes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: AppGradient.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.note_alt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('SuperNote', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary, letterSpacing: -0.3)),
              ],
            ),
            actions: [
              // New note button (gradient)
              GestureDetector(
                onTap: _createNote,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    gradient: AppGradient.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                ),
              ),
              IconButton(icon: const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary), onPressed: () {}),
              const SizedBox(width: 4),
            ],
          ),

          // Slim Update Banner
          if (_showBanner && _updateInfo != null)
            SliverToBoxAdapter(child: _buildSlimBanner()),

          // Quick Input Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildQuickInput(),
            ),
          ),

          // Notes list or Empty state with Daily Summary
          _isLoading
              ? SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
              : validNotes.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyWithSummary())
                  : SliverPadding(
                      padding: const EdgeInsets.only(bottom: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => SlideIn(
                            delay: Duration(milliseconds: i * 40),
                            child: NoteCard(
                              title: validNotes[i].title,
                              content: validNotes[i].content,
                              timeLabel: _formatTime(validNotes[i].updatedAt),
                              tags: _extractTags(validNotes[i]),
                              accentColor: _getCategoryColor(validNotes[i]),
                              onTap: () => _editNote(validNotes[i]),
                              onLongPress: () => _deleteNote(validNotes[i]),
                            ),
                          ),
                          childCount: validNotes.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // ===== SLIM UPDATE BANNER =====
  Widget _buildSlimBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'v${_updateInfo!.version} available',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ),
          GestureDetector(
            onTap: () => UpdateService.openUpdatePage(),
            child: Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showBanner = false),
            child: Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  // ===== QUICK INPUT BAR =====
  Widget _buildQuickInput() {
    final ctrl = TextEditingController();
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Thêm ghi chú nhanh...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 13.5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onSubmitted: (v) { _quickAdd(v); ctrl.clear(); },
              textInputAction: TextInputAction.send,
            ),
          ),
          GestureDetector(
            onTap: () { _quickAdd(ctrl.text); ctrl.clear(); },
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: AppGradient.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ===== EMPTY STATE WITH DAILY SUMMARY =====
  Widget _buildEmptyWithSummary() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppGradient.primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: -4)],
            ),
            child: const Icon(Icons.note_add_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('No notes yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Type above to create your first note', style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.5))),

          // Daily Summary Widget (fills empty space)
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(Note note) {
    final allText = '${note.title} ${note.content}'.toLowerCase();
    if (allText.contains('exam') || allText.contains('thi')) return AppColors.red;
    if (allText.contains('assignment') || allText.contains('homework')) return AppColors.orange;
    if (allText.contains('class') || allText.contains('lecture')) return AppColors.blue;
    return AppColors.green;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return DateFormat('MMM d').format(dt);
  }
}

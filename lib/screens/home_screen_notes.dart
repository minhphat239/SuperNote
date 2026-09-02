import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../models/update_info.dart';
import '../services/note_service.dart';
import '../services/sync_service.dart';
import '../services/update_service.dart';
import '../services/auth_service.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final NoteService noteService;
  final SyncService syncService;
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _updateSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _checkForUpdate();
    widget.syncService.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    widget.syncService.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!widget.syncService.isSyncing) {
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    final notes = await widget.noteService.getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateSuccess = false;
    });

    final update = await UpdateService.checkForUpdate();

    if (!mounted) return;
    setState(() {
      _updateInfo = update;
      _isCheckingUpdate = false;
    });
  }

  Future<void> _handleUpdate() async {
    if (_updateInfo == null) return;

    if (UpdateService.isAndroid) {
      await UpdateService.openUpdatePage();
    } else if (UpdateService.isLinux && _updateInfo!.hasDownloadUrl) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      final success = await UpdateService.downloadUpdate(
        _updateInfo!.downloadUrl,
        _updateInfo!.assetName,
        (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _updateSuccess = success;
        if (success) _updateInfo = null;
      });
    }
  }

  Future<void> _skipVersion() async {
    if (_updateInfo != null) {
      await UpdateService.skipVersion(_updateInfo!.version);
      if (!mounted) return;
      setState(() => _updateInfo = null);
    }
  }

  Future<void> _createNote() async {
    final note = await widget.noteService.createNote();
    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(
            note: note,
            noteService: widget.noteService,
          ),
        ),
      );
      if (result == true) {
        _loadNotes();
        widget.syncService.sync();
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          noteService: widget.noteService,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadNotes();
      widget.syncService.sync();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.noteService.deleteNote(note.noteId);
      if (!mounted) return;
      _loadNotes();
      widget.syncService.sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperNote'),
        actions: [
          ListenableBuilder(
            listenable: widget.syncService,
            builder: (context, _) {
              return Row(
                children: [
                  if (widget.syncService.isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      widget.syncService.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: widget.syncService.isOnline ? Colors.green : Colors.orange,
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () => widget.syncService.sync(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await widget.authService.signOut();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUpdateBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_add, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first note',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await widget.syncService.sync();
                          await _loadNotes();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return _buildNoteCard(note);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUpdateBanner() {
    if (_isCheckingUpdate) {
      return const SizedBox.shrink();
    }

    if (_updateSuccess) {
      return Material(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Successfully Updated!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _checkForUpdate,
                child: const Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_updateInfo != null) {
      return Material(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New version available!',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'v${_updateInfo!.version}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_isDownloading) ...[
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(value: _downloadProgress),
                ),
                const SizedBox(width: 8),
                Text('${(_downloadProgress * 100).toInt()}%'),
              ] else ...[
                TextButton(
                  onPressed: _skipVersion,
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: _handleUpdate,
                  child: const Text('Update'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          note.title.isEmpty ? 'Untitled' : note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          note.content.isEmpty ? 'No content' : note.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              note.isSynced ? Icons.cloud_done : Icons.cloud_upload,
              size: 16,
              color: note.isSynced ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMM d, HH:mm').format(note.updatedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => _editNote(note),
        onLongPress: () => _deleteNote(note),
      ),
    );
  }
}

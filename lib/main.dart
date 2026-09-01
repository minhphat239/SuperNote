import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/note_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/gemini_service.dart';
import 'screens/task_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'shared/widgets/glass_widgets.dart';

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<void> _bootstrapDesktop() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(420, 800),
    minimumSize: Size(360, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
    title: 'SuperNote',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(false);
    await windowManager.show();
    await windowManager.focus();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager is NOT supported on Android/iOS — calling it there
  // throws MissingPluginException and leaves the screen black.
  if (isDesktopPlatform) {
    await _bootstrapDesktop();
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0E0F1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final storageService = StorageService();
  await storageService.init();

  final authService = AuthService();
  final noteService = NoteService(storageService, authService);
  final syncService = SyncService(noteService);
  final taskService = TaskService();
  final geminiService = GeminiService();

  runApp(SuperNoteApp(
    noteService: noteService,
    syncService: syncService,
    taskService: taskService,
    authService: authService,
    geminiService: geminiService,
  ));
}

class SuperNoteApp extends StatelessWidget {
  final NoteService noteService;
  final SyncService syncService;
  final TaskService taskService;
  final AuthService authService;
  final GeminiService geminiService;

  const SuperNoteApp({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MainShell(
        noteService: noteService,
        syncService: syncService,
        taskService: taskService,
        authService: authService,
        geminiService: geminiService,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final NoteService noteService;
  final SyncService syncService;
  final TaskService taskService;
  final AuthService authService;
  final GeminiService geminiService;

  const MainShell({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TaskScreen(taskService: widget.taskService),
      CalendarScreen(taskService: widget.taskService),
      SettingsScreen(
        authService: widget.authService,
        geminiService: widget.geminiService,
      ),
    ];
  }

  void _onNavTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopPlatform;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ===== CUSTOM TITLE BAR (desktop only) =====
          if (desktop)
            GestureDetector(
              onDoubleTap: () async {
                final isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: Container(
                  height: 32,
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: DragToMoveArea(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    gradient: AppGradient.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.task_alt_rounded,
                                      size: 8, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Text('SuperNote',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted
                                            .withOpacity(0.6))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const WindowControls(),
                    ],
                  ),
                ),
              ),
            ),

          // ===== MAIN CONTENT =====
          Expanded(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ),

          // ===== BOTTOM NAVIGATION (3 tabs: Tasks, Calendar, Settings) =====
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onNavTap,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.task_alt_outlined, size: 22),
                    selectedIcon: Icon(Icons.task_alt_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_today_outlined, size: 22),
                    selectedIcon: Icon(Icons.calendar_today_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined, size: 22),
                    selectedIcon: Icon(Icons.settings_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== WINDOW CONTROLS =====
class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.minimize_rounded,
          onTap: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: Icons.crop_square_rounded,
          onTap: () async {
            final isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icons.close_rounded,
          isClose: true,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton(
      {required this.icon, required this.onTap, this.isClose = false});

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: 32,
          color: _hovering
              ? (widget.isClose
                  ? AppColors.error
                  : Colors.white.withOpacity(0.08))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovering && widget.isClose
                ? Colors.white
                : AppColors.textMuted.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

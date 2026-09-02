import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/note_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/gemini_service.dart';
import 'services/theme_service.dart';
import 'services/auto_update_service.dart';
import 'services/feedback_service.dart';
import 'services/firestore_repository.dart';
import 'services/ai_parser_service.dart';
import 'screens/auth_screen.dart';
import 'screens/task_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/update_check_dialog.dart';
import 'shared/widgets/ai_chat_button.dart';
import 'shared/widgets/ai_chat_panel.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('vi', null);

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

  final authService = AuthService();
  final storageService = StorageService(authService: authService);
  await storageService.init();

  final noteService = NoteService(storageService);
  final syncService = SyncService(noteService);
  final taskService = TaskService(authService: authService);
  await taskService.init();

  final geminiService = GeminiService();
  await geminiService.init();

  final themeService = ThemeService();
  await themeService.init();

  final updateService = AutoUpdateService();

  // ===== BACKEND SERVICES =====
  try {
    await FirestoreRepository().init();
  } catch (_) {
    // Firestore may not be available — app continues with local-only mode
  }

  try {
    await FeedbackService().init();
  } catch (_) {}

  try {
    await AiParserService().init();
  } catch (_) {}

  // Listen to auth changes → reload per-user data
  authService.authStateChanges.listen((isLoggedIn) async {
    final userId = isLoggedIn ? authService.userId : null;
    await storageService.reloadForUser(userId);
    await taskService.reloadForUser(userId);
  });

  runApp(SuperNoteApp(
    noteService: noteService,
    syncService: syncService,
    taskService: taskService,
    authService: authService,
    geminiService: geminiService,
    themeService: themeService,
    updateService: updateService,
  ));
}

class SuperNoteApp extends StatelessWidget {
  final NoteService noteService;
  final SyncService syncService;
  final TaskService taskService;
  final AuthService authService;
  final GeminiService geminiService;
  final ThemeService themeService;
  final AutoUpdateService updateService;

  const SuperNoteApp({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
    required this.themeService,
    required this.updateService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'SuperNote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final user = snapshot.data;

              if (user != null) {
                return MainShell(
                  noteService: noteService,
                  syncService: syncService,
                  taskService: taskService,
                  authService: authService,
                  geminiService: geminiService,
                  themeService: themeService,
                  updateService: updateService,
                );
              }

              return AuthScreen(
                authService: authService,
                themeService: themeService,
              );
            },
          ),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final NoteService noteService;
  final SyncService syncService;
  final TaskService taskService;
  final AuthService authService;
  final GeminiService geminiService;
  final ThemeService themeService;
  final AutoUpdateService updateService;

  const MainShell({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
    required this.themeService,
    required this.updateService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<int> _tabHistory = [0];
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TaskScreen(taskService: widget.taskService),
      CalendarScreen(taskService: widget.taskService),
      TimelineScreen(taskService: widget.taskService),
      SettingsScreen(
        authService: widget.authService,
        geminiService: widget.geminiService,
        themeService: widget.themeService,
      ),
    ];

    // Auto-check for updates after app renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final shouldCheck = await widget.updateService.shouldAutoCheck();
      if (!shouldCheck) return;

      final update = await widget.updateService.checkForUpdate();
      await widget.updateService.markChecked();

      if (update != null && mounted) {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateCheckDialog(updateService: widget.updateService),
        );
        if (result == 'skip' || result == 'later') {
          widget.updateService.clearPendingUpdate();
        }
      }
    } catch (e) {
      // Update check must never break the app
    }
  }

  Widget _buildNeonOrb(double size, Color color, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.15,
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopPlatform;
    return PopScope(
      canPop: _tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _currentIndex = _tabHistory.last;
          });
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      body: Stack(
        children: [
          // ===== NEON GLOW ORBS (behind all content for glassmorphism) =====
          Positioned(
            top: -80,
            left: -80,
            child: _buildNeonOrb(250, const Color(0xFF6366F1), 0.3),
          ),
          Positioned(
            bottom: 120,
            right: -80,
            child: _buildNeonOrb(300, const Color(0xFFEC4899), 0.2),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.25,
            child: _buildNeonOrb(200, const Color(0xFFF59E0B), 0.15),
          ),

          // ===== MAIN CONTENT =====
          Column(
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
                                                .withValues(alpha: 0.6))),
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
                  decoration: BoxDecoration(
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
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.task_alt_outlined, size: 22),
                    selectedIcon: Icon(Icons.task_alt_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.calendar_today_outlined, size: 22),
                    selectedIcon: Icon(Icons.calendar_today_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.view_timeline_outlined, size: 22),
                    selectedIcon: Icon(Icons.view_timeline_rounded,
                        size: 22, color: AppColors.primary),
                    label: 'Timeline',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings_outlined, size: 22),
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

          // ===== AI CHAT BUTTON (floating, mobile only, hidden on Settings) =====
          if (!desktop && _currentIndex != 3)
            Positioned(
              bottom: 80,
              right: 16,
              child: AiChatButton(
                onTap: () => AiChatPanel.show(
                    context, widget.geminiService, widget.taskService),
              ),
            ),
        ],
      ),
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
                  : Colors.white.withValues(alpha: 0.08))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovering && widget.isClose
                ? Colors.white
                : AppColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

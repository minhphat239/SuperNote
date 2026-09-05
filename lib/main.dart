import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/startup_log.dart';
import 'l10n/app_localizations.dart';
import 'services/language_service.dart';
import 'services/storage_service.dart';
import 'services/note_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/gemini_service.dart';
import 'services/theme_service.dart';
import 'services/auto_update_service.dart';
import 'services/feedback_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_repository.dart';
import 'services/ai_parser_service.dart';
import 'services/custom_background_service.dart';
import 'services/inactivity_retention_service.dart';
import 'services/fcm_service.dart';
import 'screens/auth_screen.dart';
import 'screens/task_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/update_check_dialog.dart';
import 'shared/widgets/ai_chat_panel.dart';
import 'shared/widgets/theme_video_background.dart';
import 'shared/widgets/custom_background_widget.dart';
import 'shared/widgets/cyberpunk_background.dart';

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
  // Write raw log BEFORE Flutter init — catches crashes during binding setup
  _rawLog('main() called');
  WidgetsFlutterBinding.ensureInitialized();
  _rawLog('WidgetsFlutterBinding.ensureInitialized done');
  StartupLog.initSync();
  _rawLog('StartupLog.initSync done');
  installGlobalErrorHandlers();
  _rawLog('installGlobalErrorHandlers done');
  StartupLog.mark('main-start');
  runApp(const _CrashAwareApp());
}

/// Ultra-early logger — writes directly to file, no Flutter dependency.
void _rawLog(String msg) {
  try {
    final file = File('/storage/emulated/0/Documents/SuperNote/startup_log.txt');
    final dir = file.parent;
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    file.writeAsStringSync('[$ts] $msg\n', mode: FileMode.append);
  } catch (_) {
    // Try cache dir as fallback
    try {
      final file = File('${Directory.systemTemp.path}/startup_log.txt');
      final ts = DateTime.now().toIso8601String().substring(11, 23);
      file.writeAsStringSync('[$ts] $msg\n', mode: FileMode.append);
    } catch (_) {}
  }
}

/// Renders the real app once services are ready, while keeping a crash
/// overlay handler alive from the very first frame.
class _CrashAwareApp extends StatefulWidget {
  const _CrashAwareApp();

  @override
  State<_CrashAwareApp> createState() => _CrashAwareAppState();
}

class _CrashAwareAppState extends State<_CrashAwareApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperNote',
      theme: AppTheme.dark,
      // CrashOverlay lives OUTSIDE the child subtree so it can render even
      // when the app tree fails to build.
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          ?child,
          const CrashOverlay(),
        ],
      ),
      home: const _ServiceBootstrap(),
    );
  }
}

class _ServiceBootstrap extends StatefulWidget {
  const _ServiceBootstrap();

  @override
  State<_ServiceBootstrap> createState() => _ServiceBootstrapState();
}

class _ServiceBootstrapState extends State<_ServiceBootstrap> {
  Object? _bootstrapError;
  BootstrapServices? _services;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _rawLog('_bootstrap: start');
    try {
      final services = await _initServices();
      _rawLog('_bootstrap: services ready');
      if (mounted) setState(() => _services = services);
    } catch (e, s) {
      _rawLog('_bootstrap: CRASH: $e');
      StartupLog.logCrash(e, s);
      if (mounted) setState(() => _bootstrapError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F17),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              '⚠️ BOOTSTRAP ERROR\n\n$_bootstrapError',
              style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
            ),
          ),
        ),
      );
    }
    if (_services == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F17),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }
    return SuperNoteAppShell(services: _services!);
  }
}

class BootstrapServices {
  final NoteService noteService;
  final SyncService syncService;
  final TaskService taskService;
  final AuthService authService;
  final GeminiService geminiService;
  final ThemeService themeService;
  final AutoUpdateService updateService;
  final CustomBackgroundService? customBackgroundService;
  final LanguageService languageService;
  final InactivityRetentionService inactivityService;
  final FcmService fcmService;
  final StreamSubscription<bool>? _authSubscription;

  BootstrapServices({
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
    required this.themeService,
    required this.updateService,
    this.customBackgroundService,
    required this.languageService,
    required this.inactivityService,
    required this.fcmService,
    StreamSubscription<bool>? authSubscription,
  }) : _authSubscription = authSubscription;

  void dispose() {
    _authSubscription?.cancel();
  }
}

Future<BootstrapServices> _initServices() async {
  _rawLog('_initServices: start');
  StartupLog.mark('timezone');
  tz.initializeTimeZones();

  try {
    StartupLog.mark('firebase-init');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    StartupLog.mark('firebase-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
    debugPrint('Firebase init skipped/failed: $e');
  }
  StartupLog.mark('firebase');

  try {
    StartupLog.mark('dateformat-init');
    await initializeDateFormatting('vi', null);
    StartupLog.mark('dateformat-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('dateformat');

  if (isDesktopPlatform) {
    StartupLog.mark('desktop-init');
    await _bootstrapDesktop();
    StartupLog.mark('desktop-ready');
  }
  StartupLog.mark('desktop');

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  StartupLog.mark('auth-init');
  final authService = AuthService();
  try {
    await authService.init();
  } catch (e) {
    debugPrint('[Main] AuthService init error: $e');
  }
  StartupLog.mark('storage-init');
  final storageService = StorageService(authService: authService);
  try {
    await storageService.init();
    StartupLog.mark('storage-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('storage');

  StartupLog.mark('noteService-init');
  final noteService = NoteService(storageService, authService: authService);
  StartupLog.mark('syncService-init');
  final syncService = SyncService(noteService);
  StartupLog.mark('taskService-init');
  final taskService = TaskService(authService: authService);
  try {
    await taskService.init();
    StartupLog.mark('taskService-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('task-service');

  StartupLog.mark('geminiService-init');
  final geminiService = GeminiService();
  try {
    await geminiService.init();
    StartupLog.mark('geminiService-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('gemini');

  StartupLog.mark('themeService-init');
  final themeService = ThemeService();
  try {
    await themeService.init();
    StartupLog.mark('themeService-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('theme');

  CustomBackgroundService? customBackgroundService;
  try {
    StartupLog.mark('customBgService-init');
    customBackgroundService = CustomBackgroundService();
    await customBackgroundService.init();
    StartupLog.mark('customBgService-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('custom-bg');

  StartupLog.mark('autoUpdateService-init');
  final updateService = AutoUpdateService();
  StartupLog.mark('autoUpdateService-ready');

  // ===== BACKEND SERVICES =====
  try {
    StartupLog.mark('firestore-init');
    await FirestoreRepository().init();
    StartupLog.mark('firestore-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('firestore');

  try {
    StartupLog.mark('feedback-init');
    await FeedbackService().init();
    StartupLog.mark('feedback-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('feedback');

  try {
    StartupLog.mark('aiParser-init');
    await AiParserService().init();
    StartupLog.mark('aiParser-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('ai-parser');

  StartupLog.mark('languageService-init');
  final languageService = LanguageService();
  try {
    await languageService.init();
    StartupLog.mark('languageService-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('language');

  // ===== INACTIVITY RETENTION =====
  final inactivityService = InactivityRetentionService();
  try {
    StartupLog.mark('inactivity-init');
    await inactivityService.init();
    StartupLog.mark('inactivity-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('inactivity');

  // ===== FCM =====
  final fcmService = FcmService();
  try {
    StartupLog.mark('fcm-init');
    await fcmService.init();
    StartupLog.mark('fcm-ready');
  } catch (e) {
    StartupLog.logCrash(e, StackTrace.current);
  }
  StartupLog.mark('fcm');

  // Listen to auth changes → reload per-user data
  StartupLog.mark('authListener-init');
  final authSubscription = authService.authStateChanges.listen((isLoggedIn) async {
    final userId = isLoggedIn ? authService.userId : null;
    await storageService.reloadForUser(userId);
    await taskService.reloadForUser(userId);
  });
  StartupLog.mark('authListener-ready');

  StartupLog.mark('services-ready');
  await StartupLog.initVisible();
  StartupLog.mark('initVisible-done');
  return BootstrapServices(
    noteService: noteService,
    syncService: syncService,
    taskService: taskService,
    authService: authService,
    geminiService: geminiService,
    themeService: themeService,
    updateService: updateService,
    customBackgroundService: customBackgroundService,
    languageService: languageService,
    inactivityService: inactivityService,
    fcmService: fcmService,
    authSubscription: authSubscription,
  );
}

class SuperNoteAppShell extends StatelessWidget {
  final BootstrapServices services;
  const SuperNoteAppShell({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    final noteService = services.noteService;
    final syncService = services.syncService;
    final taskService = services.taskService;
    final authService = services.authService;
    final geminiService = services.geminiService;
    final themeService = services.themeService;
    final updateService = services.updateService;
    final customBackgroundService = services.customBackgroundService;
    final languageService = services.languageService;
    final inactivityService = services.inactivityService;

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'SuperNote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: languageService.currentLocale,
          supportedLocales: const [
            Locale('vi'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ListenableBuilder(
            listenable: authService,
            builder: (context, _) {
              final isLoggedIn = authService.isLoggedIn;

              if (isLoggedIn) {
                return MainShell(
                  noteService: noteService,
                  syncService: syncService,
                  taskService: taskService,
                  authService: authService,
                  geminiService: geminiService,
                  themeService: themeService,
                  updateService: updateService,
                  customBackgroundService: customBackgroundService,
                  languageService: languageService,
                  inactivityService: inactivityService,
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
  final CustomBackgroundService? customBackgroundService;
  final LanguageService languageService;
  final InactivityRetentionService inactivityService;

  const MainShell({
    super.key,
    required this.noteService,
    required this.syncService,
    required this.taskService,
    required this.authService,
    required this.geminiService,
    required this.themeService,
    required this.updateService,
    this.customBackgroundService,
    required this.languageService,
    required this.inactivityService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  StreamSubscription<String>? _notifTapSub;
  bool _hasUpdate = false;

  /// Clamp _currentIndex to a safe range to prevent IndexedStack out-of-bounds.
  int get _safeIndex {
    if (_currentIndex < 0) return 0;
    if (_currentIndex >= _tabCount) return 0;
    return _currentIndex;
  }

  int get _tabCount => 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StartupLog.mark('mainShell-initState');
    widget.themeService.addListener(_onThemeChanged);
    widget.updateService.addListener(_onUpdateChanged);
    StartupLog.mark('mainShell-screens-built');

    _loadUpdateState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupLog.mark('first-frame-rendered');
      _checkNotificationPermission();
      _checkForUpdates();
    });

    // Listen to notification taps — navigate to Tasks tab
    _notifTapSub = widget.taskService.onNotificationTappedStream.listen((taskId) {
      if (!mounted) return;
      _onNavTap(0); // Switch to Tasks tab
      // Small delay to ensure tab switch completes
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã mở task từ thông báo'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  Future<void> _checkNotificationPermission() async {
    final notifService = NotificationService();
    // Only check status, don't request - permission is requested on first task creation
    await notifService.init();
    final granted = await notifService.areNotificationsEnabled();
    if (!granted && mounted) {
      _showNotificationReminderDialog();
    }
  }

  void _showNotificationReminderDialog() async {
    final notifService = NotificationService();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Nhắc nhở thông báo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Để không bỏ lỡ công việc, hãy bật thông báo cho app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, 'dismiss'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: AppColors.textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Text('Để sau'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, 'settings'),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Mở Cài đặt',
                              style: TextStyle(color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == 'settings') {
      await notifService.openNotificationSettings();
    }
  }

  Future<void> _checkForUpdates() async {
    if (widget.updateService.hasShownDialogThisSession) return;
    try {
      final update = await widget.updateService.checkForUpdate();
      _loadUpdateState();

      if (update != null && mounted) {
        widget.updateService.hasShownDialogThisSession = true;
        await showDialog<String>(
          context: context,
          barrierDismissible: !update.forceUpdate,
          builder: (_) => UpdateCheckDialog(updateService: widget.updateService),
        );
      }
    } catch (e) {
      debugPrint('[UpdateCheck] Error: $e');
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onUpdateChanged() {
    if (!mounted) return;
    widget.updateService.hasUpdateAvailable.then((v) {
      if (mounted) setState(() => _hasUpdate = v);
    });
  }

  Future<void> _loadUpdateState() async {
    final hasUpdate = await widget.updateService.hasUpdateAvailable;
    if (mounted) setState(() => _hasUpdate = hasUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.themeService.removeListener(_onThemeChanged);
    widget.updateService.removeListener(_onUpdateChanged);
    _notifTapSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
      widget.taskService.rescheduleNotifications();
      widget.inactivityService.onResume();
      _checkForUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    StartupLog.mark('mainShell-build');
    final desktop = isDesktopPlatform;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Only handle tab switching — do NOT pop routes.
        // Pushed routes (TaskDetailScreen, etc.) have their own PopScope
        // that handles back via _saveAndPop() or similar.
        if (_previousIndex != _currentIndex) {
          setState(() {
            final temp = _currentIndex;
            _currentIndex = _previousIndex;
            _previousIndex = temp;
          });
        }
      },
      child: ThemeVideoBackground(
        themeService: widget.themeService,
        child: widget.customBackgroundService != null
            ? CustomBackgroundWidget(
                backgroundService: widget.customBackgroundService!,
                child: CyberpunkBackground(
                  backgroundColor: Colors.transparent,
                  showOrbs: widget.themeService.detailedBackground,
                  child: _buildScaffold(context, desktop),
                ),
              )
            : CyberpunkBackground(
                backgroundColor: Colors.transparent,
                showOrbs: widget.themeService.detailedBackground,
                child: _buildScaffold(context, desktop),
              ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, bool desktop) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 32,
                          color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 3),
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
                  ),
                ),

              // ===== MAIN CONTENT =====
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _safeIndex,
                    children: [
                      TaskScreen(taskService: widget.taskService, geminiService: widget.geminiService),
                      CalendarScreen(taskService: widget.taskService),
                      TimelineScreen(taskService: widget.taskService),
                      SettingsScreen(
                        authService: widget.authService,
                        geminiService: widget.geminiService,
                        themeService: widget.themeService,
                        taskService: widget.taskService,
                        customBackgroundService: widget.customBackgroundService,
                        languageService: widget.languageService,
                      ),
                    ],
                  ),
                ),
              ),

              // ===== BOTTOM NAVIGATION (4 tabs + center AI FAB) =====
              SafeArea(
                top: false,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 3),
                        border: Border(
                            top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1)),
                      ),
                      child: SizedBox(
                        height: 64,
                        child: Row(
                          children: [
                            // Tasks
                            _buildNavItem(0, Icons.task_alt_outlined, Icons.task_alt_rounded, 'Tasks'),
                            // Calendar
                            _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Calendar'),
                            // Center AI FAB
                            _buildCenterFab(),
                            // Timeline
                            _buildNavItem(2, Icons.view_timeline_outlined, Icons.view_timeline_rounded, 'Timeline'),
                            // Settings
                            _buildNavItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings', showBadge: _hasUpdate),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ===== AI CHAT BUTTON is now integrated in bottom nav bar =====
        ],
      ),
    );
  }

  // ===== CUSTOM NAV ITEM =====
  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label, {bool showBadge = false}) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.6),
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== CENTER AI FAB =====
  Widget _buildCenterFab() {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () => AiChatPanel.show(
              context, widget.geminiService, widget.taskService),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradient.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/glass_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';
import '../services/theme_service.dart';
import '../services/task_service.dart';
import '../services/custom_background_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'past_tasks_screen.dart';
import 'stats_screen.dart';
import '../shared/widgets/cyberpunk_background.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  final GeminiService geminiService;
  final ThemeService themeService;
  final TaskService taskService;
  final CustomBackgroundService? customBackgroundService;
  final LanguageService languageService;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.geminiService,
    required this.themeService,
    required this.taskService,
    this.customBackgroundService,
    required this.languageService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notifService = NotificationService();
  final _geminiKeyController = TextEditingController();

  bool _notificationSound = true;
  bool _notificationVibration = true;
  int _defaultPreReminder = 0;
  int _quietStart = 22;
  int _quietEnd = 7;
  bool _geminiConfigured = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _geminiConfigured = widget.geminiService.isConfigured;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _loadSettings() async {
    try {
      final (qs, qe) = await _notifService.getQuietHours();
      if (!mounted) return;
      final defPre = await _notifService.getDefaultPreReminder();
      if (!mounted) return;
      setState(() {
        _quietStart = qs;
        _quietEnd = qe;
        _defaultPreReminder = defPre;
      });
    } catch (_) {
      // ignore — keep defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(AppLocalizations.of(context)!.settings, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ===== THEME (top — most visual impact) =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionAppearance),
                _buildThemeSelector(),
                const SizedBox(height: AppSpacing.md),

                // ===== CUSTOM BACKGROUND =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionCustomBg),
                _buildCustomBackgroundCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== NOTIFICATIONS (second — most used) =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionNotifications),
                _buildCard([
                  _buildSwitchTile(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.primary,
                    title: AppLocalizations.of(context)!.notifSound,
                    subtitle: AppLocalizations.of(context)!.notifSoundDesc,
                    value: _notificationSound,
                    onChanged: (v) => setState(() => _notificationSound = v),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    iconColor: AppColors.orange,
                    title: AppLocalizations.of(context)!.notifVibration,
                    subtitle: AppLocalizations.of(context)!.notifVibrationDesc,
                    value: _notificationVibration,
                    onChanged: (v) => setState(() => _notificationVibration = v),
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.green,
                    title: AppLocalizations.of(context)!.defaultPreReminder,
                    subtitle: _formatPreReminder(_defaultPreReminder),
                    onTap: _showPreReminderPicker,
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.nightlight_round,
                    iconColor: AppColors.purple,
                    title: AppLocalizations.of(context)!.quietHours,
                    subtitle: '${_quietStart.toString().padLeft(2, '0')}:00 – ${_quietEnd.toString().padLeft(2, '0')}:00',
                    onTap: _showQuietHoursPicker,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ARCHIVE =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionStorage),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.history_rounded,
                    iconColor: AppColors.purple,
                    title: AppLocalizations.of(context)!.pastTasks,
                    subtitle: AppLocalizations.of(context)!.pastTasksDesc,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CyberpunkBackground(
                            child: PastTasksScreen(taskService: widget.taskService),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== FEATURES =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionFeatures),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.primary,
                    title: AppLocalizations.of(context)!.statsTitle,
                    subtitle: AppLocalizations.of(context)!.statsSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CyberpunkBackground(
                            child: StatsScreen(taskService: widget.taskService),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ACCOUNT =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionAccount),
                _buildLanguageTile(),
                const SizedBox(height: AppSpacing.sm),
                _buildAccountCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== GEMINI AI =====
                _buildSectionTitle('Gemini AI'),
                _buildGeminiCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== TEST =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionTest),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.primary,
                    title: AppLocalizations.of(context)!.testNotif,
                    subtitle: AppLocalizations.of(context)!.testNotifDesc,
                    onTap: _sendTestNotification,
                  ),
                  _buildDivider(),
                  _buildTapTile(
                    icon: Icons.send_rounded,
                    iconColor: AppColors.teal,
                    title: 'Test Gemini API',
                    subtitle: _geminiConfigured ? AppLocalizations.of(context)!.geminiConfigured : AppLocalizations.of(context)!.geminiNotConfigured,
                    onTap: _testGemini,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ABOUT =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionInfo),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.textSecondary,
                    title: 'SuperNote',
                    subtitle: 'v$_appVersion — Smart reminder app for students',
                    onTap: () {},
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ACCOUNT CARD =====
  Widget _buildAccountCard() {
    try {
      final user = widget.authService.user;
      final isLoggedIn = widget.authService.isLoggedIn;

      return _buildCard([
        if (isLoggedIn && user != null) ...[
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text(
                      (user.displayName ?? user.email ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            title: Text(
              user.displayName ?? (user.isAnonymous ? AppLocalizations.of(context)!.accountGuest : 'User'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user.isAnonymous ? AppLocalizations.of(context)!.accountNoSync : (user.email ?? ''),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          _buildDivider(),
          _buildTapTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: AppLocalizations.of(context)!.logout,
            subtitle: AppLocalizations.of(context)!.logoutDesc,
            onTap: _signOut,
          ),
        ] else ...[
          _buildTapTile(
            icon: Icons.login_rounded,
            iconColor: AppColors.primary,
            title: AppLocalizations.of(context)!.accountNotLoggedIn,
            subtitle: AppLocalizations.of(context)!.accountNotLoggedInDesc,
            onTap: _signIn,
          ),
        ],
      ]);
    } catch (e) {
      // Fallback if AuthService not ready
      return _buildCard([
        _buildTapTile(
          icon: Icons.person_outline_rounded,
          iconColor: AppColors.textMuted,
            title: AppLocalizations.of(context)!.accountTitle,
            subtitle: AppLocalizations.of(context)!.loading,
          onTap: () {},
        ),
      ]);
    }
  }

  // ===== LANGUAGE TILE =====
  Widget _buildLanguageTile() {
    final isVietnamese = widget.languageService.isVietnamese;
    return _buildCard([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.languageLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    isVietnamese ? AppLocalizations.of(context)!.languageVietnamese : AppLocalizations.of(context)!.languageEnglish,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Segment toggle VI / EN
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildLangOption(label: 'VI', isSelected: isVietnamese),
                  _buildLangOption(label: 'EN', isSelected: !isVietnamese),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildLangOption({required String label, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        widget.languageService.changeLanguage(label == 'VI' ? 'vi' : 'en');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ===== GEMINI CARD =====
  Widget _buildGeminiCard() {
    return _buildCard([
      ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF34A853)]),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
        ),
        title: const Text('Gemini AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(
          _geminiConfigured ? 'Configured — AI features enabled' : 'Enter API key to enable AI',
          style: TextStyle(fontSize: 12, color: _geminiConfigured ? AppColors.green : AppColors.textMuted),
        ),
      ),
      _buildDivider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _geminiKeyController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Paste your Gemini API key...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final data = ClipboardData(text: _geminiKeyController.text);
                    Clipboard.setData(data);
                    _showSnack('Copied!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 16, color: Colors.white54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                           AppColors.secondary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveGeminiKey,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Save Key',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _testGemini,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white54),
                            SizedBox(width: 4),
                            Text('Test',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Get your API key from aistudio.google.com/apikey',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    ]);
  }

  // ===== SNACKBAR HELPER =====
  void _showSnack(String text, {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  // ===== AUTH ACTIONS =====
  void _signOut() async {
    try {
      // Firebase signOut is essential — Google signOut is optional
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.authGenericError)),
        );
      }
    }
  }

  void _signIn() async {
    await FirebaseAuth.instance.signOut();
  }

  // ===== ACTIONS =====
  void _saveGeminiKey() async {
    final key = _geminiKeyController.text.trim();
    if (key.isNotEmpty) {
      await widget.geminiService.setApiKey(key);
      if (!mounted) return;
      setState(() => _geminiConfigured = true);
      _showSnack('API key saved!', backgroundColor: AppColors.green);
    }
  }

  void _testGemini() async {
    final result = await widget.geminiService.generate('Say hello in Vietnamese');
    if (!mounted) return;
    _showSnack(result ?? 'No response', duration: const Duration(seconds: 3));
  }

  void _sendTestNotification() async {
    await _notifService.sendTestNotification();
    if (!mounted) return;
    _showSnack('Test notification sent!');
  }

  void _showPreReminderPicker() {
    final options = [0, 5, 10, 15, 30, 60, 120, 1440];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: EdgeInsets.all(16), child: Text(AppLocalizations.of(context)!.defaultPreReminder, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ...options.map((m) => RadioGroup<int>(
              groupValue: _defaultPreReminder,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _defaultPreReminder = v);
                  _notifService.setDefaultPreReminder(v);
                  Navigator.pop(context);
                }
              },
              child: RadioListTile<int>(
                value: m,
                title: Text(_formatPreReminder(m)),
                activeColor: AppColors.primary,
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showQuietHoursPicker() {
    final startTime = TimeOfDay(hour: _quietStart, minute: 0);
    final endTime = TimeOfDay(hour: _quietEnd, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuietHoursSheet(
        initialStart: startTime,
        initialEnd: endTime,
        onSave: (start, end) {
          setState(() {
            _quietStart = start.hour;
            _quietEnd = end.hour;
          });
          _notifService.setQuietHours(_quietStart, _quietEnd);
        },
      ),
    );
  }

  String _formatPreReminder(int minutes) {
    if (minutes == 0) return 'At time of event';
    if (minutes >= 1440) return '${minutes ~/ 1440} day(s) before';
    if (minutes >= 60) return '${minutes ~/ 60} hour(s) before';
    return '$minutes minute(s) before';
  }

  // ===== UI Components =====
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 56, color: Colors.white.withValues(alpha: 0.08));

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ===== THEME SELECTOR =====
  Widget _buildThemeSelector() {
    final current = widget.themeService.current.id;
    return _buildCard([
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.sectionAppearance,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: GlassTheme.all.map((theme) {
                final isSelected = theme.id == current;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.themeService.setTheme(theme.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.accent.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? theme.accent
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Color dot
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.borderStart, theme.borderEnd],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                      color: theme.accent.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    )]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${theme.emoji} ${theme.name}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? theme.accent : AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ]);
  }

  // ===== CUSTOM BACKGROUND CARD =====
  Widget _buildCustomBackgroundCard() {
    final bg = widget.customBackgroundService;
    if (bg == null) {
      return const SizedBox.shrink();
    }
    final hasBg = bg.isActive;
    final isVideo = bg.type == CustomBackgroundType.video;

    return _buildCard([
      _buildTapTile(
        icon: isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        iconColor: AppColors.primary,
        title: hasBg ? (isVideo ? AppLocalizations.of(context)!.customBgActiveVideo : AppLocalizations.of(context)!.customBgActiveImage) : AppLocalizations.of(context)!.customBgChoose,
        subtitle: hasBg ? AppLocalizations.of(context)!.customBgTapToChange : AppLocalizations.of(context)!.customBgDesc,
        onTap: _pickCustomBackground,
      ),
      if (hasBg) ...[
        _buildDivider(),
        _buildTapTile(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          title: AppLocalizations.of(context)!.customBgRemove,
          subtitle: AppLocalizations.of(context)!.customBgRemoveDesc,
          onTap: _removeCustomBackground,
        ),
      ],
    ]);
  }

  Future<void> _pickCustomBackground() async {
    try {
      await widget.customBackgroundService?.pickAndSetBackground();
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.customBgUpdated, backgroundColor: AppColors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.authGenericError, backgroundColor: AppColors.error);
      }
    }
  }

  Future<void> _removeCustomBackground() async {
    await widget.customBackgroundService?.removeBackground();
    if (mounted) {
      _showSnack(AppLocalizations.of(context)!.customBgRemoved);
    }
  }
}

// ===== QUIET HOURS SHEET =====
class _QuietHoursSheet extends StatefulWidget {
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final Function(TimeOfDay start, TimeOfDay end) onSave;

  const _QuietHoursSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  @override
  State<_QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<_QuietHoursSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd;
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary.withValues(alpha: 0.2);
                }
                return Colors.white.withValues(alpha: 0.04);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textPrimary;
              }),
              dialHandColor: AppColors.primary,
              dialBackgroundColor: Colors.white.withValues(alpha: 0.04),
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textPrimary;
              }),
              entryModeIconColor: AppColors.primary,
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary.withValues(alpha: 0.2);
                }
                return Colors.white.withValues(alpha: 0.04);
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.textPrimary;
              }),
              dayPeriodBorderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.nightlight_round, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.quietHours,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.quietHoursDesc,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Time tiles
            Row(
              children: [
                // Start time
                Expanded(
                  child: _buildTimeTile('Bắt đầu', _startTime, true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
                // End time
                Expanded(
                  child: _buildTimeTile('Kết thúc', _endTime, false),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(_startTime, _endTime);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.geminiSave,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, bool isStart) {
    return GestureDetector(
      onTap: () => _selectTime(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.touch_app_rounded, size: 14,
                color: AppColors.textMuted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

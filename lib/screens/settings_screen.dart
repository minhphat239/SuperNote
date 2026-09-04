import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'auth_screen.dart';
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
            backgroundColor: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 4),
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
                const SizedBox(height: AppSpacing.sm),

                // ===== DETAILED BACKGROUND TOGGLE =====
                _buildCard([
                  _buildSwitchTile(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.primary,
                    title: AppLocalizations.of(context)!.detailedBackground,
                    subtitle: AppLocalizations.of(context)!.detailedBackgroundDesc,
                    value: widget.themeService.detailedBackground,
                    onChanged: (v) => widget.themeService.toggleDetailedBackground(v),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),

                // ===== CUSTOM BACKGROUND =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionCustomBg),
                _buildCustomBackgroundCard(),
                const SizedBox(height: AppSpacing.sm),

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
                const SizedBox(height: AppSpacing.sm),

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
                const SizedBox(height: AppSpacing.sm),

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
                const SizedBox(height: AppSpacing.sm),

                // ===== ACCOUNT =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionAccount),
                _buildLanguageTile(),
                const SizedBox(height: AppSpacing.xs),
                _buildAccountCard(),
                const SizedBox(height: AppSpacing.sm),

                // ===== GEMINI AI =====
                _buildSectionTitle('Gemini AI'),
                _buildGeminiCard(),
                const SizedBox(height: AppSpacing.sm),

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
                const SizedBox(height: AppSpacing.sm),

                // ===== ABOUT =====
                _buildSectionTitle(AppLocalizations.of(context)!.sectionInfo),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'SuperNote',
                    subtitle: 'v$_appVersion',
                    onTap: _showAboutDialog,
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
      final isLocalGuest = widget.authService.isLocalGuest;
      final displayName = (user?.displayName?.isNotEmpty == true ? user!.displayName : null)
          ?? (isLocalGuest ? 'Khách' : null) ?? '';
      final photoUrl = user?.photoURL;
      final email = (user?.email?.isNotEmpty == true ? user!.email : null) ?? '';
      final initial = (displayName.isNotEmpty ? displayName : email.isNotEmpty ? email : '?')[0].toUpperCase();

      return _buildCard([
        if (isLoggedIn) ...[
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            title: Text(
              displayName.isNotEmpty ? displayName : (isLocalGuest ? AppLocalizations.of(context)!.accountGuest : email.isNotEmpty ? email : 'User'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isLocalGuest || user?.isAnonymous == true ? AppLocalizations.of(context)!.accountNoSync : email,
              style: const TextStyle(fontSize: 12, color: Color(0xFFA0AAB2)),
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
    } catch (e, stackTrace) {
      debugPrint('[Settings] _buildAccountCard error: $e');
      debugPrint('[Settings] StackTrace: $stackTrace');
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: const TextStyle(fontSize: 12, color: Color(0xFFA0AAB2)),
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
      onTap: () async {
        await widget.languageService.changeLanguage(label == 'VI' ? 'vi' : 'en');
        if (mounted) setState(() {});
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
          style: TextStyle(fontSize: 12, color: _geminiConfigured ? AppColors.green : const Color(0xFFA0AAB2)),
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
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
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
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
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
      margin: EdgeInsets.fromLTRB(16, 0, 16, 80 + MediaQuery.of(context).padding.bottom),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ));
  }

  // ===== AUTH ACTIONS =====
  void _signOut() async {
    try {
      await widget.authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.authGenericError)),
        );
      }
    }
  }

  void _signIn() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          authService: widget.authService,
          themeService: widget.themeService,
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'About',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a1, a2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, a1, a2, child) {
        final curved = CurvedAnimation(parent: a1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: a1,
            child: _AboutDialog(appVersion: _appVersion),
          ),
        );
      },
    );
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
    final success = await _notifService.sendTestNotification();
    if (!mounted) return;
    if (success) {
      _showSnack('Test notification sent!');
    } else {
      _showSnack('Notification failed — check permission in Settings');
    }
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
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 16, top: 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFA0AAB2),
              letterSpacing: 0.8)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.xl),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AAB2))),
        trailing: Container(
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            inactiveThumbColor: AppColors.textMuted,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AAB2))),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, size: 20, color: iconColor)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AAB2))),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: GlassTheme.all.length,
              itemBuilder: (context, index) {
                final theme = GlassTheme.all[index];
                final isSelected = theme.id == current;
                return GestureDetector(
                  onTap: () => widget.themeService.setTheme(theme.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.accent.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? theme.accent.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.10),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.accent.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.borderStart, theme.borderEnd],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [BoxShadow(
                                    color: theme.accent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  )]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
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
        color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: _buildTimeTile(AppLocalizations.of(context)!.timeStart, _startTime, true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
                // End time
                Expanded(
                  child: _buildTimeTile(AppLocalizations.of(context)!.timeEnd, _endTime, false),
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

class _AboutDialog extends StatelessWidget {
  final String appVersion;
  const _AboutDialog({required this.appVersion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.flash_on_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),

                    // App name + version
                    Text('SuperNote',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text('v$appVersion',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        )),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),

                    // Links row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialChip(
                          icon: Icons.language_rounded,
                          label: 'Website',
                          onTap: () => launchUrl(Uri.parse('https://supernote.app'),
                              mode: LaunchMode.externalApplication),
                        ),
                        const SizedBox(width: 10),
                        _SocialChip(
                          icon: Icons.code_rounded,
                          label: 'GitHub',
                          onTap: () => launchUrl(Uri.parse('https://github.com/minhphat239/SuperNote'),
                              mode: LaunchMode.externalApplication),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),

                    // Author
                    Text('Tác giả',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(height: 8),
                    Text('Ngô Minh Phát',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 12),

                    // Social icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialIcon(
                          icon: 'facebook',
                          color: const Color(0xFF1877F2),
                          onTap: () => launchUrl(Uri.parse('https://facebook.com/nmp0704'),
                              mode: LaunchMode.externalApplication),
                        ),
                        const SizedBox(width: 14),
                        _SocialIcon(
                          icon: 'instagram',
                          color: const Color(0xFFE4405F),
                          onTap: () => launchUrl(Uri.parse('https://instagram.com/nmp0704'),
                              mode: LaunchMode.externalApplication),
                        ),
                        const SizedBox(width: 14),
                        _SocialIcon(
                          icon: 'tiktok',
                          color: AppColors.textPrimary,
                          onTap: () => launchUrl(Uri.parse('https://tiktok.com/@nmp0704'),
                              mode: LaunchMode.externalApplication),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Đóng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          _getIconData(),
          size: 20,
          color: color,
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (icon) {
      case 'facebook':
        return Icons.facebook_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      default:
        return Icons.link;
    }
  }
}

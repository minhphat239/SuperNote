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

class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  final GeminiService geminiService;
  final ThemeService themeService;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.geminiService,
    required this.themeService,
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
    final (qs, qe) = await _notifService.getQuietHours();
    final defPre = await _notifService.getDefaultPreReminder();
    setState(() {
      _quietStart = qs;
      _quietEnd = qe;
      _defaultPreReminder = defPre;
    });
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
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ===== THEME (top — most visual impact) =====
                _buildSectionTitle('Giao diện'),
                _buildThemeSelector(),
                const SizedBox(height: AppSpacing.md),

                // ===== NOTIFICATIONS (second — most used) =====
                _buildSectionTitle('Thông báo'),
                _buildCard([
                  _buildSwitchTile(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.primary,
                    title: 'Âm thanh thông báo',
                    subtitle: 'Phát âm thanh khi nhắc nhở',
                    value: _notificationSound,
                    onChanged: (v) => setState(() => _notificationSound = v),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    iconColor: AppColors.orange,
                    title: 'Rung',
                    subtitle: 'Rung khi có nhắc nhở',
                    value: _notificationVibration,
                    onChanged: (v) => setState(() => _notificationVibration = v),
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.green,
                    title: 'Nhắc nhở mặc định',
                    subtitle: _formatPreReminder(_defaultPreReminder),
                    onTap: _showPreReminderPicker,
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.nightlight_round,
                    iconColor: AppColors.purple,
                    title: 'Giờ yên lặng',
                    subtitle: '${_quietStart.toString().padLeft(2, '0')}:00 – ${_quietEnd.toString().padLeft(2, '0')}:00',
                    onTap: _showQuietHoursPicker,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ACCOUNT =====
                _buildSectionTitle('Tài khoản'),
                _buildAccountCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== GEMINI AI =====
                _buildSectionTitle('Gemini AI'),
                _buildGeminiCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== TEST =====
                _buildSectionTitle('Test'),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.primary,
                    title: 'Gửi thông báo test',
                    subtitle: 'Kiểm tra thông báo hoạt động',
                    onTap: _sendTestNotification,
                  ),
                  _buildDivider(),
                  _buildTapTile(
                    icon: Icons.send_rounded,
                    iconColor: AppColors.teal,
                    title: 'Test Gemini API',
                    subtitle: _geminiConfigured ? 'Đã cấu hình' : 'Chưa có API key',
                    onTap: _testGemini,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ABOUT =====
                _buildSectionTitle('Thông tin'),
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
            user.displayName ?? (user.isAnonymous ? 'Khách' : 'User'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            user.isAnonymous ? 'Không đồng bộ' : (user.email ?? ''),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        _buildDivider(),
        _buildTapTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          title: 'Đăng xuất',
          subtitle: 'Thoát khỏi tài khoản hiện tại',
          onTap: _signOut,
        ),
      ] else ...[
        _buildTapTile(
          icon: Icons.login_rounded,
          iconColor: AppColors.primary,
          title: 'Chưa đăng nhập',
          subtitle: 'Mở lại màn hình đăng nhập',
          onTap: _signIn,
        ),
      ],
    ]);
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
                          AppColors.magentaPink.withValues(alpha: 0.8),
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
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
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
            const Padding(padding: EdgeInsets.all(16), child: Text('Default Pre-reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
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
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const Text('Quiet Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: _buildHourPicker('Start', _quietStart, (v) => setState(() => _quietStart = v))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('—', style: TextStyle(fontSize: 20, color: AppColors.textMuted))),
                Expanded(child: _buildHourPicker('End', _quietEnd, (v) => setState(() => _quietEnd = v))),
              ]),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _notifService.setQuietHours(_quietStart, _quietEnd);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourPicker(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: () => onChanged((value - 1 + 24) % 24),
              ),
              SizedBox(
                width: 44,
                child: Text('${value.toString().padLeft(2, '0')}:00', textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                onPressed: () => onChanged((value + 1) % 24),
              ),
            ],
          ),
        ),
      ],
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
                const Text(
                  'Chọn bộ màu giao diện',
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
}

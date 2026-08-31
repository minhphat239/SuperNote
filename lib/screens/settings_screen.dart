import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  final GeminiService geminiService;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.geminiService,
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _geminiConfigured = widget.geminiService.isConfigured;
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
      backgroundColor: AppColors.background,
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
                // ===== ACCOUNT =====
                _buildSectionTitle('Account'),
                _buildAccountCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== GEMINI AI =====
                _buildSectionTitle('Gemini AI'),
                _buildGeminiCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== SYNC =====
                _buildSectionTitle('Cloud Sync'),
                _buildSyncCard(),
                const SizedBox(height: AppSpacing.md),

                // ===== NOTIFICATIONS =====
                _buildSectionTitle('Notifications'),
                _buildCard([
                  _buildSwitchTile(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.primary,
                    title: 'Notification Sound',
                    subtitle: 'Play sound for reminders',
                    value: _notificationSound,
                    onChanged: (v) => setState(() => _notificationSound = v),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    iconColor: AppColors.orange,
                    title: 'Vibration',
                    subtitle: 'Vibrate for reminders',
                    value: _notificationVibration,
                    onChanged: (v) => setState(() => _notificationVibration = v),
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.timer_rounded,
                    iconColor: AppColors.green,
                    title: 'Default Pre-reminder',
                    subtitle: _formatPreReminder(_defaultPreReminder),
                    onTap: _showPreReminderPicker,
                  ),
                  _buildDivider(),
                  _buildPickerTile(
                    icon: Icons.nightlight_round,
                    iconColor: AppColors.purple,
                    title: 'Quiet Hours',
                    subtitle: '${_quietStart.toString().padLeft(2, '0')}:00 – ${_quietEnd.toString().padLeft(2, '0')}:00',
                    onTap: _showQuietHoursPicker,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== TEST =====
                _buildSectionTitle('Test'),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.primary,
                    title: 'Send Test Notification',
                    subtitle: 'Verify notifications are working',
                    onTap: _sendTestNotification,
                  ),
                  _buildDivider(),
                  _buildTapTile(
                    icon: Icons.send_rounded,
                    iconColor: AppColors.teal,
                    title: 'Test Gemini API',
                    subtitle: _geminiConfigured ? 'API configured' : 'API key not set',
                    onTap: _testGemini,
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ===== ABOUT =====
                _buildSectionTitle('About'),
                _buildCard([
                  _buildTapTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.textSecondary,
                    title: 'SuperNote',
                    subtitle: 'v3.1.0 — Smart reminder app for students',
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
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    (user.name ?? user.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(
            user.name ?? 'User',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            user.email ?? '',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        _buildDivider(),
        _buildTapTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          title: 'Sign Out',
          subtitle: 'Sign out from your account',
          onTap: _signOut,
        ),
      ] else ...[
        _buildTapTile(
          icon: Icons.g_mobiledata_rounded,
          iconColor: const Color(0xFF4285F4),
          title: 'Sign in with Google',
          subtitle: 'Sync notes & tasks to cloud',
          onTap: _signInWithGoogle,
        ),
        _buildDivider(),
        _buildTapTile(
          icon: Icons.mail_outline_rounded,
          iconColor: AppColors.primary,
          title: 'Sign in with Email',
          subtitle: 'Use email & password',
          onTap: _signInWithEmail,
        ),
        _buildDivider(),
        _buildTapTile(
          icon: Icons.phone_android_rounded,
          iconColor: AppColors.green,
          title: 'Use Locally',
          subtitle: 'No cloud sync, data on this device only',
          onTap: _signInLocal,
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
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Paste your Gemini API key...',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final data = ClipboardData(text: _geminiKeyController.text);
                    Clipboard.setData(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveGeminiKey,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save Key', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _testGemini,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Test', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Get your API key from aistudio.google.com/apikey',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    ]);
  }

  // ===== SYNC CARD =====
  Widget _buildSyncCard() {
    final isLoggedIn = widget.authService.isLoggedIn;
    return _buildCard([
      _buildTapTile(
        icon: Icons.cloud_upload_rounded,
        iconColor: isLoggedIn ? AppColors.green : AppColors.textMuted,
        title: isLoggedIn ? 'Sync Now' : 'Sign in to enable sync',
        subtitle: isLoggedIn ? 'Upload local data to cloud' : 'Use Account section to sign in',
        onTap: isLoggedIn ? _syncNow : () {},
      ),
      _buildDivider(),
      _buildTapTile(
        icon: Icons.cloud_download_rounded,
        iconColor: isLoggedIn ? AppColors.teal : AppColors.textMuted,
        title: isLoggedIn ? 'Pull from Cloud' : 'Sign in to enable pull',
        subtitle: isLoggedIn ? 'Download cloud data to this device' : 'Use Account section to sign in',
        onTap: isLoggedIn ? _pullFromCloud : () {},
      ),
    ]);
  }

  // ===== ACTIONS =====
  void _signInWithGoogle() async {
    final success = await widget.authService.signInWithGoogle();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Signed in with Google!' : 'Sign-in cancelled'),
      backgroundColor: success ? AppColors.green : AppColors.error,
    ));
  }

  void _signInWithEmail() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign in with Email'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await widget.authService.registerWithEmail(
                emailCtrl.text, passCtrl.text, nameCtrl.text,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success ? 'Registered!' : 'Failed'),
                backgroundColor: success ? AppColors.green : AppColors.error,
              ));
            },
            child: const Text('Register & Sign In'),
          ),
        ],
      ),
    );
  }

  void _signInLocal() async {
    await widget.authService.signInAsLocal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using local mode — no cloud sync')),
    );
  }

  void _signOut() async {
    await widget.authService.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
  }

  void _saveGeminiKey() {
    final key = _geminiKeyController.text.trim();
    if (key.isNotEmpty) {
      widget.geminiService.setApiKey(key);
      setState(() => _geminiConfigured = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved!'), backgroundColor: AppColors.green),
      );
    }
  }

  void _testGemini() async {
    final result = await widget.geminiService.generate('Say hello in Vietnamese');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result ?? 'No response'),
      duration: const Duration(seconds: 3),
    ));
  }

  void _syncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing...'), duration: Duration(seconds: 2)),
    );
  }

  void _pullFromCloud() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pulling from cloud...'), duration: Duration(seconds: 2)),
    );
  }

  void _sendTestNotification() async {
    await _notifService.sendTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Test notification sent!', style: TextStyle(fontWeight: FontWeight.w500)),
      ]),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      duration: const Duration(seconds: 2),
    ));
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
            ...options.map((m) => RadioListTile<int>(
              value: m,
              groupValue: _defaultPreReminder,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _defaultPreReminder = v);
                  _notifService.setDefaultPreReminder(v);
                  Navigator.pop(context);
                }
              },
              title: Text(_formatPreReminder(m)),
              activeColor: AppColors.primary,
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
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadow.sm,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56, color: AppColors.border);

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 20, color: iconColor)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 20, color: iconColor)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 20, color: iconColor)),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}

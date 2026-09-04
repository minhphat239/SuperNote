import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/glass_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class AuthScreen extends StatefulWidget {
  final AuthService authService;
  final ThemeService themeService;

  const AuthScreen({
    super.key,
    required this.authService,
    required this.themeService,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _isLoading = false;
  String? _error;

  // Email form
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ==================== GOOGLE ====================
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    debugPrint('=== GOOGLE SIGN IN START ===');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await widget.authService.signInWithGoogle();
      debugPrint('Google sign in result: $success');
      if (!mounted) return;
      if (!success) {
        setState(() {
          _error = widget.authService.errorMessage ?? 'Đăng nhập Google thất bại.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Google sign in exception: $e');
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e, context);
        _isLoading = false;
      });
    }
  }

  // ==================== EMAIL ====================
  Future<void> _submitEmail() async {
    if (_isLoading) return;

    // Validate
    if (_emailController.text.trim().isEmpty ||
        _passController.text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.authFillAll);
      return;
    }

    if (!_isLogin) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _error = AppLocalizations.of(context)!.authEnterName);
        return;
      }
      if (_passController.text != _confirmPassController.text) {
        setState(() => _error = AppLocalizations.of(context)!.authPasswordMismatch);
        return;
      }
      if (_passController.text.length < 6) {
        setState(() => _error = AppLocalizations.of(context)!.authWeakPassword);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool success;
      if (_isLogin) {
        debugPrint('=== EMAIL LOGIN START ===');
        success = await widget.authService.signInWithEmail(
          _emailController.text.trim(),
          _passController.text,
        );
      } else {
        debugPrint('=== EMAIL REGISTER START ===');
        success = await widget.authService.registerWithEmail(
          _emailController.text.trim(),
          _passController.text,
          _nameController.text.trim(),
        );
      }
      debugPrint('Email auth result: $success, error: ${widget.authService.errorMessage}');
      if (!mounted) return;
      if (!success) {
        setState(() {
          _error = widget.authService.errorMessage ?? 'Đăng nhập thất bại.';
          _isLoading = false;
        });
      }
      // On success, authStateChanges stream auto-navigates to MainShell
    } catch (e) {
      debugPrint('Email auth exception: $e');
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e, context);
        _isLoading = false;
      });
    }
  }

  // ==================== GUEST ====================
  Future<void> _signInAsGuest() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await widget.authService.signInAsLocal();
      if (!mounted) return;
      if (!success) {
        setState(() {
          _error = widget.authService.errorMessage ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
      // If success, StreamBuilder in main.dart will handle navigation
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e, context);
        _isLoading = false;
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== FORGOT PASSWORD ====================
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email để đặt lại mật khẩu');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }

    final success = await widget.authService.sendPasswordResetEmail(email);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.authPasswordResetSent,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() {
        _error = widget.authService.errorMessage ?? 'Không thể gửi email. Vui lòng thử lại.';
      });
    }
  }

  String _friendlyError(Object e, BuildContext context) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return AppLocalizations.of(context)!.authAccountNotFound;
    if (msg.contains('wrong-password')) return AppLocalizations.of(context)!.authWrongPassword;
    if (msg.contains('email-already-in-use')) return AppLocalizations.of(context)!.authEmailInUse;
    if (msg.contains('invalid-email')) return AppLocalizations.of(context)!.authInvalidEmail;
    if (msg.contains('weak-password')) return AppLocalizations.of(context)!.authTooWeak;
    if (msg.contains('network-request-failed')) return AppLocalizations.of(context)!.authNetworkError;
    if (msg.contains('invalid-credential')) return AppLocalizations.of(context)!.authInvalidCredential;
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildAuthButtons(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.authDataSafe,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.note_alt_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'SuperNote',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.authTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      children: [
        // ===== GOOGLE =====
        _AuthButton(
          icon: Icons.g_mobiledata_rounded,
          label: AppLocalizations.of(context)!.authGoogleSignIn,
          color: const Color(0xFF4285F4),
          isLoading: _isLoading,
          onTap: _signInWithGoogle,
          glassTheme: widget.themeService.current,
        ),
        const SizedBox(height: 12),

        // ===== DIVIDER =====
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(AppLocalizations.of(context)!.authOr,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 12),

        // ===== EMAIL FORM =====
        _buildEmailForm(),
        const SizedBox(height: 12),

        // ===== GUEST =====
        _AuthButton(
          icon: Icons.phone_android_rounded,
          label: AppLocalizations.of(context)!.authGuest,
          color: AppColors.green,
          isOutlined: true,
          isLoading: _isLoading,
          onTap: _signInAsGuest,
          glassTheme: widget.themeService.current,
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassTint.withValues(alpha: AppColors.glassOpacity * 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle login/register
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLogin ? AppLocalizations.of(context)!.authEmailSignIn : AppLocalizations.of(context)!.authEmailRegister,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name (register only)
          if (!_isLogin) ...[
            _FieldInput(
              controller: _nameController,
              hint: AppLocalizations.of(context)!.authNameHint,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
          ],

          // Email
          _FieldInput(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),

          // Password
          _FieldInput(
            controller: _passController,
            hint: AppLocalizations.of(context)!.authPasswordHint,
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            suffix: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),

          // Confirm password (register only)
          if (!_isLogin) ...[
            const SizedBox(height: 10),
            _FieldInput(
              controller: _confirmPassController,
              hint: AppLocalizations.of(context)!.authConfirmPassword,
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isLogin ? AppLocalizations.of(context)!.authLoginButton : AppLocalizations.of(context)!.authRegisterButton,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Toggle login/register link + Forgot password
          if (_isLogin)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
                  child: Text(
                    AppLocalizations.of(context)!.authNoAccount,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '  •  ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                GestureDetector(
                  onTap: _forgotPassword,
                  child: Text(
                    AppLocalizations.of(context)!.authForgotPassword,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child: Text(
                  AppLocalizations.of(context)!.authHasAccount,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;
  final bool isLoading;
  final VoidCallback onTap;
  final GlassTheme? glassTheme;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isOutlined = false,
    required this.isLoading,
    required this.onTap,
    this.glassTheme,
  });

  @override
  Widget build(BuildContext context) {
    final tint = glassTheme?.glassTint ?? color;
    final borderStart = glassTheme?.borderStart ?? color;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: isOutlined
            ? null
            : LinearGradient(
                colors: [
                  tint.withValues(alpha: glassTheme?.glassOpacity ?? 0.08),
                  tint.withValues(alpha: (glassTheme?.glassOpacity ?? 0.08) * 0.5),
                ],
              ),
        color: isOutlined ? Colors.transparent : null,
        border: Border.all(
          width: 1,
          color: isOutlined ? color.withValues(alpha: 0.3) : borderStart.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isOutlined ? color : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _FieldInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

// lib/features/auth/screens/login_screen.dart
// شاشة تسجيل الدخول - تصميم حديث وأنيق

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/business/auth_service.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import 'account_status_screen.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    FocusScope.of(context).unfocus();

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    final success = await authProvider.signInWithEmail(
      email,
      _passwordController.text,
    );

    if (mounted) setState(() => _isLoading = false);

    if (!success) {
      _handleLoginError(
        authProvider: authProvider,
        email: email,
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
      );
    }
  }

  void _handleLoginError({
    required AuthProvider authProvider,
    required String email,
    required ScaffoldMessengerState scaffoldMessenger,
    required NavigatorState navigator,
  }) {
    final error = authProvider.lastError;
    if (error == null) {
      _showSnackBar(scaffoldMessenger, 'حدث خطأ أثناء تسجيل الدخول');
      return;
    }

    switch (error.type) {
      case AuthErrorType.emailNotVerified:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
        break;
      case AuthErrorType.accountPending:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => AccountStatusScreen(
              status: AccountStatusType.pending,
              email: email,
              message: error.message,
              onBackToLogin: () => navigator.pop(),
            ),
          ),
        );
        break;
      case AuthErrorType.accountRejected:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => AccountStatusScreen(
              status: AccountStatusType.rejected,
              email: email,
              message: error.message,
              onBackToLogin: () => navigator.pop(),
            ),
          ),
        );
        break;
      case AuthErrorType.accountDisabled:
        navigator.push(
          MaterialPageRoute(
            builder: (_) => AccountStatusScreen(
              status: AccountStatusType.disabled,
              email: email,
              message: error.message,
              onBackToLogin: () => navigator.pop(),
            ),
          ),
        );
        break;
      case AuthErrorType.operationCancelled:
        break;
      default:
        _showSnackBar(scaffoldMessenger, error.message);
    }
  }

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();

    setState(() => _isLoading = true);
    final success = await authProvider.signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);

    if (!success) {
      _handleLoginError(
        authProvider: authProvider,
        email: authProvider.pendingEmail ?? '',
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
      );
    }
  }

  void _showForgotPasswordSheet() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheet(
        emailController: emailController,
        onSubmit: (email) => _resetPassword(email, ctx),
      ),
    );
  }

  Future<void> _resetPassword(String email, BuildContext sheetContext) async {
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await authProvider.resetPassword(email);
    if (Navigator.of(sheetContext).canPop()) Navigator.of(sheetContext).pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'تم إرسال رابط الاستعادة' : authProvider.error ?? 'حدث خطأ',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 56),
                  _buildForm(),
                  const SizedBox(height: 28),
                  _buildDivider(),
                  const SizedBox(height: 28),
                  _buildGoogleButton(),
                  const SizedBox(height: 48),
                  _buildRegisterLink(),
                ],
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.store_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text(
          'مدير هور',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'نظام إدارة المبيعات',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          const Text(
            'البريد الإلكتروني',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration('example@email.com'),
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocusNode),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'بريد غير صالح';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password
          const Text(
            'كلمة المرور',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration('••••••••').copyWith(
              suffixIcon: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 44),
            ),
            onFieldSubmitted: (_) => _login(),
            validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
          ),

          const SizedBox(height: 14),

          // Forgot Password
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _showForgotPasswordSheet,
              child: Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(
                  0xFF1A1A2E,
                ).withValues(alpha: 0.5),
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
                  : const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.g_mobiledata,
                size: 22,
                color: Color(0xFFEA4335),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'المتابعة بحساب Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'إنشاء حساب',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== Forgot Password Sheet ====================
class _ForgotPasswordSheet extends StatefulWidget {
  final TextEditingController emailController;
  final Future<void> Function(String email) onSubmit;

  const _ForgotPasswordSheet({
    required this.emailController,
    required this.onSubmit,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'استعادة كلمة المرور',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سنرسل لك رابط إعادة التعيين',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: widget.emailController,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'بريد غير صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _isLoading = true);
                                await widget.onSubmit(
                                  widget.emailController.text.trim(),
                                );
                                if (mounted) setState(() => _isLoading = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'إرسال',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

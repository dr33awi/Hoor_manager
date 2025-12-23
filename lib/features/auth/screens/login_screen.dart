// lib/features/auth/screens/login_screen.dart
// شاشة تسجيل الدخول - مع التوجيه لشاشة الانتظار عند الحساب المعلق

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'pending_approval_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final success = await authProvider.signInWithEmail(
      email,
      _passwordController.text,
    );

    // ✅ التحقق من mounted قبل setState
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!success) {
      // ✅ التوجيه حسب نوع الخطأ
      final errorCode = authProvider.errorCode;
      if (errorCode != null) {
        _handleLoginError(errorCode, authProvider.error, email);
      } else if (authProvider.error != null) {
        // إذا لم يكن هناك errorCode لكن يوجد error
        _showErrorSnackBar(authProvider.error!);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    // ✅ التحقق من mounted قبل setState
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!success) {
      final errorCode = authProvider.errorCode;
      if (errorCode != null) {
        _handleLoginError(
          errorCode,
          authProvider.error,
          authProvider.pendingVerificationEmail ?? '',
        );
      } else if (authProvider.error != null) {
        _showErrorSnackBar(authProvider.error!);
      }
    }
  }

  /// ✅ معالجة أخطاء تسجيل الدخول والتوجيه المناسب
  void _handleLoginError(String errorCode, String? errorMessage, String email) {
    debugPrint('🔴 _handleLoginError called with errorCode: $errorCode');
    switch (errorCode) {
      case 'account-pending':
        // ✅ الانتقال لشاشة انتظار الموافقة
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PendingApprovalScreen(
              email: email,
              isNewAccount: false,
              onBackToLogin: () => Navigator.pop(context),
            ),
          ),
        );
        break;

      case 'email-not-verified':
        // ✅ الانتقال لشاشة التحقق من الإيميل
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
        break;

      case 'account-rejected':
        // عرض Dialog للحساب المرفوض
        _showErrorDialog(
          title: 'تم رفض الحساب',
          message: errorMessage ?? 'تم رفض حسابك من قبل المدير',
          icon: Icons.cancel,
          color: AppTheme.errorColor,
        );
        break;

      case 'account-disabled':
        // عرض Dialog للحساب المعطل
        _showErrorDialog(
          title: 'حساب معطل',
          message: errorMessage ?? 'تم تعطيل حسابك. تواصل مع المدير',
          icon: Icons.block,
          color: AppTheme.grey600,
        );
        break;

      // ✅ أخطاء بيانات الدخول الخاطئة
      case 'user-not-found':
        _showErrorSnackBar('لا يوجد حساب بهذا البريد الإلكتروني');
        break;

      case 'wrong-password':
        _showErrorSnackBar('كلمة المرور غير صحيحة');
        break;

      case 'invalid-credential':
        _showErrorSnackBar('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        break;

      case 'invalid-email':
        _showErrorSnackBar('البريد الإلكتروني غير صالح');
        break;

      case 'too-many-requests':
        _showErrorSnackBar('محاولات كثيرة جداً. حاول لاحقاً');
        break;

      case 'network-request-failed':
        _showErrorSnackBar('خطأ في الاتصال بالإنترنت');
        break;

      default:
        // عرض SnackBar للأخطاء الأخرى
        _showErrorSnackBar(errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول');
    }
  }

  /// ✅ عرض رسالة خطأ سريعة
  void _showErrorSnackBar(String message) {
    debugPrint('🔴 _showErrorSnackBar called with: $message');
    debugPrint('🔴 mounted: $mounted');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              Navigator.pop(context);

              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.resetPassword(
                emailController.text.trim(),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'تم إرسال رابط استعادة كلمة المرور'
                          : authProvider.error ?? 'حدث خطأ',
                    ),
                    backgroundColor: success
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // الشعار
                Icon(Icons.store, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),

                // العنوان
                Text(
                  'مدير هور',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجل دخولك للمتابعة',
                  style: TextStyle(color: AppTheme.grey600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'البريد الإلكتروني غير صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                const SizedBox(height: 16),

                // زر تسجيل الدخول
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // أو
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.grey300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'أو',
                        style: TextStyle(color: AppTheme.grey600),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.grey300)),
                  ],
                ),
                const SizedBox(height: 24),

                // تسجيل الدخول بـ Google
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 24,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata),
                    ),
                    label: const Text('تسجيل الدخول بـ Google'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.grey300),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // إنشاء حساب
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

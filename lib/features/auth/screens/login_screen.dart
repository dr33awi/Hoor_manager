// lib/features/auth/screens/login_screen.dart
// شاشة تسجيل الدخول المحسنة - مع UI حديث ومعالجة أخطاء محسنة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'pending_approval_screen.dart';
import 'email_verification_screen.dart';
import 'account_status_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _shakeForm();
      return;
    }

    // إخفاء الكيبورد
    FocusScope.of(context).unfocus();

    // حفظ المراجع قبل الـ async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    final success = await authProvider.signInWithEmail(
      email,
      _passwordController.text,
    );

    // استخدام try-catch للتعامل مع حالة الـ unmounted
    try {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {}

    if (!success) {
      _handleLoginErrorSafe(
        authProvider: authProvider,
        email: email,
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
      );
    }
  }

  /// معالجة خطأ تسجيل الدخول بشكل آمن (لا يعتمد على context)
  void _handleLoginErrorSafe({
    required AuthProvider authProvider,
    required String email,
    required ScaffoldMessengerState scaffoldMessenger,
    required NavigatorState navigator,
  }) {
    final error = authProvider.lastError;

    debugPrint('🔴 _handleLoginErrorSafe called');
    debugPrint('🔴 error: $error');

    if (error == null) {
      _showErrorSnackBarSafe(scaffoldMessenger, 'حدث خطأ أثناء تسجيل الدخول');
      return;
    }

    debugPrint('🔴 error.type: ${error.type}');
    debugPrint('🔴 error.message: ${error.message}');

    switch (error.type) {
      case AuthErrorType.emailNotVerified:
        debugPrint('🔴 Navigating to EmailVerificationScreen');
        navigator.push(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
        break;

      case AuthErrorType.accountPending:
        debugPrint('🔴 Navigating to AccountStatusScreen (pending)');
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
        debugPrint('🔴 Navigating to AccountStatusScreen (rejected)');
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
        debugPrint('🔴 Navigating to AccountStatusScreen (disabled)');
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
        debugPrint('🔴 Operation cancelled, doing nothing');
        break;

      default:
        debugPrint('🔴 Showing error snackbar: ${error.message}');
        _showErrorSnackBarSafe(scaffoldMessenger, error.message);
    }
  }

  void _showErrorSnackBarSafe(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    // حفظ المراجع قبل الـ async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();

    setState(() => _isLoading = true);

    final success = await authProvider.signInWithGoogle();

    try {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {}

    if (!success) {
      _handleLoginErrorSafe(
        authProvider: authProvider,
        email: authProvider.pendingEmail ?? '',
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
      );
    }
  }

  void _navigateToEmailVerification(String email) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EmailVerificationScreen(email: email),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToPendingApproval(String email, {required bool isNew}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PendingApprovalScreen(
          email: email,
          isNewAccount: isNew,
          onBackToLogin: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorDialog(AuthError error) {
    showDialog(
      context: context,
      builder: (context) => _ErrorDialog(error: error),
    );
  }

  void _shakeForm() {
    // يمكن إضافة animation للاهتزاز هنا
    HapticFeedback.mediumImpact();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    // حفظ المراجع قبل فتح الـ sheet
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ForgotPasswordSheet(
        emailController: emailController,
        onSubmit: (email) =>
            _resetPassword(email, sheetContext, scaffoldMessenger),
      ),
    );
  }

  Future<void> _resetPassword(
    String email,
    BuildContext sheetContext,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(email);

    // إغلاق الـ sheet أولاً
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    // عرض الـ SnackBar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'تم إرسال رابط استعادة كلمة المرور'
                    : authProvider.error ?? 'حدث خطأ',
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
              AppTheme.primaryColor.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isSmallScreen ? 16 : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الشعار والعنوان
                        _buildHeader(isSmallScreen),

                        SizedBox(height: isSmallScreen ? 24 : 40),

                        // بطاقة تسجيل الدخول
                        _buildLoginCard(),

                        const SizedBox(height: 24),

                        // رابط إنشاء حساب
                        _buildRegisterLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Column(
      children: [
        // الشعار
        Container(
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.store_rounded,
            size: isSmall ? 48 : 64,
            color: Colors.white,
          ),
        ),

        SizedBox(height: isSmall ? 16 : 24),

        // العنوان
        Text(
          'مدير هور',
          style: TextStyle(
            fontSize: isSmall ? 28 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'نظام إدارة المبيعات المتكامل',
          style: TextStyle(
            fontSize: isSmall ? 14 : 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان البطاقة
            Text(
              'تسجيل الدخول',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // حقل البريد الإلكتروني
            _buildEmailField(),

            const SizedBox(height: 16),

            // حقل كلمة المرور
            _buildPasswordField(),

            const SizedBox(height: 12),

            // نسيت كلمة المرور وتذكرني
            _buildOptionsRow(),

            const SizedBox(height: 24),

            // زر تسجيل الدخول
            _buildLoginButton(),

            const SizedBox(height: 20),

            // الفاصل
            _buildDivider(),

            const SizedBox(height: 20),

            // تسجيل الدخول بـ Google
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني',
        hintText: 'example@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: AppTheme.grey200.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال البريد الإلكتروني';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'البريد الإلكتروني غير صالح';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppTheme.grey400,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        filled: true,
        fillColor: AppTheme.grey200.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // تذكرني
        Expanded(
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'تذكرني',
                style: TextStyle(color: AppTheme.grey600, fontSize: 13),
              ),
            ],
          ),
        ),

        // نسيت كلمة المرور
        TextButton(
          onPressed: _showForgotPasswordDialog,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'نسيت كلمة المرور؟',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'تسجيل الدخول',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.grey300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'أو',
            style: TextStyle(color: AppTheme.grey400, fontSize: 14),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.grey300)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.grey300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              height: 22,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(
              'متابعة بحساب Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ليس لديك حساب؟',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const RegisterScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    );
                  },
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'إنشاء حساب جديد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== Dialogs & Sheets ====================

class _ErrorDialog extends StatelessWidget {
  final AuthError error;

  const _ErrorDialog({required this.error});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (error.type) {
      case AuthErrorType.accountRejected:
        color = AppTheme.errorColor;
        icon = Icons.cancel_rounded;
        break;
      case AuthErrorType.accountDisabled:
        color = AppTheme.grey600;
        icon = Icons.block_rounded;
        break;
      case AuthErrorType.accountPending:
        color = AppTheme.warningColor;
        icon = Icons.hourglass_empty_rounded;
        break;
      default:
        color = AppTheme.errorColor;
        icon = Icons.error_rounded;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.grey600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (error.type) {
      case AuthErrorType.accountRejected:
        return 'تم رفض الحساب';
      case AuthErrorType.accountDisabled:
        return 'الحساب معطل';
      case AuthErrorType.accountPending:
        return 'في انتظار الموافقة';
      default:
        return 'خطأ';
    }
  }
}

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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit(widget.emailController.text.trim());
    } finally {
      // التحقق من أن الـ widget لا يزال mounted قبل setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المقبض
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // الأيقونة والعنوان
              Icon(
                Icons.lock_reset_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'استعادة كلمة المرور',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين',
                style: TextStyle(fontSize: 14, color: AppTheme.grey600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // حقل البريد
              TextFormField(
                controller: widget.emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
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
              const SizedBox(height: 24),

              // الأزرار
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('إرسال الرابط'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

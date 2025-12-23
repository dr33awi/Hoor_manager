// lib/features/auth/screens/email_verification_screen.dart
// شاشة التحقق من البريد الإلكتروني المحسنة

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/logger_service.dart';
import '../providers/auth_provider.dart';
import 'pending_approval_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoCheck();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAutoCheck() {
    // حفظ المرجع قبل بدء الـ Timer
    final authProvider = context.read<AuthProvider>();

    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isChecking && mounted) {
        _checkVerificationSilently(authProvider);
      }
    });
  }

  Future<void> _checkVerificationSilently(AuthProvider authProvider) async {
    if (!mounted) return;

    final isVerified = await authProvider.checkEmailVerificationOnly();

    if (isVerified && mounted) {
      _autoCheckTimer?.cancel();
      _navigateToPendingApproval();
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;

    // حفظ المراجع
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isResending = true);

    final success = await authProvider.resendVerificationEmail();

    if (mounted) {
      setState(() => _isResending = false);

      if (success) {
        _startCooldown();
        _showMessageSafe(
          scaffoldMessenger,
          'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
          isSuccess: true,
        );
      } else {
        _showMessageSafe(
          scaffoldMessenger,
          authProvider.error ?? 'حدث خطأ',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _checkVerification() async {
    // حفظ المراجع
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isChecking = true);

    final isVerified = await authProvider.checkEmailVerificationOnly();

    if (mounted) {
      setState(() => _isChecking = false);

      if (isVerified) {
        AppLogger.i('✅ تم التحقق من البريد الإلكتروني');
        _showMessageSafe(
          scaffoldMessenger,
          'تم تفعيل البريد بنجاح! ✓',
          isSuccess: true,
        );
        _autoCheckTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _navigateToPendingApproval();
      } else {
        _showMessageSafe(
          scaffoldMessenger,
          'البريد الإلكتروني لم يتم تفعيله بعد',
          isSuccess: false,
        );
      }
    }
  }

  void _navigateToPendingApproval() {
    // حفظ المراجع قبل أي عملية
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();

    authProvider.signOutAfterVerification();

    navigator.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PendingApprovalScreen(
          email: widget.email,
          isNewAccount: true,
          onBackToLogin: () => navigator.popUntil((route) => route.isFirst),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showMessage(String message, {required bool isSuccess}) {
    if (!mounted) return;
    _showMessageSafe(
      ScaffoldMessenger.of(context),
      message,
      isSuccess: isSuccess,
    );
  }

  void _showMessageSafe(
    ScaffoldMessengerState messenger,
    String message, {
    required bool isSuccess,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    // خطوات التسجيل
                    _buildProgressSteps(),

                    const SizedBox(height: 24),

                    // البطاقة الرئيسية
                    _buildMainCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStep(1, 'إنشاء الحساب', false, true),
          _buildStepLine(true),
          _buildStep(2, 'تفعيل البريد', true, false),
          _buildStepLine(false),
          _buildStep(3, 'موافقة المدير', false, false),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successColor
                  : isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: isActive
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppTheme.successColor : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Column(
        children: [
          // أيقونة البريد المتحركة
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warningColor.withOpacity(0.15),
                    AppTheme.warningColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                size: 56,
                color: AppTheme.warningColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // العنوان
          const Text(
            'تحقق من بريدك الإلكتروني',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'لقد أرسلنا رابط التحقق إلى:',
            style: TextStyle(color: AppTheme.grey600, fontSize: 15),
          ),

          const SizedBox(height: 12),

          // البريد الإلكتروني
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // التعليمات
          _buildInstructions(),

          const SizedBox(height: 28),

          // زر التحقق
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isChecking
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'تم التفعيل - متابعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // إعادة الإرسال
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لم تصلك الرسالة؟',
                style: TextStyle(color: AppTheme.grey600),
              ),
              TextButton(
                onPressed: (_isResending || _resendCooldown > 0)
                    ? null
                    : _resendEmail,
                child: _isResending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _resendCooldown > 0
                            ? 'إعادة الإرسال ($_resendCooldown)'
                            : 'إعادة الإرسال',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _resendCooldown > 0 ? AppTheme.grey400 : null,
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الرجوع
          TextButton.icon(
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              final navigator = Navigator.of(context);
              authProvider.signOut();
              navigator.popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: const Text('الرجوع لتسجيل الدخول'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.grey600),
          ),

          const SizedBox(height: 16),

          // ملاحظة Spam
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.grey200.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.grey600,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تحقق من مجلد الرسائل غير المرغوب فيها (Spam)',
                    style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                color: AppTheme.infoColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'خطوات التفعيل:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(1, 'افتح بريدك الإلكتروني'),
          _buildInstructionItem(2, 'ابحث عن رسالة التفعيل'),
          _buildInstructionItem(3, 'اضغط على رابط التفعيل'),
          _buildInstructionItem(4, 'عد هنا واضغط "تم التفعيل"'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

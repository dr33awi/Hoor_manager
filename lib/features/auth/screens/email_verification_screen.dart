// lib/features/auth/screens/email_verification_screen.dart
// شاشة التحقق من البريد الإلكتروني - مُصححة ومحسنة

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

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        if (mounted) {
          setState(() => _resendCooldown--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendVerificationEmail();

    if (mounted) {
      setState(() => _isResending = false);

      if (success) {
        _startCooldown();
        _showMessage(
          'تم إرسال رابط التحقق إلى بريدك الإلكتروني',
          isSuccess: true,
        );
      } else {
        _showMessage(authProvider.error ?? 'حدث خطأ', isSuccess: false);
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    final authProvider = context.read<AuthProvider>();

    AppLogger.d('=== بدء التحقق من تفعيل البريد ===');
    AppLogger.d('البريد: ${widget.email}');

    final success = await authProvider.checkVerificationAndLogin();

    AppLogger.d('نتيجة التحقق: success=$success');
    AppLogger.d('errorCode: ${authProvider.errorCode}');
    AppLogger.d('error: ${authProvider.error}');
    AppLogger.d(
      'needsEmailVerification: ${authProvider.needsEmailVerification}',
    );

    if (mounted) {
      setState(() => _isChecking = false);

      if (success) {
        // ✅ تم التحقق بنجاح والحساب موافق عليه
        AppLogger.i('✅ تم التحقق والدخول بنجاح');
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (authProvider.errorCode == 'account-pending') {
        // ✅ تم تفعيل البريد لكن الحساب في انتظار الموافقة
        AppLogger.i('✅ البريد مفعّل - الحساب في انتظار الموافقة');
        _showMessage('تم تفعيل البريد بنجاح! ✓', isSuccess: true);

        // انتظار قليل ثم الانتقال
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          // مسح حالة التحقق
          authProvider.clearVerificationState();

          // الانتقال لشاشة الانتظار
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PendingApprovalScreen(email: widget.email),
            ),
          );
        }
      } else if (authProvider.needsEmailVerification ||
          authProvider.errorCode == 'email-not-verified') {
        // ❌ البريد لم يتم تفعيله بعد
        AppLogger.w('❌ البريد لم يتم تفعيله بعد');
        _showMessage('البريد الإلكتروني لم يتم تفعيله بعد', isSuccess: false);
      } else if (authProvider.errorCode == 'account-rejected') {
        // ❌ الحساب مرفوض
        AppLogger.w('❌ الحساب مرفوض');
        _showMessage(authProvider.error ?? 'تم رفض حسابك', isSuccess: false);
      } else if (authProvider.errorCode == 'no-pending-data') {
        // ❌ انتهت صلاحية البيانات
        AppLogger.w('❌ انتهت صلاحية بيانات التحقق');
        _showMessage(
          'انتهت صلاحية البيانات، يرجى إعادة تسجيل الدخول',
          isSuccess: false,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (authProvider.error != null) {
        // ❌ خطأ آخر
        AppLogger.e('❌ خطأ: ${authProvider.error}');
        _showMessage(authProvider.error!, isSuccess: false);
      }
    }
  }

  void _showMessage(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? AppTheme.successColor
            : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة البريد
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 64,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // العنوان
                      Text(
                        'تحقق من بريدك الإلكتروني',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // الوصف
                      Text(
                        'لقد أرسلنا رابط التحقق إلى:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // البريد الإلكتروني
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.ltr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // التعليمات
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.infoColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.infoColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'خطوات التفعيل:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStep('1', 'افتح بريدك الإلكتروني'),
                            _buildStep('2', 'ابحث عن رسالة من التطبيق'),
                            _buildStep('3', 'اضغط على رابط التفعيل'),
                            _buildStep('4', 'عد هنا واضغط "تم التفعيل"'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر التحقق من التفعيل
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _checkVerification,
                          icon: _isChecking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isChecking
                                ? 'جاري التحقق...'
                                : 'تم التفعيل - متابعة',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // إعادة إرسال الرابط
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لم تصلك الرسالة؟',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: (_isResending || _resendCooldown > 0)
                                ? null
                                : _resendEmail,
                            child: _isResending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _resendCooldown > 0
                                        ? 'إعادة الإرسال ($_resendCooldown)'
                                        : 'إعادة الإرسال',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _resendCooldown > 0
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // الرجوع
                      TextButton.icon(
                        onPressed: () {
                          context.read<AuthProvider>().clearVerificationState();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('الرجوع لتسجيل الدخول'),
                      ),

                      const SizedBox(height: 16),

                      // ملاحظة
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تحقق من مجلد الرسائل غير المرغوب فيها (Spam) إذا لم تجد الرسالة',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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

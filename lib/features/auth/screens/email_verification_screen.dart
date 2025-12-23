// lib/features/auth/screens/email_verification_screen.dart
// شاشة التحقق من البريد - تصميم حديث

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
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

    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isResending = true);
    final success = await authProvider.resendVerificationEmail();

    if (mounted) {
      setState(() => _isResending = false);
      if (success) {
        _startCooldown();
        _showSnackBar(messenger, 'تم إرسال الرابط', isSuccess: true);
      } else {
        _showSnackBar(
          messenger,
          authProvider.error ?? 'حدث خطأ',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _checkVerification() async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isChecking = true);
    final isVerified = await authProvider.checkEmailVerificationOnly();

    if (mounted) {
      setState(() => _isChecking = false);
      if (isVerified) {
        _showSnackBar(messenger, 'تم التفعيل بنجاح', isSuccess: true);
        _autoCheckTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _navigateToPendingApproval();
      } else {
        _showSnackBar(messenger, 'لم يتم التفعيل بعد', isSuccess: false);
      }
    }
  }

  void _navigateToPendingApproval() {
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();
    authProvider.signOutAfterVerification();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => PendingApprovalScreen(
          email: widget.email,
          isNewAccount: true,
          onBackToLogin: () => navigator.popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  void _showSnackBar(
    ScaffoldMessengerState messenger,
    String message, {
    required bool isSuccess,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.read<AuthProvider>().signOut();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.grey.shade700,
            size: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  _buildSteps(),
                  const SizedBox(height: 48),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, false, true),
        _stepLine(true),
        _stepDot(2, true, false),
        _stepLine(false),
        _stepDot(3, false, false),
      ],
    );
  }

  Widget _stepDot(int num, bool active, bool done) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF10B981)
            : active
            ? const Color(0xFF1A1A2E)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$num',
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: active ? const Color(0xFF10B981) : Colors.grey.shade200,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mark_email_unread_rounded,
            size: 36,
            color: Color(0xFFD97706),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'تحقق من بريدك',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'أرسلنا رابط التحقق إلى',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
            textDirection: TextDirection.ltr,
          ),
        ),

        const SizedBox(height: 36),

        // Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _instructionItem('1', 'افتح بريدك الإلكتروني'),
              const SizedBox(height: 12),
              _instructionItem('2', 'اضغط على رابط التفعيل'),
              const SizedBox(height: 12),
              _instructionItem('3', 'عد هنا واضغط "تم التفعيل"'),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Check Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isChecking ? null : _checkVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'تم التفعيل',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لم تصلك الرسالة؟',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: (_isResending || _resendCooldown > 0)
                  ? null
                  : _resendEmail,
              child: _isResending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A2E),
                      ),
                    )
                  : Text(
                      _resendCooldown > 0
                          ? 'إعادة الإرسال ($_resendCooldown)'
                          : 'إعادة الإرسال',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _resendCooldown > 0
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Spam note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              'تحقق من مجلد Spam',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _instructionItem(String num, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
        ),
      ],
    );
  }
}

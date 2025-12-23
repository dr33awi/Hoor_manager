// lib/features/auth/screens/account_status_screen.dart
// شاشة حالة الحساب - تصميم حديث

import 'package:flutter/material.dart';

enum AccountStatusType { rejected, disabled, pending }

class AccountStatusScreen extends StatelessWidget {
  final AccountStatusType status;
  final String email;
  final String message;
  final VoidCallback onBackToLogin;

  const AccountStatusScreen({
    super.key,
    required this.status,
    required this.email,
    required this.message,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(_getIcon(), size: 40, color: _getColor()),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    _getTitle(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _getColor(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: const Color(0xFF0369A1),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getInfoMessage(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0369A1),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onBackToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'العودة لتسجيل الدخول',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case AccountStatusType.rejected:
        return const Color(0xFFEF4444);
      case AccountStatusType.disabled:
        return const Color(0xFFD97706);
      case AccountStatusType.pending:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (status) {
      case AccountStatusType.rejected:
        return Icons.cancel_rounded;
      case AccountStatusType.disabled:
        return Icons.block_rounded;
      case AccountStatusType.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getTitle() {
    switch (status) {
      case AccountStatusType.rejected:
        return 'تم رفض الحساب';
      case AccountStatusType.disabled:
        return 'الحساب معطل';
      case AccountStatusType.pending:
        return 'في انتظار الموافقة';
    }
  }

  String _getInfoMessage() {
    switch (status) {
      case AccountStatusType.rejected:
        return 'إذا كنت تعتقد أن هذا خطأ، تواصل مع المدير.';
      case AccountStatusType.disabled:
        return 'تم تعطيل حسابك. تواصل مع الدعم الفني.';
      case AccountStatusType.pending:
        return 'طلبك قيد المراجعة. سيتم إعلامك عند الموافقة.';
    }
  }
}

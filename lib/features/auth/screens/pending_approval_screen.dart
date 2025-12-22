// lib/features/auth/screens/pending_approval_screen.dart
// شاشة انتظار موافقة المدير

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String email;
  final bool isNewAccount;
  final VoidCallback? onBackToLogin;

  const PendingApprovalScreen({
    super.key,
    required this.email,
    this.isNewAccount = false,
    this.onBackToLogin,
  });

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
                      // أيقونة الساعة
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_empty,
                          size: 64,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // العنوان
                      Text(
                        isNewAccount
                            ? 'تم إنشاء حسابك بنجاح!'
                            : 'حسابك في انتظار الموافقة',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // الوصف
                      Text(
                        'طلب تسجيلك قيد المراجعة من قبل المدير.\nسيتم إعلامك عند الموافقة على حسابك.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

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
                                email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // معلومات إضافية
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
                                  'ماذا يحدث الآن؟',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStep(
                              '1',
                              'سيراجع المدير طلب تسجيلك',
                              Icons.person_search,
                            ),
                            _buildStep(
                              '2',
                              'ستتلقى إشعاراً عند الموافقة',
                              Icons.notifications_active,
                            ),
                            _buildStep(
                              '3',
                              'يمكنك تسجيل الدخول بعد الموافقة',
                              Icons.login,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر العودة
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed:
                              onBackToLogin ?? () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('العودة لتسجيل الدخول'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ملاحظة
                      Text(
                        'إذا كان لديك استفسار، تواصل مع المدير',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
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

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

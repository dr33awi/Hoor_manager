// lib/features/auth/screens/account_status_screen.dart
// شاشة حالة الحساب (مرفوض / معطل)

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum AccountStatusType { rejected, disabled, pending }

class AccountStatusScreen extends StatefulWidget {
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
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_getStatusColor().withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // الأيقونة المتحركة
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      size: 70,
                      color: _getStatusColor(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // العنوان
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _getStatusTitle(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // الرسالة الرئيسية
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey600,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // البريد الإلكتروني
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.grey200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: AppTheme.grey600,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.email,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.grey600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // معلومات إضافية
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildInfoCard(),
                ),

                const Spacer(flex: 2),

                // زر العودة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onBackToLogin,
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    label: const Text(
                      'العودة لتسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppTheme.infoColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _getInfoMessage(),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case AccountStatusType.rejected:
        return AppTheme.errorColor;
      case AccountStatusType.disabled:
        return AppTheme.warningColor;
      case AccountStatusType.pending:
        return AppTheme.infoColor;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case AccountStatusType.rejected:
        return Icons.cancel_rounded;
      case AccountStatusType.disabled:
        return Icons.block_rounded;
      case AccountStatusType.pending:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case AccountStatusType.rejected:
        return 'تم رفض الحساب';
      case AccountStatusType.disabled:
        return 'الحساب معطل';
      case AccountStatusType.pending:
        return 'في انتظار الموافقة';
    }
  }

  String _getInfoMessage() {
    switch (widget.status) {
      case AccountStatusType.rejected:
        return 'إذا كنت تعتقد أن هذا خطأ، يرجى التواصل مع المدير لمراجعة طلبك.';
      case AccountStatusType.disabled:
        return 'تم تعطيل حسابك من قبل المدير. تواصل مع الدعم الفني لمعرفة السبب.';
      case AccountStatusType.pending:
        return 'طلبك قيد المراجعة. سيتم إعلامك عند الموافقة على حسابك.';
    }
  }
}

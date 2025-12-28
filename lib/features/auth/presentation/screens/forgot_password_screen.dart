import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';

/// شاشة استعادة كلمة المرور
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(authStateProvider.notifier)
        .resetPassword(_emailController.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = success;
      });

      if (success) {
        _showSuccess();
      } else {
        _showError();
      }
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل إرسال الرابط، تحقق من البريد الإلكتروني'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.resetPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xl),

                // أيقونة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                // العنوان
                Text(
                  'نسيت كلمة المرور؟',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.sm),

                // الوصف
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.xxl),

                if (_emailSent) ...[
                  // رسالة النجاح
                  Container(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 48,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'تم إرسال الرابط بنجاح!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'تحقق من بريدك الإلكتروني واتبع التعليمات لإعادة تعيين كلمة المرور',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // زر العودة لتسجيل الدخول
                  AppButton(
                    text: 'العودة لتسجيل الدخول',
                    onPressed: () => context.pop(),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // إعادة الإرسال
                  AppButton(
                    text: 'إعادة إرسال الرابط',
                    isOutlined: true,
                    onPressed: () {
                      setState(() => _emailSent = false);
                    },
                  ),
                ] else ...[
                  // حقل البريد الإلكتروني
                  EmailTextField(
                    controller: _emailController,
                    validator: Validators.email,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleResetPassword(),
                  ),

                  const SizedBox(height: AppSizes.xl),

                  // زر إرسال
                  AppButton(
                    text: 'إرسال رابط الاستعادة',
                    onPressed: _handleResetPassword,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // العودة لتسجيل الدخول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تذكرت كلمة المرور؟',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AppTextButton(
                        text: AppStrings.login,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

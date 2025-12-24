import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// شاشة إنشاء حساب جديد
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(authStateProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      _handleAuthState();
    }
  }

  void _handleAuthState() {
    final state = ref.read(authStateProvider);

    switch (state) {
      case AuthPendingApproval():
        _showSuccess();
        context.go(AppRoutes.pendingApproval);
        break;
      case AuthError(:final message):
        _showError(message);
        ref.read(authStateProvider.notifier).clearError();
        break;
      default:
        break;
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إنشاء حسابك بنجاح، في انتظار موافقة المدير'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.register),
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
                const SizedBox(height: AppSizes.md),

                // رسالة ترحيبية
                Text(
                  'إنشاء حساب جديد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'أدخل بياناتك لإنشاء حساب جديد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: AppSizes.xl),

                // حقل الاسم الكامل
                AppTextField(
                  controller: _nameController,
                  label: AppStrings.fullName,
                  hint: 'أدخل اسمك الكامل',
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSizes.md),

                // حقل البريد الإلكتروني
                EmailTextField(
                  controller: _emailController,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSizes.md),

                // حقل الهاتف (اختياري)
                PhoneTextField(
                  controller: _phoneController,
                  validator: Validators.phoneOptional,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSizes.md),

                // حقل كلمة المرور
                PasswordTextField(
                  controller: _passwordController,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSizes.md),

                // حقل تأكيد كلمة المرور
                PasswordTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  validator: Validators.confirmPassword(_passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleRegister(),
                ),

                const SizedBox(height: AppSizes.xl),

                // ملاحظة
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: AppSizes.iconMd,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'بعد التسجيل، سيكون حسابك في انتظار موافقة المدير',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.info,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                // زر التسجيل
                AppButton(
                  text: AppStrings.register,
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSizes.lg),

                // لديك حساب؟
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.haveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppTextButton(
                      text: AppStrings.login,
                      onPressed: () => context.pop(),
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

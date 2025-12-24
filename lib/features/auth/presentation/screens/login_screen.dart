import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// شاشة تسجيل الدخول
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(authStateProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      _handleAuthState();
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    await ref.read(authStateProvider.notifier).signInWithGoogle();

    if (mounted) {
      setState(() => _isGoogleLoading = false);
      _handleAuthState();
    }
  }

  void _handleAuthState() {
    final state = ref.read(authStateProvider);

    switch (state) {
      case AuthAuthenticated():
        context.go(AppRoutes.home);
        break;
      case AuthPendingApproval():
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xxl),

                // الشعار والعنوان
                _buildHeader(),

                const SizedBox(height: AppSizes.xxl),

                // حقل البريد الإلكتروني
                EmailTextField(
                  controller: _emailController,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: AppSizes.md),

                // حقل كلمة المرور
                PasswordTextField(
                  controller: _passwordController,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: AppSizes.sm),

                // نسيت كلمة المرور
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppTextButton(
                    text: AppStrings.forgotPassword,
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                  ),
                ),

                const SizedBox(height: AppSizes.lg),

                // زر تسجيل الدخول
                AppButton(
                  text: AppStrings.login,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSizes.lg),

                // أو
                _buildDivider(),

                const SizedBox(height: AppSizes.lg),

                // زر تسجيل الدخول بـ Google
                GoogleSignInButton(
                  onPressed: _handleGoogleLogin,
                  isLoading: _isGoogleLoading,
                ),

                const SizedBox(height: AppSizes.xxl),

                // إنشاء حساب جديد
                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // الشعار
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          AppStrings.appNameAr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          AppStrings.appTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            AppStrings.orLoginWith,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noAccount,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        AppTextButton(
          text: AppStrings.register,
          onPressed: () => context.push(AppRoutes.register),
        ),
      ],
    );
  }
}

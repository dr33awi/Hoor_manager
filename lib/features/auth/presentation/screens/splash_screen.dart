import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

/// شاشة البداية
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // انتظار قليل لعرض الشاشة
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // التحقق من حالة المصادقة
    final state = ref.read(authStateProvider);

    switch (state) {
      case AuthAuthenticated():
        context.go(AppRoutes.home);
        break;
      case AuthPendingApproval():
        context.go(AppRoutes.pendingApproval);
        break;
      default:
        context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لتغييرات الحالة
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
          break;
        case AuthPendingApproval():
          context.go(AppRoutes.pendingApproval);
          break;
        case AuthUnauthenticated():
          context.go(AppRoutes.login);
          break;
        default:
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الشعار
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // اسم التطبيق
            const Text(
              AppStrings.appNameAr,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: AppSizes.xs),

            // الوصف
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryLight,
              ),
            ),

            const SizedBox(height: AppSizes.xxl),

            // مؤشر التحميل
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

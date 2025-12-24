import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';

/// شاشة انتظار موافقة المدير
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الانتظار
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  size: 60,
                  color: AppColors.warning,
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              // العنوان
              Text(
                'في انتظار الموافقة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.md),

              // الوصف
              Text(
                'تم إنشاء حسابك بنجاح!\n\nحسابك الآن في انتظار موافقة المدير.\nسيتم إعلامك عند تفعيل حسابك.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.xl),

              // معلومات المستخدم
              if (user != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.person_outline,
                        label: 'الاسم',
                        value: user.fullName,
                      ),
                      const Divider(height: AppSizes.lg),
                      _buildInfoRow(
                        context,
                        icon: Icons.email_outlined,
                        label: 'البريد',
                        value: user.email,
                      ),
                      if (user.phone != null) ...[
                        const Divider(height: AppSizes.lg),
                        _buildInfoRow(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'الهاتف',
                          value: user.phone!,
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: AppSizes.xxl),

              // زر تسجيل الخروج
              AppButton(
                text: AppStrings.logout,
                isOutlined: true,
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),

              const SizedBox(height: AppSizes.md),

              // ملاحظة
              Text(
                'إذا كان لديك أي استفسار، تواصل مع إدارة المتجر',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconMd, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.sm),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

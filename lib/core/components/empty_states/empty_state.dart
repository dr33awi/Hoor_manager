// ═══════════════════════════════════════════════════════════════════════════
// Empty State Component
// Consistent empty states for lists and screens
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/pro/design_tokens.dart';

/// Predefined empty state types
enum EmptyStateType {
  invoices,
  customers,
  suppliers,
  products,
  categories,
  transactions,
  reports,
  search,
  alerts,
  generic,
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.compact = false,
  });

  const EmptyState.custom({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  }) : type = EmptyStateType.generic;

  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = _getTypeInfo(type);
    final displayIcon = icon ?? info.icon;
    final displayTitle = title ?? info.title;
    final displayMessage = message ?? info.message;

    if (compact) {
      return _buildCompact(displayIcon, displayTitle, displayMessage);
    }

    return _buildFull(displayIcon, displayTitle, displayMessage);
  }

  Widget _buildFull(IconData icon, String title, String message) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          _buildIllustration(icon),
          SizedBox(height: AppSpacing.xl.h),

          // Title
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm.h),

          // Message
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          // Action Button
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppSpacing.xl.h),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textOnSecondary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl.w,
                  vertical: AppSpacing.md.h,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(IconData icon, String title, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.xl.h,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              icon,
              color: AppColors.textTertiary,
              size: AppIconSize.xl,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xxxs.h),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }

  Widget _buildIllustration(IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
        ),
        // Decorative circles
        Positioned(
          top: 10.h,
          right: 10.w,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 15.h,
          left: 5.w,
          child: Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Main icon
        Icon(
          icon,
          color: AppColors.textTertiary,
          size: AppIconSize.huge,
        ),
      ],
    );
  }

  _EmptyStateInfo _getTypeInfo(EmptyStateType type) {
    return switch (type) {
      EmptyStateType.invoices => const _EmptyStateInfo(
          icon: Icons.receipt_long_outlined,
          title: 'لا توجد فواتير',
          message: 'لم يتم إنشاء أي فواتير بعد. ابدأ بإنشاء فاتورة جديدة.',
        ),
      EmptyStateType.customers => const _EmptyStateInfo(
          icon: Icons.people_outline_rounded,
          title: 'لا يوجد عملاء',
          message: 'لم يتم إضافة أي عملاء بعد. أضف عميلك الأول.',
        ),
      EmptyStateType.suppliers => const _EmptyStateInfo(
          icon: Icons.local_shipping_outlined,
          title: 'لا يوجد موردين',
          message: 'لم يتم إضافة أي موردين بعد. أضف موردك الأول.',
        ),
      EmptyStateType.products => const _EmptyStateInfo(
          icon: Icons.inventory_2_outlined,
          title: 'لا توجد منتجات',
          message: 'لم يتم إضافة أي منتجات بعد. أضف منتجك الأول.',
        ),
      EmptyStateType.categories => const _EmptyStateInfo(
          icon: Icons.category_outlined,
          title: 'لا توجد تصنيفات',
          message: 'لم يتم إنشاء أي تصنيفات بعد. أنشئ تصنيفك الأول.',
        ),
      EmptyStateType.transactions => const _EmptyStateInfo(
          icon: Icons.swap_horiz_rounded,
          title: 'لا توجد معاملات',
          message: 'لم تسجل أي معاملات في هذه الفترة.',
        ),
      EmptyStateType.reports => const _EmptyStateInfo(
          icon: Icons.bar_chart_outlined,
          title: 'لا توجد بيانات',
          message: 'لا توجد بيانات كافية لعرض التقرير.',
        ),
      EmptyStateType.search => const _EmptyStateInfo(
          icon: Icons.search_off_rounded,
          title: 'لا توجد نتائج',
          message: 'لم نجد نتائج مطابقة لبحثك. جرب كلمات مختلفة.',
        ),
      EmptyStateType.alerts => const _EmptyStateInfo(
          icon: Icons.notifications_off_outlined,
          title: 'لا توجد تنبيهات',
          message: 'كل شيء على ما يرام! لا توجد تنبيهات تحتاج انتباهك.',
        ),
      EmptyStateType.generic => const _EmptyStateInfo(
          icon: Icons.inbox_outlined,
          title: 'لا توجد بيانات',
          message: 'لا توجد بيانات لعرضها حالياً.',
        ),
    };
  }
}

class _EmptyStateInfo {
  const _EmptyStateInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

/// Error state widget
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            decoration: BoxDecoration(
              color: AppColors.expenseSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.expense,
              size: AppIconSize.huge,
            ),
          ),
          SizedBox(height: AppSpacing.xl.h),
          Text(
            'حدث خطأ',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.xl.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state placeholder
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xxl.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg.h),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

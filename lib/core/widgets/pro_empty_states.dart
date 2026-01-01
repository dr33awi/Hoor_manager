// ═══════════════════════════════════════════════════════════════════════════
// Pro Empty States
// Beautiful Empty State Widgets for Various Scenarios
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/design_tokens.dart';
import '../animations/pro_animations.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Generic Empty State
// ═══════════════════════════════════════════════════════════════════════════

class ProEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const ProEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.textTertiary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 56.sp,
                  color: iconColor ?? AppColors.textTertiary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search Empty State
// ═══════════════════════════════════════════════════════════════════════════

class SearchEmptyState extends StatelessWidget {
  final String searchTerm;
  final VoidCallback? onClearSearch;

  const SearchEmptyState({
    super.key,
    required this.searchTerm,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ProEmptyState(
      icon: Icons.search_off,
      title: 'لا توجد نتائج',
      subtitle: 'لم نجد نتائج تطابق "$searchTerm"\nجرب البحث بكلمات مختلفة',
      iconColor: AppColors.warning,
      actionLabel: onClearSearch != null ? 'مسح البحث' : null,
      onAction: onClearSearch,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Products Empty State
// ═══════════════════════════════════════════════════════════════════════════

class ProductsEmptyState extends StatelessWidget {
  final VoidCallback? onAddProduct;

  const ProductsEmptyState({
    super.key,
    this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return ProEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'لا توجد منتجات',
      subtitle: 'ابدأ بإضافة منتجاتك لتتمكن من إدارتها بسهولة',
      iconColor: AppColors.primary,
      actionLabel: 'إضافة منتج',
      onAction: onAddProduct,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Invoices Empty State
// ═══════════════════════════════════════════════════════════════════════════

class InvoicesEmptyState extends StatelessWidget {
  final VoidCallback? onCreateInvoice;

  const InvoicesEmptyState({
    super.key,
    this.onCreateInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return ProEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'لا توجد فواتير',
      subtitle: 'أنشئ فاتورتك الأولى لتتبع مبيعاتك',
      iconColor: AppColors.success,
      actionLabel: 'إنشاء فاتورة',
      onAction: onCreateInvoice,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Customers Empty State
// ═══════════════════════════════════════════════════════════════════════════

class CustomersEmptyState extends StatelessWidget {
  final VoidCallback? onAddCustomer;

  const CustomersEmptyState({
    super.key,
    this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return ProEmptyState(
      icon: Icons.people_outline,
      title: 'لا يوجد عملاء',
      subtitle: 'أضف عملاءك لتتمكن من إدارة حساباتهم',
      iconColor: AppColors.info,
      actionLabel: 'إضافة عميل',
      onAction: onAddCustomer,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error State
// ═══════════════════════════════════════════════════════════════════════════

class ErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48.sp,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                title ?? 'حدث خطأ',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              if (message != null) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Error State
// ═══════════════════════════════════════════════════════════════════════════

class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'لا يوجد اتصال',
      message: 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
      onRetry: onRetry,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading State
// ═══════════════════════════════════════════════════════════════════════════

class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48.w,
            height: 48.h,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg),
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

// ═══════════════════════════════════════════════════════════════════════════
// Coming Soon State
// ═══════════════════════════════════════════════════════════════════════════

class ComingSoonState extends StatelessWidget {
  final String feature;
  final String? description;

  const ComingSoonState({
    super.key,
    required this.feature,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  size: 56.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'قريباً',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                feature,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  description!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 18.sp,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'تحت التطوير',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

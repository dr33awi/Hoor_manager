// ═══════════════════════════════════════════════════════════════════════════
// Reports Screen Pro - Professional Design System
// Reports Hub with Modern UI
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pro/design_tokens.dart';

class ReportsScreenPro extends StatelessWidget {
  const ReportsScreenPro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
        ),
        title: Text(
          'التقارير',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon:
                Icon(Icons.date_range_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildQuickStats(),
            SizedBox(height: AppSpacing.lg),

            // Sales Reports
            _buildSectionTitle('تقارير المبيعات'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المبيعات',
              description: 'إجمالي المبيعات والإيرادات',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
              onTap: () => context.push('/reports/sales'),
            ),
            _ReportCard(
              title: 'تقرير المنتجات الأكثر مبيعاً',
              description: 'المنتجات حسب حجم المبيعات',
              icon: Icons.star_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.lg),

            // Purchase Reports
            _buildSectionTitle('تقارير المشتريات'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المشتريات',
              description: 'إجمالي المشتريات والتكاليف',
              icon: Icons.shopping_cart_rounded,
              color: AppColors.secondary,
              onTap: () => context.push('/reports/purchases'),
            ),

            SizedBox(height: AppSpacing.lg),

            // Financial Reports
            _buildSectionTitle('التقارير المالية'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير الأرباح والخسائر',
              description: 'صافي الربح والمصروفات',
              icon: Icons.analytics_rounded,
              color: AppColors.success,
              onTap: () => context.push('/reports/profit'),
            ),
            _ReportCard(
              title: 'تقرير الذمم المدينة',
              description: 'المبالغ المستحقة من العملاء',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.error,
              onTap: () => context.push('/reports/receivables'),
            ),
            _ReportCard(
              title: 'تقرير الذمم الدائنة',
              description: 'المبالغ المستحقة للموردين',
              icon: Icons.payments_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.lg),

            // Inventory Reports
            _buildSectionTitle('تقارير المخزون'),
            SizedBox(height: AppSpacing.md),
            _ReportCard(
              title: 'تقرير المخزون',
              description: 'الكميات والقيم الحالية',
              icon: Icons.inventory_2_rounded,
              color: AppColors.secondary,
              onTap: () {},
            ),
            _ReportCard(
              title: 'تقرير المخزون المنخفض',
              description: 'المنتجات التي تحتاج إعادة طلب',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              onTap: () {},
            ),

            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الشهر الحالي',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  label: 'المبيعات',
                  value: '125,000',
                  icon: Icons.arrow_upward_rounded,
                  trend: '+12%',
                  isPositive: true,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'المشتريات',
                  value: '85,000',
                  icon: Icons.arrow_downward_rounded,
                  trend: '+5%',
                  isPositive: false,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  label: 'صافي الربح',
                  value: '40,000',
                  icon: Icons.trending_up_rounded,
                  trend: '+18%',
                  isPositive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required IconData icon,
    required String trend,
    required bool isPositive,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12.sp,
                color: Colors.white,
              ),
              SizedBox(width: 2.w),
              Text(
                trend,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: AppIconSize.md),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Report Detail Screen Pro - Placeholder
// ═══════════════════════════════════════════════════════════════════════════

class ReportDetailScreenPro extends StatelessWidget {
  final String reportType;

  const ReportDetailScreenPro({
    super.key,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    switch (reportType) {
      case 'sales':
        title = 'تقرير المبيعات';
        break;
      case 'purchases':
        title = 'تقرير المشتريات';
        break;
      case 'profit':
        title = 'تقرير الأرباح والخسائر';
        break;
      case 'receivables':
        title = 'تقرير الذمم المدينة';
        break;
      default:
        title = 'تقرير';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
        ),
        title: Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.download_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 80.sp,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'قريباً',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'تفاصيل التقرير قيد التطوير',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

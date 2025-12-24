// lib/features/home/screens/home_screen.dart
// الشاشة الرئيسية - تصميم محسّن

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/user_management_screen.dart';
import '../../products/providers/product_provider.dart';
import '../../products/screens/products_screen.dart';
import '../../sales/providers/sale_provider.dart';
import '../../sales/screens/sales_screen.dart';
import '../../sales/screens/new_sale_screen.dart';
import '../../reports/screens/reports_screen.dart';
import 'dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(),
    const NewSaleScreen(),
    const SalesScreen(),
    const ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final productProvider = context.read<ProductProvider>();
    final saleProvider = context.read<SaleProvider>();
    await Future.wait([productProvider.loadAll(), saleProvider.loadSales()]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(authProvider),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _getTitle(),
          key: ValueKey(_currentIndex),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      centerTitle: true,
      actions: [_buildProfileMenu(authProvider), const SizedBox(width: 8)],
    );
  }

  Widget _buildProfileMenu(AuthProvider authProvider) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      icon: Hero(
        tag: 'profile_avatar',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: authProvider.userPhoto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    authProvider.userPhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                )
              : const Icon(Icons.person, size: 18, color: Colors.white),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.userName ?? 'المستخدم',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoleBadge(
                    label: authProvider.isAdmin ? 'مدير' : 'موظف',
                    isAdmin: authProvider.isAdmin,
                  ),
                  if (authProvider.isGoogleUser) ...[
                    const SizedBox(width: 6),
                    _GoogleBadge(),
                  ],
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (authProvider.isAdmin)
          _buildMenuItem(
            icon: Icons.people_outline,
            label: 'إدارة المستخدمين',
            value: 'users',
          ),
        _buildMenuItem(
          icon: Icons.person_outline,
          label: 'الملف الشخصي',
          value: 'profile',
        ),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          label: 'الإعدادات',
          value: 'settings',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          icon: Icons.logout_rounded,
          label: 'تسجيل الخروج',
          value: 'logout',
          color: AppColors.error,
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'logout':
            final confirm = await _showLogoutDialog();
            if (confirm == true) await authProvider.signOut();
            break;
          case 'settings':
          case 'profile':
            _showComingSoon(value == 'settings' ? 'الإعدادات' : 'الملف الشخصي');
            break;
          case 'users':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            );
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: _currentIndex,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'الرئيسية',
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                index: 1,
                currentIndex: _currentIndex,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'المنتجات',
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _buildMainButton(),
              _NavItem(
                index: 3,
                currentIndex: _currentIndex,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'الفواتير',
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavItem(
                index: 4,
                currentIndex: _currentIndex,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'التقارير',
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      onTapDown: (_) => _fabAnimationController.forward(),
      onTapUp: (_) {
        _fabAnimationController.reverse();
        setState(() => _currentIndex = 2);
      },
      onTapCancel: () => _fabAnimationController.reverse(),
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [AppColors.success, const Color(0xFF059669)]
                  : [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isSelected ? Icons.receipt_rounded : Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'المنتجات';
      case 2:
        return 'فاتورة جديدة';
      case 3:
        return 'الفواتير';
      case 4:
        return 'التقارير';
      default:
        return 'مدير المبيعات';
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('$feature - قريباً!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.errorLight,
                      AppColors.error.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'خروج',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Widgets الداخلية =================

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final bool isAdmin;

  const _RoleBadge({required this.label, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isAdmin
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isAdmin ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AppColors.primary : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.google.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.g_mobiledata, size: 14, color: AppColors.google),
    );
  }
}

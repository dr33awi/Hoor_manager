// lib/features/home/screens/home_screen.dart
// الشاشة الرئيسية - تصميم حديث

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(authProvider),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        _getTitle(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
      centerTitle: true,
      actions: [
        if (authProvider.isAdmin)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 20,
                color: Color(0xFF1A1A2E),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 20,
              color: Color(0xFF1A1A2E),
            ),
          ),
          onPressed: _loadData,
        ),
        _buildProfileMenu(authProvider),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileMenu(AuthProvider authProvider) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: authProvider.isAdmin
                          ? const Color(0xFF1A1A2E).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      authProvider.isAdmin ? 'مدير' : 'موظف',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: authProvider.isAdmin
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (authProvider.isGoogleUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.g_mobiledata,
                        size: 14,
                        color: Color(0xFFEA4335),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (authProvider.isAdmin)
          PopupMenuItem(
            value: 'users',
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 12),
                const Text('إدارة المستخدمين'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              const Text('الملف الشخصي'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              const Text('الإعدادات'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
              SizedBox(width: 12),
              Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.dashboard_outlined,
                Icons.dashboard_rounded,
                'الرئيسية',
              ),
              _buildNavItem(
                1,
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded,
                'المنتجات',
              ),
              _buildNavItem(
                2,
                Icons.add_shopping_cart_outlined,
                Icons.add_shopping_cart_rounded,
                'بيع',
                isMain: true,
              ),
              _buildNavItem(
                3,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'الفواتير',
              ),
              _buildNavItem(
                4,
                Icons.bar_chart_outlined,
                Icons.bar_chart_rounded,
                'التقارير',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isMain = false,
  }) {
    final isSelected = _currentIndex == index;

    if (isMain) {
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A1A2E).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF1A1A2E)
                  : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey.shade400,
              ),
            ),
          ],
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
        content: Text('$feature - قريباً!'),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('خروج'),
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

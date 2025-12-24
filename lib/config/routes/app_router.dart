import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/screens.dart';
import '../../features/products/presentation/screens/screens.dart';
import '../../features/sales/presentation/screens/screens.dart';
import '../../features/reports/presentation/screens/screens.dart';
import '../../features/home/presentation/screens/screens.dart';
import '../../features/settings/presentation/screens/screens.dart';

/// مسارات التطبيق
class AppRoutes {
  AppRoutes._();

  // المسارات الرئيسية
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending-approval';

  // المسارات الرئيسية بعد تسجيل الدخول
  static const String home = '/home';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit/:id';
  static const String productDetails = '/products/:id';

  static const String sales = '/sales';
  static const String newSale = '/sales/new';
  static const String invoiceDetails = '/sales/:id';

  static const String reports = '/reports';
  static const String salesReport = '/reports/sales';
  static const String profitsReport = '/reports/profits';
  static const String inventoryReport = '/reports/inventory';
  static const String topProducts = '/reports/top-products';

  static const String settings = '/settings';
  static const String users = '/users';
}

/// إعداد التوجيه
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        name: 'pendingApproval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // Main App Routes (will be wrapped with ShellRoute later)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),

      // Products Routes
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        builder: (context, state) => const ProductsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'addProduct',
            builder: (context, state) => const AddEditProductScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'editProduct',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddEditProductScreen(productId: id);
            },
          ),
          GoRoute(
            path: ':id',
            name: 'productDetails',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailsScreen(productId: id);
            },
          ),
        ],
      ),

      // Sales Routes
      GoRoute(
        path: AppRoutes.sales,
        name: 'sales',
        builder: (context, state) => const SalesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'newSale',
            builder: (context, state) => const NewSaleScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'invoiceDetails',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailsScreen(invoiceId: id);
            },
          ),
        ],
      ),

      // Reports Routes
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
        routes: [
          GoRoute(
            path: 'sales',
            name: 'salesReport',
            builder: (context, state) => const SalesReportScreen(),
          ),
          GoRoute(
            path: 'profits',
            name: 'profitsReport',
            builder: (context, state) => const ProfitsReportScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventoryReport',
            builder: (context, state) => const InventoryReportScreen(),
          ),
          GoRoute(
            path: 'top-products',
            name: 'topProducts',
            builder: (context, state) => const TopProductsScreen(),
          ),
        ],
      ),

      // Settings Route
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Users Management Route
      GoRoute(
        path: AppRoutes.users,
        name: 'users',
        builder: (context, state) => const UsersManagementScreen(),
      ),
    ],

    // Error Page
    errorBuilder: (context, state) => _PlaceholderScreen(
      title: 'خطأ: ${state.error?.message ?? "الصفحة غير موجودة"}',
    ),
  );
}

/// شاشة مؤقتة للتطوير
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'قيد التطوير',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

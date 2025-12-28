import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/product_details_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/invoices/presentation/invoice_form_screen.dart';
import '../../features/invoices/presentation/invoice_details_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/inventory/presentation/inventory_count_screen.dart';
import '../../features/shifts/presentation/shifts_screen.dart';
import '../../features/shifts/presentation/shift_details_screen.dart';
import '../../features/cash/presentation/cash_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/sales_report_screen.dart';
import '../../features/reports/presentation/products_report_screen.dart';
import '../../features/reports/presentation/inventory_report_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Home
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Products
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'product-add',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'product-edit',
            builder: (context, state) => ProductFormScreen(
              productId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'product-details',
            builder: (context, state) => ProductDetailsScreen(
              productId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Categories
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),

      // Invoices
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => InvoicesScreen(
          type: state.uri.queryParameters['type'],
        ),
        routes: [
          GoRoute(
            path: 'new/:type',
            name: 'invoice-new',
            builder: (context, state) => InvoiceFormScreen(
              type: state.pathParameters['type']!,
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'invoice-details',
            builder: (context, state) => InvoiceDetailsScreen(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Inventory
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'count',
            name: 'inventory-count',
            builder: (context, state) => const InventoryCountScreen(),
          ),
        ],
      ),

      // Shifts
      GoRoute(
        path: '/shifts',
        name: 'shifts',
        builder: (context, state) => const ShiftsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'shift-details',
            builder: (context, state) => ShiftDetailsScreen(
              shiftId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Cash
      GoRoute(
        path: '/cash',
        name: 'cash',
        builder: (context, state) => const CashScreen(),
      ),

      // Reports
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
        routes: [
          GoRoute(
            path: 'sales',
            name: 'sales-report',
            builder: (context, state) => const SalesReportScreen(),
          ),
          GoRoute(
            path: 'products',
            name: 'products-report',
            builder: (context, state) => const ProductsReportScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventory-report',
            builder: (context, state) => const InventoryReportScreen(),
          ),
        ],
      ),

      // Customers
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersScreen(),
      ),

      // Suppliers
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        builder: (context, state) => const SuppliersScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Backup
      GoRoute(
        path: '/backup',
        name: 'backup',
        builder: (context, state) => const BackupScreen(),
      ),
    ],
  );
});

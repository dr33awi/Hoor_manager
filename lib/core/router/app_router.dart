/// ═══════════════════════════════════════════════════════════════════════════
/// App Router - Modern Design System
/// Navigation Configuration
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Main Screens
import '../../features/home/presentation/redesign/dashboard_screen.dart';
import '../../features/products/presentation/redesign/products_screen_redesign.dart';
import '../../features/invoices/presentation/redesign/invoices_screen_redesign.dart';
import '../../features/customers/presentation/redesign/customers_screen_redesign.dart';
import '../../features/suppliers/presentation/redesign/suppliers_screen_redesign.dart';
import '../../features/reports/presentation/redesign/reports_screen_redesign.dart';
import '../../features/settings/presentation/redesign/settings_screen_redesign.dart';
import '../../features/shifts/presentation/redesign/shifts_screen_redesign.dart';
import '../../features/cash/presentation/redesign/cash_screen_redesign.dart';
import '../../features/vouchers/presentation/redesign/vouchers_screen_redesign.dart';
import '../../features/categories/presentation/redesign/categories_screen_redesign.dart';
import '../../features/inventory/presentation/redesign/inventory_screen_redesign.dart';

// Detail Screens
import '../../features/products/presentation/redesign/product_form_screen_redesign.dart';
import '../../features/products/presentation/redesign/product_details_screen_redesign.dart';
import '../../features/invoices/presentation/redesign/invoice_form_screen_redesign.dart';
import '../../features/invoices/presentation/redesign/invoice_details_screen_redesign.dart';
import '../../features/inventory/presentation/redesign/inventory_count_screen_redesign.dart';
import '../../features/inventory/presentation/redesign/stock_transfer_screen_redesign.dart';
import '../../features/inventory/presentation/redesign/warehouses_screen_redesign.dart';
import '../../features/shifts/presentation/redesign/shift_details_screen_redesign.dart';
import '../../features/reports/presentation/redesign/sales_report_screen_redesign.dart';
import '../../features/reports/presentation/redesign/inventory_report_screen_redesign.dart';
import '../../features/reports/presentation/redesign/receivables_report_screen_redesign.dart';
import '../../features/reports/presentation/redesign/payables_report_screen_redesign.dart';
import '../../features/reports/presentation/redesign/profit_loss_report_screen_redesign.dart';
import '../../features/settings/presentation/redesign/print_settings_screen_redesign.dart';
import '../../features/backup/presentation/redesign/backup_screen_redesign.dart';
import '../../features/alerts/redesign/alerts_screen_redesign.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ═══════════════════════════════════════════════════════════════════
      // Dashboard (Home)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Products
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductsScreenRedesign(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'product-add',
            builder: (context, state) => const ProductFormScreenRedesign(),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'product-edit',
            builder: (context, state) => ProductFormScreenRedesign(
              productId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'product-details',
            builder: (context, state) => ProductDetailsScreenRedesign(
              productId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Categories
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices - Sales
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/sales',
        name: 'sales',
        builder: (context, state) => const InvoicesScreenRedesign(type: 'sale'),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices - Purchases
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/purchases',
        name: 'purchases',
        builder: (context, state) =>
            const InvoicesScreenRedesign(type: 'purchase'),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices (Generic route)
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => InvoicesScreenRedesign(
          type: state.uri.queryParameters['type'],
        ),
        routes: [
          GoRoute(
            path: 'new/:type',
            name: 'invoice-new',
            builder: (context, state) => InvoiceFormScreenRedesign(
              type: state.pathParameters['type']!,
            ),
          ),
          GoRoute(
            path: 'edit/:id/:type',
            name: 'invoice-edit',
            builder: (context, state) => InvoiceFormScreenRedesign(
              type: state.pathParameters['type']!,
              invoiceId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: 'details/:id',
            name: 'invoice-details',
            builder: (context, state) => InvoiceDetailsScreenRedesign(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Inventory
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) => const InventoryScreenRedesign(),
        routes: [
          GoRoute(
            path: 'count',
            name: 'inventory-count',
            builder: (context, state) => const InventoryCountScreenRedesign(),
          ),
          GoRoute(
            path: 'transfer',
            name: 'stock-transfer',
            builder: (context, state) => const StockTransferScreenRedesign(),
          ),
          GoRoute(
            path: 'transfer/new',
            name: 'new-stock-transfer',
            builder: (context, state) => const NewStockTransferScreenRedesign(),
          ),
          GoRoute(
            path: 'warehouses',
            name: 'warehouses',
            builder: (context, state) => const WarehousesScreenRedesign(),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Shifts
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/shifts',
        name: 'shifts',
        builder: (context, state) => const ShiftsScreenRedesign(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'shift-details',
            builder: (context, state) => ShiftDetailsScreenRedesign(
              shiftId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Cash
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/cash',
        name: 'cash',
        builder: (context, state) => const CashScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Vouchers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/vouchers',
        name: 'vouchers',
        builder: (context, state) => const VouchersScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Reports
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreenRedesign(),
        routes: [
          GoRoute(
            path: 'sales',
            name: 'sales-report',
            builder: (context, state) => const SalesReportScreenRedesign(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventory-report',
            builder: (context, state) => const InventoryReportScreenRedesign(),
          ),
          GoRoute(
            path: 'receivables',
            name: 'receivables-report',
            builder: (context, state) =>
                const ReceivablesReportScreenRedesign(),
          ),
          GoRoute(
            path: 'payables',
            name: 'payables-report',
            builder: (context, state) => const PayablesReportScreenRedesign(),
          ),
          GoRoute(
            path: 'profit-loss',
            name: 'profit-loss-report',
            builder: (context, state) => const ProfitLossReportScreenRedesign(),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Customers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Suppliers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        builder: (context, state) => const SuppliersScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Settings
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreenRedesign(),
        routes: [
          GoRoute(
            path: 'print',
            name: 'print-settings',
            builder: (context, state) => const PrintSettingsScreenRedesign(),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Backup
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/backup',
        name: 'backup',
        builder: (context, state) => const BackupScreenRedesign(),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Alerts
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsScreenRedesign(),
      ),
    ],
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// App Router Pro - Modern Design System
// Navigation Configuration with Pro Dashboard
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Pro Dashboard
import '../../features/dashboard_pro/dashboard_pro.dart';

// Pro Screens
import '../../features/products_pro/products_screen_pro.dart';
import '../../features/products_pro/product_form_screen_pro.dart';
import '../../features/products_pro/product_details_screen_pro.dart';
import '../../features/invoices_pro/invoices_screen_pro.dart';
import '../../features/invoices_pro/invoice_form_screen_pro.dart';
import '../../features/invoices_pro/invoice_details_screen_pro.dart';
import '../../features/customers_pro/customers_screen_pro.dart';
import '../../features/customers_pro/customer_form_screen_pro.dart';
import '../../features/suppliers_pro/suppliers_screen_pro.dart';
import '../../features/reports_pro/reports_screen_pro.dart';
import '../../features/settings_pro/settings_screen_pro.dart';
import '../../features/shifts_pro/shifts_screen_pro.dart';
import '../../features/vouchers_pro/vouchers_screen_pro.dart';
import '../../features/alerts_pro/alerts_screen_pro.dart';
import '../../features/sales_pro/sales_screen_pro.dart';
import '../../features/purchases_pro/purchases_screen_pro.dart';

/// Provider for the app router
final appRouterProProvider = Provider<GoRouter>((ref) {
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardPro(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Products
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/products',
        name: 'products',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const ProductsScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'product-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const ProductFormScreenPro(),
            ),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'product-edit',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              ProductFormScreenPro(productId: state.pathParameters['id']),
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'product-details',
            pageBuilder: (context, state) => _buildSlideTransition(
              state,
              ProductDetailsScreenPro(productId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices - Sales
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/sales',
        name: 'sales',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const SalesScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'sales-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const InvoiceFormScreenPro(type: 'sale'),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices - Purchases
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/purchases',
        name: 'purchases',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const PurchasesScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'purchases-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const InvoiceFormScreenPro(type: 'purchase'),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices List
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const InvoicesScreenPro(),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Invoices Details
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/invoices/:id',
        name: 'invoice-details',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          InvoiceDetailsScreenPro(invoiceId: state.pathParameters['id']!),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Customers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/customers',
        name: 'customers',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const CustomersScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'add',
            name: 'customer-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const CustomerFormScreenPro(),
            ),
          ),
          GoRoute(
            path: 'edit/:id',
            name: 'customer-edit',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              CustomerFormScreenPro(customerId: state.pathParameters['id']),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Suppliers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const SuppliersScreenPro(),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Vouchers
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/vouchers',
        name: 'vouchers',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const VouchersScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'receipt/add',
            name: 'receipt-voucher-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const VoucherFormScreenPro(type: 'receipt'),
            ),
          ),
          GoRoute(
            path: 'payment/add',
            name: 'payment-voucher-add',
            pageBuilder: (context, state) => _buildSlideUpTransition(
              state,
              const VoucherFormScreenPro(type: 'payment'),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Shifts
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/shifts',
        name: 'shifts',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const ShiftsScreenPro(),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Reports
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/reports',
        name: 'reports',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const ReportsScreenPro(),
        ),
        routes: [
          GoRoute(
            path: 'sales',
            name: 'sales-report',
            pageBuilder: (context, state) => _buildSlideTransition(
              state,
              const ReportDetailScreenPro(reportType: 'sales'),
            ),
          ),
          GoRoute(
            path: 'purchases',
            name: 'purchases-report',
            pageBuilder: (context, state) => _buildSlideTransition(
              state,
              const ReportDetailScreenPro(reportType: 'purchases'),
            ),
          ),
          GoRoute(
            path: 'profit',
            name: 'profit-report',
            pageBuilder: (context, state) => _buildSlideTransition(
              state,
              const ReportDetailScreenPro(reportType: 'profit'),
            ),
          ),
          GoRoute(
            path: 'receivables',
            name: 'receivables-report',
            pageBuilder: (context, state) => _buildSlideTransition(
              state,
              const ReportDetailScreenPro(reportType: 'receivables'),
            ),
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Settings
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const SettingsScreenPro(),
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════
      // Alerts
      // ═══════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        pageBuilder: (context, state) => _buildSlideTransition(
          state,
          const AlertsScreenPro(),
        ),
      ),
    ],
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// Custom Page Transitions
// ═══════════════════════════════════════════════════════════════════════════

CustomTransitionPage _buildSlideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

CustomTransitionPage _buildSlideUpTransition(
    GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

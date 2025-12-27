import 'package:flutter/material.dart';

// Features
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/invoices/presentation/pages/sales_invoice_page.dart';
import '../../features/invoices/presentation/pages/purchase_invoice_page.dart';
import '../../features/invoices/presentation/pages/returns_page.dart';
import '../../features/invoices/presentation/pages/sales_list_page.dart';
import '../../features/invoices/presentation/pages/purchases_list_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/categories_page.dart';
import '../../features/inventory/presentation/pages/inventory_count_page.dart';
import '../../features/inventory/presentation/pages/opening_balance_page.dart';
import '../../features/inventory/presentation/pages/price_update_page.dart';
import '../../features/accounts/presentation/pages/customers_page.dart';
import '../../features/accounts/presentation/pages/suppliers_page.dart';
import '../../features/accounts/presentation/pages/voucher_page.dart';
import '../../features/accounts/presentation/pages/cash_accounts_page.dart';
import '../../features/accounts/presentation/pages/accounts_tree_page.dart';
import '../../features/queries/presentation/pages/account_movement_page.dart';
import '../../features/queries/presentation/pages/product_movement_page.dart';
import '../../features/queries/presentation/pages/daily_movement_page.dart';
import '../../features/queries/presentation/pages/price_inquiry_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/debts/presentation/pages/payables_page.dart';
import '../../features/reports/presentation/pages/movement_summary_page.dart';
import '../../features/reports/presentation/pages/profit_loss_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/print_settings_page.dart';

/// أسماء المسارات
class AppRoutes {
  // الرئيسية
  static const String home = '/';
  
  // الفواتير
  static const String salesInvoice = '/invoices/sales';
  static const String purchaseInvoice = '/invoices/purchase';
  static const String returns = '/invoices/returns';
  static const String salesList = '/invoices/sales-list';
  static const String purchasesList = '/invoices/purchases-list';
  static const String salesReturnsList = '/invoices/sales-returns';
  static const String purchaseReturnsList = '/invoices/purchase-returns';
  
  // المواد
  static const String products = '/products';
  static const String productForm = '/products/form';
  static const String categories = '/products/categories';
  
  // المخزون
  static const String inventoryCount = '/inventory/count';
  static const String openingBalance = '/inventory/opening';
  static const String priceUpdate = '/inventory/price-update';
  
  // الحسابات
  static const String customers = '/accounts/customers';
  static const String suppliers = '/accounts/suppliers';
  static const String voucher = '/accounts/voucher';
  static const String cashAccounts = '/accounts/cash';
  static const String accountsTree = '/accounts/tree';
  
  // الاستعلامات
  static const String priceInquiry = '/queries/price';
  static const String accountMovement = '/queries/account';
  static const String productMovement = '/queries/product';
  static const String dailyMovement = '/queries/daily';
  static const String totalProductMovement = '/queries/total-products';
  
  // الديون
  static const String debts = '/debts';
  static const String payables = '/payables';
  
  // التقارير
  static const String movementSummary = '/reports/summary';
  static const String profitLoss = '/reports/profit-loss';
  
  // الإعدادات
  static const String settings = '/settings';
  static const String printSettings = '/settings/print';
}

/// موجه التطبيق
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // استخراج الوسائط
    final args = settings.arguments;
    
    switch (settings.name) {
      // الرئيسية
      case AppRoutes.home:
        return _buildRoute(const HomePage());
      
      // الفواتير
      case AppRoutes.salesInvoice:
        return _buildRoute(SalesInvoicePage(
          invoiceId: args is String ? args : null,
        ));
      
      case AppRoutes.purchaseInvoice:
        return _buildRoute(PurchaseInvoicePage(
          invoiceId: args is String ? args : null,
        ));
      
      case AppRoutes.returns:
        return _buildRoute(ReturnsPage(
          type: args is String ? args : 'sale',
        ));
      
      case AppRoutes.salesList:
        return _buildRoute(const SalesListPage());
      
      case AppRoutes.purchasesList:
        return _buildRoute(const PurchasesListPage());
      
      case AppRoutes.salesReturnsList:
        return _buildRoute(const SalesListPage(isReturns: true));
      
      case AppRoutes.purchaseReturnsList:
        return _buildRoute(const PurchasesListPage(isReturns: true));
      
      // المواد
      case AppRoutes.products:
        return _buildRoute(const ProductsPage());
      
      case AppRoutes.productForm:
        return _buildRoute(ProductFormPage(
          productId: args is String ? args : null,
        ));
      
      case AppRoutes.categories:
        return _buildRoute(const CategoriesPage());
      
      // المخزون
      case AppRoutes.inventoryCount:
        return _buildRoute(const InventoryCountPage());
      
      case AppRoutes.openingBalance:
        return _buildRoute(const OpeningBalancePage());
      
      case AppRoutes.priceUpdate:
        return _buildRoute(const PriceUpdatePage());
      
      // الحسابات
      case AppRoutes.customers:
        return _buildRoute(const CustomersPage());
      
      case AppRoutes.suppliers:
        return _buildRoute(const SuppliersPage());
      
      case AppRoutes.voucher:
        return _buildRoute(VoucherPage(
          type: args is String ? args : 'receipt',
        ));
      
      case AppRoutes.cashAccounts:
        return _buildRoute(const CashAccountsPage());
      
      case AppRoutes.accountsTree:
        return _buildRoute(const AccountsTreePage());
      
      // الاستعلامات
      case AppRoutes.priceInquiry:
        return _buildRoute(const PriceInquiryPage());
      
      case AppRoutes.accountMovement:
        return _buildRoute(const AccountMovementPage());
      
      case AppRoutes.productMovement:
        return _buildRoute(const ProductMovementPage());
      
      case AppRoutes.dailyMovement:
        return _buildRoute(const DailyMovementPage());
      
      // الديون
      case AppRoutes.debts:
        return _buildRoute(const DebtsPage());
      
      case AppRoutes.payables:
        return _buildRoute(const PayablesPage());
      
      // التقارير
      case AppRoutes.movementSummary:
        return _buildRoute(const MovementSummaryPage());
      
      case AppRoutes.profitLoss:
        return _buildRoute(const ProfitLossPage());
      
      // الإعدادات
      case AppRoutes.settings:
        return _buildRoute(const SettingsPage());
      
      case AppRoutes.printSettings:
        return _buildRoute(const PrintSettingsPage());
      
      // صفحة غير موجودة
      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'الصفحة غير موجودة',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.name ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
  
  /// بناء المسار مع التأثيرات
  static MaterialPageRoute<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
    );
  }
  
  /// التنقل للصفحة
  static Future<T?> navigateTo<T>(BuildContext context, String route, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, route, arguments: arguments);
  }
  
  /// التنقل مع استبدال الصفحة الحالية
  static Future<T?> navigateAndReplace<T>(BuildContext context, String route, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, route, arguments: arguments);
  }
  
  /// التنقل مع مسح كل الصفحات السابقة
  static Future<T?> navigateAndClearStack<T>(BuildContext context, String route, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      route,
      (route) => false,
      arguments: arguments,
    );
  }
  
  /// الرجوع للصفحة السابقة
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}

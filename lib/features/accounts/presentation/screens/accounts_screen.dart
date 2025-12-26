import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/entities.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card.dart';
import '../widgets/journal_entry_card.dart';
import '../widgets/account_stats_card.dart';

/// شاشة الحسابات الرئيسية
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  AccountType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحسابات'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
            Tab(text: 'شجرة الحسابات', icon: Icon(Icons.account_tree)),
            Tab(text: 'القيود', icon: Icon(Icons.receipt_long)),
            Tab(text: 'التقارير', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartOfAccountsTab(),
          _buildJournalEntriesTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildOverviewTab() {
    final statsAsync = ref.watch(accountStatsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsAsync.when(
            data: (stats) => AccountStatsCard(stats: stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('خطأ: $error'),
          ),
          SizedBox(height: 16.h),

          // القيود المعلقة
          _buildSectionHeader('القيود المعلقة', Icons.pending_actions),
          SizedBox(height: 8.h),
          Consumer(
            builder: (context, ref, child) {
              final draftAsync = ref.watch(draftEntriesProvider);
              return draftAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('خطأ: $error'),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8.w),
                            const Text('لا توجد قيود معلقة'),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: entries
                        .take(5)
                        .map((entry) => JournalEntryCard(entry: entry))
                        .toList(),
                  );
                },
              );
            },
          ),
          SizedBox(height: 16.h),

          // آخر القيود المرحّلة
          _buildSectionHeader('آخر القيود المرحّلة', Icons.history),
          SizedBox(height: 8.h),
          Consumer(
            builder: (context, ref, child) {
              final postedAsync = ref.watch(postedEntriesProvider);
              return postedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('خطأ: $error'),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: const Text('لا توجد قيود مرحّلة'),
                      ),
                    );
                  }
                  return Column(
                    children: entries
                        .take(5)
                        .map((entry) => JournalEntryCard(entry: entry))
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartOfAccountsTab() {
    return Column(
      children: [
        // فلتر نوع الحساب
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                SizedBox(width: 8.w),
                ...AccountType.values.map((type) => Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: FilterChip(
                        label: Text(type.arabicName),
                        selected: _selectedType == type,
                        onSelected: (_) => setState(() => _selectedType = type),
                        avatar: Icon(type.icon, size: 18.sp),
                        selectedColor: type.color.withValues(alpha: 0.2),
                      ),
                    )),
              ],
            ),
          ),
        ),

        // قائمة الحسابات
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final accountsAsync = _selectedType == null
                  ? ref.watch(accountsProvider)
                  : ref.watch(accountsByTypeProvider(_selectedType!));

              return accountsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('خطأ: $error')),
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_tree,
                              size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد حسابات',
                            style:
                                TextStyle(fontSize: 18.sp, color: Colors.grey),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            onPressed: _showAddAccountDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة حساب'),
                          ),
                        ],
                      ),
                    );
                  }

                  // ترتيب الحسابات حسب الكود
                  accounts.sort((a, b) => a.code.compareTo(b.code));

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(accountsProvider),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return AccountCard(
                          account: account,
                          onTap: () => _showAccountDetails(account),
                          onEdit: () => _showEditAccountDialog(account),
                          onDelete: account.isParent
                              ? null
                              : () => _confirmDeleteAccount(account),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJournalEntriesTab() {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('خطأ: $error')),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد قيود',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _showAddJournalEntryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قيد'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(journalEntriesProvider),
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return JournalEntryCard(
                entry: entry,
                onTap: () => _showEntryDetails(entry),
                onPost: entry.status == JournalEntryStatus.draft
                    ? () => _postEntry(entry)
                    : null,
                onReverse: entry.status == JournalEntryStatus.posted
                    ? () => _reverseEntry(entry)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // ميزان المراجعة
          Card(
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.balance, color: Colors.blue),
              ),
              title: const Text('ميزان المراجعة'),
              subtitle: const Text('عرض أرصدة جميع الحسابات'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showTrialBalance(),
            ),
          ),
          SizedBox(height: 12.h),

          // كشف حساب
          Card(
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.list_alt, color: Colors.green),
              ),
              title: const Text('كشف حساب'),
              subtitle: const Text('عرض حركات حساب معين'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAccountLedger(),
            ),
          ),
          SizedBox(height: 12.h),

          // قائمة الدخل
          Card(
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.trending_up, color: Colors.purple),
              ),
              title: const Text('قائمة الدخل'),
              subtitle: const Text('الإيرادات والمصروفات'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showIncomeStatement(),
            ),
          ),
          SizedBox(height: 12.h),

          // الميزانية العمومية
          Card(
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.account_balance, color: Colors.orange),
              ),
              title: const Text('الميزانية العمومية'),
              subtitle: const Text('الأصول والخصوم وحقوق الملكية'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showBalanceSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        switch (_tabController.index) {
          case 1:
            _showAddAccountDialog();
            break;
          case 2:
            _showAddJournalEntryDialog();
            break;
          default:
            _showQuickActionsSheet();
        }
      },
      icon: const Icon(Icons.add),
      label: Text(_getFABLabel()),
    );
  }

  String _getFABLabel() {
    switch (_tabController.index) {
      case 1:
        return 'حساب جديد';
      case 2:
        return 'قيد جديد';
      default:
        return 'إجراء سريع';
    }
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('إضافة حساب'),
              onTap: () {
                Navigator.pop(context);
                _showAddAccountDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('إضافة قيد'),
              onTap: () {
                Navigator.pop(context);
                _showAddJournalEntryDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    var type = AccountType.asset;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حساب جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration:
                        const InputDecoration(labelText: 'كود الحساب *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'الكود مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'اسم الحساب *'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<AccountType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'نوع الحساب'),
                    items: AccountType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(t.icon, size: 20.sp, color: t.color),
                                  SizedBox(width: 8.w),
                                  Text(t.arabicName),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => type = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final notifier = ref.read(accountNotifierProvider.notifier);
                  final account = AccountEntity(
                    id: '',
                    code: codeController.text,
                    name: nameController.text,
                    type: type,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await notifier.createAccount(account);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الحساب بنجاح')),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(AccountEntity account) {
    // TODO: Implement edit account dialog
  }

  void _confirmDeleteAccount(AccountEntity account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text('هل أنت متأكد من حذف حساب "${account.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(accountNotifierProvider.notifier);
              final success = await notifier.deleteAccount(account.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'تم حذف الحساب بنجاح' : 'فشل في حذف الحساب'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAccountDetails(AccountEntity account) {
    // TODO: Navigate to account details
  }

  void _showAddJournalEntryDialog() {
    // TODO: Show add journal entry dialog
  }

  void _showEntryDetails(JournalEntryEntity entry) {
    // TODO: Navigate to entry details
  }

  void _postEntry(JournalEntryEntity entry) async {
    final notifier = ref.read(journalEntryNotifierProvider.notifier);
    final success = await notifier.postEntry(
      id: entry.id,
      postedBy: 'current_user', // TODO: Get current user
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'تم ترحيل القيد بنجاح' : 'فشل في ترحيل القيد'),
        ),
      );
    }
  }

  void _reverseEntry(JournalEntryEntity entry) async {
    final notifier = ref.read(journalEntryNotifierProvider.notifier);
    final reversal = await notifier.reverseEntry(
      id: entry.id,
      reversedBy: 'current_user', // TODO: Get current user
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              reversal != null ? 'تم عكس القيد بنجاح' : 'فشل في عكس القيد'),
        ),
      );
    }
  }

  void _showTrialBalance() {
    // TODO: Navigate to trial balance report
  }

  void _showAccountLedger() {
    // TODO: Navigate to account ledger
  }

  void _showIncomeStatement() {
    // TODO: Navigate to income statement
  }

  void _showBalanceSheet() {
    // TODO: Navigate to balance sheet
  }
}

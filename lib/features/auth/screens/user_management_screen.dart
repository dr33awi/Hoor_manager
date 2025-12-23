// lib/features/auth/screens/user_management_screen.dart
// شاشة إدارة المستخدمين (للمدير فقط) - مُصححة

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  List<UserModel> _pendingUsers = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.d('=== جاري تحميل المستخدمين ===');

      // جلب المستخدمين المعلقين مباشرة من Firestore
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('accountStatus', isEqualTo: 'pending')
          .get();

      AppLogger.d('عدد المستخدمين المعلقين: ${pendingSnapshot.docs.length}');

      // طباعة بيانات كل مستخدم معلق للتشخيص
      for (var doc in pendingSnapshot.docs) {
        AppLogger.d(
          'مستخدم معلق: ${doc.data()['email']} - status: ${doc.data()['accountStatus']}',
        );
      }

      // جلب جميع المستخدمين
      final allSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      AppLogger.d('عدد جميع المستخدمين: ${allSnapshot.docs.length}');

      if (mounted) {
        setState(() {
          _pendingUsers = pendingSnapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();

          // ترتيب المستخدمين المعلقين حسب تاريخ الإنشاء
          _pendingUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _allUsers = allSnapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();

          _isLoading = false;
        });

        AppLogger.d('تم تحميل ${_pendingUsers.length} مستخدم معلق');
        AppLogger.d('تم تحميل ${_allUsers.length} مستخدم إجمالي');
      }
    } catch (e) {
      AppLogger.e('خطأ في تحميل المستخدمين', error: e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('هذه الصفحة للمدير فقط'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'في الانتظار',
                    style: TextStyle(color: AppTheme.textOnPrimary),
                  ),
                  if (_pendingUsers.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingUsers.length}',
                        style: const TextStyle(
                          color: AppTheme.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'جميع المستخدمين',
                    style: TextStyle(color: AppTheme.textOnPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_allUsers.length}',
                      style: const TextStyle(
                        color: AppTheme.textOnPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingList(), _buildAllUsersList()],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text('حدث خطأ: $_error'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات في الانتظار',
              style: TextStyle(color: AppTheme.grey600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الطلبات تمت معالجتها ✓',
              style: TextStyle(color: AppTheme.grey400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) => _PendingUserCard(
          user: _pendingUsers[index],
          onApprove: () => _approveUser(_pendingUsers[index]),
          onReject: () => _showRejectDialog(_pendingUsers[index]),
        ),
      ),
    );
  }

  Widget _buildAllUsersList() {
    if (_allUsers.isEmpty) {
      return const Center(child: Text('لا يوجد مستخدمين'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) => _UserCard(
          user: _allUsers[index],
          onTap: () => _showUserDetails(_allUsers[index]),
        ),
      ),
    );
  }

  Future<void> _approveUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppTheme.successColor, size: 48),
        title: const Text('تأكيد الموافقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد الموافقة على حساب "${user.name}"؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.email,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('موافقة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _authService.approveUser(user.id);

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('تمت الموافقة على ${user.name}'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'حدث خطأ'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showRejectDialog(UserModel user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.cancel, color: AppTheme.errorColor, size: 48),
        title: const Text('رفض الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم رفض حساب "${user.name}"'),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                hintText: 'اختياري - سيظهر للمستخدم',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // عرض مؤشر التحميل
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final result = await _authService.rejectUser(
                user.id,
                reasonController.text.trim().isEmpty
                    ? 'لم يتم تحديد السبب'
                    : reasonController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context); // إغلاق مؤشر التحميل

                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('تم رفض ${user.name}'),
                        ],
                      ),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  _loadUsers();
                }
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('رفض'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserDetailsSheet(user: user, onUpdate: _loadUsers),
    );
  }
}

/// بطاقة مستخدم في الانتظار
class _PendingUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingUserCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // صورة المستخدم
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // معلومات المستخدم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(color: AppTheme.grey600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // شارة طريقة التسجيل
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.authProvider == 'google'
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.authProvider == 'google'
                            ? Icons.g_mobiledata
                            : Icons.email_outlined,
                        size: 16,
                        color: user.authProvider == 'google'
                            ? Colors.red
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.authProvider == 'google' ? 'Google' : 'Email',
                        style: TextStyle(
                          color: user.authProvider == 'google'
                              ? Colors.red
                              : AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // تاريخ التسجيل
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.grey600),
                  const SizedBox(width: 4),
                  Text(
                    'التسجيل: ${dateFormatter.format(user.createdAt)}',
                    style: TextStyle(color: AppTheme.grey600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة مستخدم عادية
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left, color: AppTheme.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    if (user.isPending) {
      color = AppTheme.warningColor;
      text = 'معلق';
      icon = Icons.hourglass_empty;
    } else if (user.isRejected) {
      color = AppTheme.errorColor;
      text = 'مرفوض';
      icon = Icons.cancel;
    } else if (!user.isActive) {
      color = AppTheme.grey600;
      text = 'معطل';
      icon = Icons.block;
    } else if (user.isAdmin) {
      color = AppTheme.primaryColor;
      text = 'مدير';
      icon = Icons.admin_panel_settings;
    } else {
      color = AppTheme.successColor;
      text = 'نشط';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة تفاصيل المستخدم
class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUpdate;

  const _UserDetailsSheet({required this.user, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // صورة المستخدم
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // الاسم
          Text(
            user.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(user.email, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // المعلومات
          _buildInfoRow('الحالة', _getStatusText(), _getStatusColor()),
          _buildInfoRow('الدور', user.isAdmin ? 'مدير' : 'موظف', null),
          _buildInfoRow(
            'طريقة التسجيل',
            user.authProvider == 'google' ? 'Google' : 'البريد الإلكتروني',
            null,
          ),
          _buildInfoRow(
            'تاريخ التسجيل',
            dateFormatter.format(user.createdAt),
            null,
          ),
          if (user.lastLoginAt != null)
            _buildInfoRow(
              'آخر دخول',
              dateFormatter.format(user.lastLoginAt!),
              null,
            ),
          if (user.approvedAt != null)
            _buildInfoRow(
              'تاريخ الموافقة',
              dateFormatter.format(user.approvedAt!),
              null,
            ),
          if (user.rejectionReason != null)
            _buildInfoRow(
              'سبب الرفض',
              user.rejectionReason!,
              AppTheme.errorColor,
            ),

          const SizedBox(height: 24),

          // الأزرار
          if (!user.isAdmin) ...[
            Row(
              children: [
                // زر تعطيل/تفعيل
                if (user.isApproved && user.isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.deactivateUser(user.id);
                        onUpdate();
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('تعطيل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),

                if (!user.isActive && user.isApproved)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.activateUser(user.id);
                        onUpdate();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('تفعيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ),

                // أزرار للمستخدمين المعلقين
                if (user.isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.rejectUser(
                          user.id,
                          'تم الرفض من قبل المدير',
                        );
                        onUpdate();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.approveUser(user.id);
                        onUpdate();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (user.isPending) return 'في انتظار الموافقة';
    if (user.isRejected) return 'مرفوض';
    if (!user.isActive) return 'معطل';
    return 'نشط';
  }

  Color _getStatusColor() {
    if (user.isPending) return AppTheme.warningColor;
    if (user.isRejected) return AppTheme.errorColor;
    if (!user.isActive) return AppTheme.grey600;
    return AppTheme.successColor;
  }
}

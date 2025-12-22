// lib/features/auth/screens/user_management_screen.dart
// شاشة إدارة المستخدمين (للمدير فقط)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
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
    setState(() => _isLoading = true);

    final pendingResult = await _authService.getPendingUsers();
    final allResult = await _authService.getAllUsers();

    if (mounted) {
      setState(() {
        if (pendingResult.success) _pendingUsers = pendingResult.data!;
        if (allResult.success) _allUsers = allResult.data!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير مصرح')),
        body: const Center(child: Text('هذه الصفحة للمدير فقط')),
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
                  const Text('في الانتظار'),
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
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'جميع المستخدمين'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingList(), _buildAllUsersList()],
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات في الانتظار',
              style: TextStyle(color: Colors.grey[600]),
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
        title: const Text('تأكيد الموافقة'),
        content: Text('هل تريد الموافقة على حساب "${user.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _authService.approveUser(user.id);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت الموافقة على ${user.name}'),
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
        title: const Text('رفض الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم رفض حساب "${user.name}"'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                hintText: 'اختياري',
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _authService.rejectUser(
                user.id,
                reasonController.text.trim().isEmpty
                    ? 'لم يتم تحديد السبب'
                    : reasonController.text.trim(),
              );
              if (mounted) {
                if (result.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم رفض ${user.name}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  _loadUsers();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('رفض'),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
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
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.authProvider == 'google'
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.authProvider == 'google' ? 'Google' : 'Email',
                    style: TextStyle(
                      color: user.authProvider == 'google'
                          ? Colors.red
                          : AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'التسجيل: ${dateFormatter.format(user.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: AppTheme.errorColor),
                    label: const Text(
                      'رفض',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
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
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(user.name[0].toUpperCase())
              : null,
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    if (user.isPending) {
      color = AppTheme.warningColor;
      text = 'معلق';
    } else if (user.isRejected) {
      color = AppTheme.errorColor;
      text = 'مرفوض';
    } else if (!user.isActive) {
      color = Colors.grey;
      text = 'معطل';
    } else if (user.isAdmin) {
      color = AppTheme.primaryColor;
      text = 'مدير';
    } else {
      color = AppTheme.successColor;
      text = 'نشط';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(user.email, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          _buildInfoRow('الحالة', _getStatusText()),
          _buildInfoRow('الدور', user.isAdmin ? 'مدير' : 'موظف'),
          _buildInfoRow(
            'طريقة التسجيل',
            user.authProvider == 'google' ? 'Google' : 'البريد الإلكتروني',
          ),
          _buildInfoRow('تاريخ التسجيل', dateFormatter.format(user.createdAt)),
          if (user.approvedAt != null)
            _buildInfoRow(
              'تاريخ الموافقة',
              dateFormatter.format(user.approvedAt!),
            ),
          if (user.rejectionReason != null)
            _buildInfoRow('سبب الرفض', user.rejectionReason!),
          const SizedBox(height: 24),
          if (!user.isAdmin) ...[
            Row(
              children: [
                if (user.isApproved && user.isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authService.deactivateUser(user.id);
                        onUpdate();
                      },
                      icon: const Icon(Icons.block, color: AppTheme.errorColor),
                      label: const Text(
                        'تعطيل',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                if (!user.isActive && user.isApproved) ...[
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
                ],
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
                      icon: const Icon(Icons.close, color: AppTheme.errorColor),
                      label: const Text(
                        'رفض',
                        style: TextStyle(color: AppTheme.errorColor),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
}

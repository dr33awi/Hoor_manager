// lib/features/auth/screens/user_management_screen.dart
// شاشة إدارة المستخدمين

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    try {
      // تحميل المستخدمين المعلقين
      final pendingSnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'pending')
          .get();

      _pendingUsers = pendingSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      _pendingUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // تحميل جميع المستخدمين
      final allSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _allUsers = allSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المستخدمين: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'قيد الانتظار',
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
            const Tab(
              child: Text(
                'جميع المستخدمين',
                style: TextStyle(color: AppTheme.textOnPrimary),
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
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingUsersList(), _buildAllUsersList()],
            ),
    );
  }

  Widget _buildPendingUsersList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.successColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يوجد مستخدمين في الانتظار',
              style: TextStyle(fontSize: 18, color: AppTheme.grey600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        itemBuilder: (context, index) {
          final user = _pendingUsers[index];
          return _PendingUserCard(
            user: user,
            onApprove: () => _approveUser(user),
            onReject: () => _showRejectDialog(user),
            onTap: () => _showUserDetails(user),
          );
        },
      ),
    );
  }

  Widget _buildAllUsersList() {
    if (_allUsers.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد مستخدمين',
          style: TextStyle(fontSize: 18, color: AppTheme.grey600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return _UserCard(user: user, onTap: () => _showUserDetails(user));
        },
      ),
    );
  }

  Future<void> _approveUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الموافقة على المستخدم'),
        content: Text('هل تريد الموافقة على "${user.name}"؟'),
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
      try {
        final result = await _authService.approveUser(user.id);
        if (result.success) {
          await _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تمت الموافقة على "${user.name}"'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
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
        title: const Text('رفض المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد رفض "${user.name}"؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              try {
                final result = await _authService.rejectUser(
                  user.id,
                  reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                );
                if (result.success) {
                  await _loadUsers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم رفض "${user.name}"'),
                        backgroundColor: AppTheme.warningColor,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
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
      builder: (context) =>
          _UserDetailsSheet(user: user, onRefresh: _loadUsers),
    );
  }
}

// بطاقة المستخدم المعلق
class _PendingUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _PendingUserCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
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
                          style: const TextStyle(
                            color: AppTheme.grey600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'تاريخ التسجيل: ${DateFormat('dd/MM/yyyy - hh:mm a').format(user.createdAt)}',
                style: const TextStyle(color: AppTheme.grey600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
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
      ),
    );
  }
}

// بطاقة المستخدم العادية
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.1),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(child: Text(user.name)),
            _buildStatusBadge(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleBadge(),
                if (user.isGoogleUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.g_mobiledata, size: 14, color: Colors.red),
                        Text(
                          'Google',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color color;

    if (user.isPending) {
      text = 'معلق';
      color = AppTheme.warningColor;
    } else if (user.isRejected) {
      text = 'مرفوض';
      color = AppTheme.errorColor;
    } else if (!user.isActive) {
      text = 'معطل';
      color = AppTheme.grey600;
    } else {
      text = 'نشط';
      color = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: user.isAdmin
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        user.isAdmin ? 'مدير' : 'موظف',
        style: TextStyle(
          fontSize: 10,
          color: user.isAdmin ? AppTheme.primaryColor : AppTheme.grey600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (user.isPending) return AppTheme.warningColor;
    if (user.isRejected) return AppTheme.errorColor;
    if (!user.isActive) return AppTheme.grey600;
    return AppTheme.successColor;
  }
}

// صفحة تفاصيل المستخدم
class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onRefresh;

  const _UserDetailsSheet({required this.user, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // صورة المستخدم
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0] : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // الاسم
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppTheme.grey600),
                  ),
                  const SizedBox(height: 24),

                  // معلومات
                  _buildInfoRow('الحالة', _getStatusText()),
                  _buildInfoRow('الدور', user.isAdmin ? 'مدير' : 'موظف'),
                  _buildInfoRow(
                    'تاريخ التسجيل',
                    DateFormat('dd/MM/yyyy').format(user.createdAt),
                  ),
                  if (user.lastLoginAt != null)
                    _buildInfoRow(
                      'آخر دخول',
                      DateFormat(
                        'dd/MM/yyyy - hh:mm a',
                      ).format(user.lastLoginAt!),
                    ),
                  if (user.rejectionReason != null)
                    _buildInfoRow('سبب الرفض', user.rejectionReason!),

                  const SizedBox(height: 32),

                  // الإجراءات
                  _buildActions(context),
                ],
              ),
            ),
          ),
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
          Text(label, style: const TextStyle(color: AppTheme.grey600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (user.isPending) return 'قيد الانتظار';
    if (user.isRejected) return 'مرفوض';
    if (!user.isActive) return 'معطل';
    return 'نشط';
  }

  Widget _buildActions(BuildContext context) {
    final authService = AuthService();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (user.isActive && !user.isPending && !user.isRejected)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await authService.deactivateUser(user.id);
              onRefresh();
            },
            icon: const Icon(Icons.block),
            label: const Text('تعطيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        if (!user.isActive)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await authService.activateUser(user.id);
              onRefresh();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('تفعيل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
        if (user.isRejected)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await authService.approveUser(user.id);
              onRefresh();
            },
            icon: const Icon(Icons.check),
            label: const Text('موافقة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
          ),
      ],
    );
  }
}

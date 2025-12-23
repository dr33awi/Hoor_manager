// lib/features/auth/screens/user_management_screen.dart
// شاشة إدارة المستخدمين - محدثة للتوافق مع AuthService المحسن

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
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
        _showErrorSnackBar('خطأ في تحميل المستخدمين: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            _showSuccessSnackBar('تمت الموافقة على "${user.name}"');
          }
        } else {
          if (mounted) {
            _showErrorSnackBar(result.errorMessage ?? 'حدث خطأ');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('خطأ: $e');
        }
      }
    }
  }

  void _showRejectDialog(UserModel user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('رفض المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد رفض "${user.name}"؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    _showSuccessSnackBar('تم رفض "${user.name}"');
                  }
                } else {
                  if (mounted) {
                    _showErrorSnackBar(result.errorMessage ?? 'حدث خطأ');
                  }
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('خطأ: $e');
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
      builder: (context) => _UserDetailsSheet(
        user: user,
        authService: _authService,
        onRefresh: _loadUsers,
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                        const SizedBox(height: 2),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'جديد',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.grey200.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.grey600),
                    const SizedBox(width: 6),
                    Text(
                      'تاريخ التسجيل: ${DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(user.createdAt)}',
                      style: const TextStyle(
                        color: AppTheme.grey600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildRoleBadge(),
                if (user.isGoogleUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://www.google.com/favicon.ico',
                          height: 12,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata,
                            size: 12,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
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
        trailing: const Icon(Icons.chevron_left, color: AppTheme.grey400),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: user.isAdmin
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.grey200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        user.isAdmin ? 'مدير' : 'موظف',
        style: TextStyle(
          fontSize: 11,
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
  final AuthService authService;
  final VoidCallback onRefresh;

  const _UserDetailsSheet({
    required this.user,
    required this.authService,
    required this.onRefresh,
  });

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
                  _buildInfoCard(context),

                  const SizedBox(height: 24),

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

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grey200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow('الحالة', _getStatusText(), _getStatusColor()),
          const Divider(height: 24),
          _buildInfoRow('الدور', user.isAdmin ? 'مدير' : 'موظف', null),
          const Divider(height: 24),
          _buildInfoRow(
            'تاريخ التسجيل',
            DateFormat('dd/MM/yyyy').format(user.createdAt),
            null,
          ),
          if (user.lastLoginAt != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'آخر دخول',
              DateFormat('dd/MM/yyyy - hh:mm a').format(user.lastLoginAt!),
              null,
            ),
          ],
          if (user.rejectionReason != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'سبب الرفض',
              user.rejectionReason!,
              AppTheme.errorColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.grey600)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (user.isPending) return 'قيد الانتظار';
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

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // زر التعطيل (للمستخدمين النشطين)
        if (user.isActive && !user.isPending && !user.isRejected)
          _ActionButton(
            icon: Icons.block,
            label: 'تعطيل',
            color: AppTheme.errorColor,
            onPressed: () async {
              Navigator.pop(context);
              final result = await authService.deactivateUser(user.id);
              if (result.success) {
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تعطيل "${user.name}"'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                }
              }
            },
          ),

        // زر التفعيل (للمستخدمين المعطلين)
        if (!user.isActive)
          _ActionButton(
            icon: Icons.check_circle,
            label: 'تفعيل',
            color: AppTheme.successColor,
            onPressed: () async {
              Navigator.pop(context);
              final result = await authService.activateUser(user.id);
              if (result.success) {
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تفعيل "${user.name}"'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              }
            },
          ),

        // زر الموافقة (للمستخدمين المرفوضين)
        if (user.isRejected)
          _ActionButton(
            icon: Icons.check,
            label: 'موافقة',
            color: AppTheme.successColor,
            onPressed: () async {
              Navigator.pop(context);
              final result = await authService.approveUser(user.id);
              if (result.success) {
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت الموافقة على "${user.name}"'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

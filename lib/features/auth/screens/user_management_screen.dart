// lib/features/auth/screens/user_management_screen.dart
// شاشة إدارة المستخدمين - تصميم حديث

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
      final pendingSnapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'pending')
          .get();

      _pendingUsers = pendingSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      _pendingUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final allSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      _allUsers = allSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في التحميل', isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.grey.shade700,
            size: 20,
          ),
        ),
        title: const Text(
          'إدارة المستخدمين',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade600),
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('الانتظار'),
                      if (_pendingUsers.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_pendingUsers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'الكل'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingList(), _buildAllList()],
            ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingUsers.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        title: 'لا يوجد طلبات',
        subtitle: 'جميع الطلبات تمت معالجتها',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingUsers.length,
        itemBuilder: (_, i) => _PendingCard(
          user: _pendingUsers[i],
          onApprove: () => _approveUser(_pendingUsers[i]),
          onReject: () => _rejectUser(_pendingUsers[i]),
        ),
      ),
    );
  }

  Widget _buildAllList() {
    if (_allUsers.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline_rounded,
        color: Colors.grey.shade400,
        title: 'لا يوجد مستخدمين',
        subtitle: '',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allUsers.length,
        itemBuilder: (_, i) => _UserCard(
          user: _allUsers[i],
          onTap: () => _showUserSheet(_allUsers[i]),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approveUser(UserModel user) async {
    final confirm = await _showConfirmDialog(
      title: 'موافقة',
      message: 'الموافقة على "${user.name}"؟',
      confirmText: 'موافقة',
      confirmColor: const Color(0xFF10B981),
    );

    if (confirm == true) {
      final result = await _authService.approveUser(user.id);
      if (result.success) {
        await _loadUsers();
        if (mounted) _showSnackBar('تمت الموافقة');
      } else {
        if (mounted) _showSnackBar(result.errorMessage ?? 'خطأ', isError: true);
      }
    }
  }

  Future<void> _rejectUser(UserModel user) async {
    final confirm = await _showConfirmDialog(
      title: 'رفض',
      message: 'رفض "${user.name}"؟',
      confirmText: 'رفض',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirm == true) {
      final result = await _authService.rejectUser(user.id);
      if (result.success) {
        await _loadUsers();
        if (mounted) _showSnackBar('تم الرفض');
      } else {
        if (mounted) _showSnackBar(result.errorMessage ?? 'خطأ', isError: true);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(message, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(confirmText),
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

  void _showUserSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserSheet(
        user: user,
        authService: _authService,
        onRefresh: _loadUsers,
      ),
    );
  }
}

// ==================== Pending Card ====================
class _PendingCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFFD97706),
                    ),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'جديد',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd/MM/yyyy', 'ar').format(user.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'موافقة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== User Card ====================
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: user.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _statusColor(),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _statusBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    String text;
    Color color;

    if (user.isPending) {
      text = 'معلق';
      color = const Color(0xFFD97706);
    } else if (user.isRejected) {
      text = 'مرفوض';
      color = const Color(0xFFEF4444);
    } else if (!user.isActive) {
      text = 'معطل';
      color = Colors.grey.shade500;
    } else {
      text = 'نشط';
      color = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor() {
    if (user.isPending) return const Color(0xFFD97706);
    if (user.isRejected) return const Color(0xFFEF4444);
    if (!user.isActive) return Colors.grey.shade500;
    return const Color(0xFF10B981);
  }
}

// ==================== User Sheet ====================
class _UserSheet extends StatelessWidget {
  final UserModel user;
  final AuthService authService;
  final VoidCallback onRefresh;

  const _UserSheet({
    required this.user,
    required this.authService,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: user.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow('الحالة', _statusText(), _statusColor()),
                Divider(height: 20, color: Colors.grey.shade200),
                _infoRow('الدور', user.isAdmin ? 'مدير' : 'موظف', null),
                Divider(height: 20, color: Colors.grey.shade200),
                _infoRow(
                  'التسجيل',
                  DateFormat('dd/MM/yyyy').format(user.createdAt),
                  null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  String _statusText() {
    if (user.isPending) return 'معلق';
    if (user.isRejected) return 'مرفوض';
    if (!user.isActive) return 'معطل';
    return 'نشط';
  }

  Color _statusColor() {
    if (user.isPending) return const Color(0xFFD97706);
    if (user.isRejected) return const Color(0xFFEF4444);
    if (!user.isActive) return Colors.grey.shade500;
    return const Color(0xFF10B981);
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (user.isActive && !user.isPending && !user.isRejected)
          _actionBtn(
            context,
            'تعطيل',
            Icons.block,
            const Color(0xFFEF4444),
            () async {
              Navigator.pop(context);
              await authService.deactivateUser(user.id);
              onRefresh();
            },
          ),
        if (!user.isActive)
          _actionBtn(
            context,
            'تفعيل',
            Icons.check_circle,
            const Color(0xFF10B981),
            () async {
              Navigator.pop(context);
              await authService.activateUser(user.id);
              onRefresh();
            },
          ),
        if (user.isRejected)
          _actionBtn(
            context,
            'موافقة',
            Icons.check,
            const Color(0xFF10B981),
            () async {
              Navigator.pop(context);
              await authService.approveUser(user.id);
              onRefresh();
            },
          ),
      ],
    );
  }

  Widget _actionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

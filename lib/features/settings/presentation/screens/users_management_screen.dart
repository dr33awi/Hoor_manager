import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../auth/domain/entities/entities.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// شاشة إدارة المستخدمين
class UsersManagementScreen extends ConsumerWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'بانتظار الموافقة'),
              Tab(text: 'النشطون'),
              Tab(text: 'المعطلون'),
            ],
          ),
        ),
        body: usersAsync.when(
          data: (users) {
            final pending = users.where((u) => u.isPending).toList();
            final active = users.where((u) => u.isActive).toList();
            final inactive = users.where((u) => !u.isActive && !u.isPending).toList();

            return TabBarView(
              children: [
                // بانتظار الموافقة
                _UsersList(
                  users: pending,
                  emptyMessage: 'لا يوجد مستخدمون بانتظار الموافقة',
                  emptyIcon: Icons.hourglass_empty,
                  currentUser: currentUser,
                  showApproveButton: true,
                ),
                // النشطون
                _UsersList(
                  users: active,
                  emptyMessage: 'لا يوجد مستخدمون نشطون',
                  emptyIcon: Icons.people_outline,
                  currentUser: currentUser,
                ),
                // المعطلون
                _UsersList(
                  users: inactive,
                  emptyMessage: 'لا يوجد مستخدمون معطلون',
                  emptyIcon: Icons.person_off_outlined,
                  currentUser: currentUser,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }
}

/// قائمة المستخدمين
class _UsersList extends ConsumerWidget {
  final List<UserEntity> users;
  final String emptyMessage;
  final IconData emptyIcon;
  final UserEntity? currentUser;
  final bool showApproveButton;

  const _UsersList({
    required this.users,
    required this.emptyMessage,
    required this.emptyIcon,
    this.currentUser,
    this.showApproveButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSizes.md),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUsersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(
            user: user,
            currentUser: currentUser,
            showApproveButton: showApproveButton,
          );
        },
      ),
    );
  }
}

/// بطاقة المستخدم
class _UserCard extends ConsumerWidget {
  final UserEntity user;
  final UserEntity? currentUser;
  final bool showApproveButton;

  const _UserCard({
    required this.user,
    this.currentUser,
    this.showApproveButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = currentUser?.id == user.id;
    final canManage = currentUser?.canManageUsers == true && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Row(
              children: [
                // صورة المستخدم
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '؟',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),

                // معلومات المستخدم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: const Text(
                                'أنت',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          // الدور
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              user.role.arabicName,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          // الحالة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(user).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              _getStatusText(user),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(user),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // المزيد
                if (canManage)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(context, ref, value),
                    itemBuilder: (context) => [
                      if (user.isPending) ...[
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success),
                              SizedBox(width: AppSizes.sm),
                              Text('الموافقة'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: AppColors.error),
                              SizedBox(width: AppSizes.sm),
                              Text('رفض'),
                            ],
                          ),
                        ),
                      ],
                      if (!user.isPending) ...[
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                user.isActive ? Icons.block : Icons.check_circle,
                                color: user.isActive ? AppColors.error : AppColors.success,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(user.isActive ? 'تعطيل' : 'تفعيل'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'change_role',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings),
                              SizedBox(width: AppSizes.sm),
                              Text('تغيير الدور'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: AppSizes.sm),
                            Text('حذف', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // أزرار الموافقة السريعة
            if (showApproveButton && user.isPending && canManage) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectUser(context, ref),
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text('رفض', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveUser(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                    ),
                  ),
                ],
              ),
            ],

            // تاريخ التسجيل
            if (user.createdAt != null) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    'انضم ${user.createdAt!.toRelativeDate()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.founder:
        return const Color(0xFFFFD700);
      case UserRole.manager:
        return AppColors.primary;
      case UserRole.employee:
        return AppColors.info;
    }
  }

  Color _getStatusColor(UserEntity user) {
    if (user.isPending) return AppColors.warning;
    if (user.isActive) return AppColors.success;
    return AppColors.error;
  }

  String _getStatusText(UserEntity user) {
    if (user.isPending) return 'بانتظار الموافقة';
    if (user.isActive) return 'نشط';
    return 'معطل';
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'approve':
        _approveUser(context, ref);
        break;
      case 'reject':
        _rejectUser(context, ref);
        break;
      case 'toggle_status':
        _toggleUserStatus(context, ref);
        break;
      case 'change_role':
        _showChangeRoleDialog(context, ref);
        break;
      case 'delete':
        _confirmDeleteUser(context, ref);
        break;
    }
  }

  Future<void> _approveUser(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(userManagementProvider.notifier).approveUser(user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تمت الموافقة على المستخدم' : 'فشل في الموافقة'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectUser(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض المستخدم'),
        content: Text('هل أنت متأكد من رفض ${user.fullName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(userManagementProvider.notifier).rejectUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم رفض المستخدم' : 'فشل في الرفض'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(userManagementProvider.notifier).toggleUserStatus(user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم تحديث حالة المستخدم' : 'فشل في التحديث'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref) {
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تغيير الدور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                title: Text(role.arabicName),
                subtitle: Text(role.arabicDescription),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() => selectedRole = value!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(userManagementProvider.notifier)
                    .updateUserRole(user.id, selectedRole);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'تم تغيير الدور' : 'فشل في التغيير'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: AppColors.error, size: 48),
            const SizedBox(height: AppSizes.md),
            Text('هل أنت متأكد من حذف ${user.fullName}؟'),
            const Text(
              'لا يمكن التراجع عن هذا الإجراء',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(userManagementProvider.notifier).deleteUser(user.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف المستخدم' : 'فشل في الحذف'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}

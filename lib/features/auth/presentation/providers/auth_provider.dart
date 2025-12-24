import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// مزود مستودع المصادقة
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// مزود مستودع إدارة المستخدمين
final userManagementRepositoryProvider = Provider((ref) {
  return UserManagementRepositoryImpl();
});

/// مزود حالة المصادقة
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Alias للتوافق
final authNotifierProvider = authStateProvider;

/// مزود المستخدم الحالي
final currentUserProvider = Provider<UserEntity?>((ref) {
  final state = ref.watch(authStateProvider);
  return switch (state) {
    AuthAuthenticated(:final user) => user,
    AuthPendingApproval(:final user) => user,
    _ => null,
  };
});

/// مزود هل المستخدم مسجل دخوله
final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authStateProvider);
  return state is AuthAuthenticated;
});

/// مزود جميع المستخدمين
final allUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  final result = await repository.getAllUsers();
  return result.valueOrNull ?? [];
});

/// مزود المستخدمين بانتظار الموافقة
final pendingUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  final result = await repository.getPendingUsers();
  return result.valueOrNull ?? [];
});

/// Notifier لإدارة حالة المصادقة
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  StreamSubscription? _authSubscription;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _init();
    return const AuthInitial();
  }

  /// تهيئة الاستماع لتغييرات المصادقة
  void _init() {
    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges.listen(
      (user) {
        if (user == null) {
          state = const AuthUnauthenticated();
        } else if (user.isPendingApproval) {
          state = AuthPendingApproval(user);
        } else if (user.canAccessApp) {
          state = AuthAuthenticated(user);
        } else {
          state = const AuthUnauthenticated();
        }
      },
      onError: (error) {
        state = AuthError(error.toString());
      },
    );
  }

  /// تسجيل الدخول بالبريد الإلكتروني
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (user) {
        if (user.isPendingApproval) {
          state = AuthPendingApproval(user);
        } else {
          state = AuthAuthenticated(user);
        }
      },
      failure: (message) {
        state = AuthError(message);
      },
    );
  }

  /// تسجيل الدخول بـ Google
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();

    final result = await _repository.signInWithGoogle();

    result.when(
      success: (user) {
        if (user.isPendingApproval) {
          state = AuthPendingApproval(user);
        } else {
          state = AuthAuthenticated(user);
        }
      },
      failure: (message) {
        state = AuthError(message);
      },
    );
  }

  /// إنشاء حساب جديد
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AuthLoading();

    final result = await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    result.when(
      success: (user) {
        state = AuthPendingApproval(user);
      },
      failure: (message) {
        state = AuthError(message);
      },
    );
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    final result = await _repository.resetPassword(email);
    return result.isSuccess;
  }

  /// مسح حالة الخطأ
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

/// مزود عملية تسجيل الدخول
final signInProvider = FutureProvider.family<void, ({String email, String password})>((ref, params) async {
  final notifier = ref.read(authStateProvider.notifier);
  await notifier.signInWithEmail(email: params.email, password: params.password);
});

/// مزود عملية إنشاء الحساب
final signUpProvider = FutureProvider.family<void, ({String email, String password, String fullName, String? phone})>((ref, params) async {
  final notifier = ref.read(authStateProvider.notifier);
  await notifier.signUp(
    email: params.email,
    password: params.password,
    fullName: params.fullName,
    phone: params.phone,
  );
});

/// Notifier لإدارة المستخدمين
class UserManagementNotifier extends Notifier<AsyncValue<void>> {
  late UserManagementRepositoryImpl _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(userManagementRepositoryProvider);
    return const AsyncValue.data(null);
  }

  /// الموافقة على مستخدم
  Future<bool> approveUser(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.approveUser(userId);
    state = const AsyncValue.data(null);
    if (result.isSuccess) {
      ref.invalidate(allUsersProvider);
      ref.invalidate(pendingUsersProvider);
    }
    return result.isSuccess;
  }

  /// رفض مستخدم
  Future<bool> rejectUser(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.rejectUser(userId);
    state = const AsyncValue.data(null);
    if (result.isSuccess) {
      ref.invalidate(allUsersProvider);
      ref.invalidate(pendingUsersProvider);
    }
    return result.isSuccess;
  }

  /// تغيير حالة المستخدم
  Future<bool> toggleUserStatus(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.toggleUserStatus(userId);
    state = const AsyncValue.data(null);
    if (result.isSuccess) {
      ref.invalidate(allUsersProvider);
    }
    return result.isSuccess;
  }

  /// تحديث دور المستخدم
  Future<bool> updateUserRole(String userId, UserRole role) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateUserRole(userId, role);
    state = const AsyncValue.data(null);
    if (result.isSuccess) {
      ref.invalidate(allUsersProvider);
    }
    return result.isSuccess;
  }

  /// حذف مستخدم
  Future<bool> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteUser(userId);
    state = const AsyncValue.data(null);
    if (result.isSuccess) {
      ref.invalidate(allUsersProvider);
    }
    return result.isSuccess;
  }
}

/// مزود إدارة المستخدمين
final userManagementProvider =
    NotifierProvider<UserManagementNotifier, AsyncValue<void>>(() {
  return UserManagementNotifier();
});

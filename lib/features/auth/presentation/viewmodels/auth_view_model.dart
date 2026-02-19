import 'package:daylog/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_view_model.g.dart';

@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  @override
  Stream<UserModel?> build() {
    return ref.watch(authRepositoryProvider).authStateChanges;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithEmail(
            email: email,
            password: password,
          );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            name: name,
            nickname: nickname,
          );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      // State is updated via stream, but we can set data if stream is slow?
      // Better to rely on stream.
      // But if user cancels, we stay in previous state?
      // signInWithGoogle returns UserModel? or null.
      if (user == null) {
        // Canceled
        // We might want to refresh state to current stream value
        ref.invalidateSelf();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithKakao() async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithKakao();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return ref.read(authRepositoryProvider).updatePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }

  Future<void> completeProfileSetup({
    required String nickname,
    String? profileImagePath,
  }) {
    return ref.read(authRepositoryProvider).completeProfileSetup(
          nickname: nickname,
          profileImagePath: profileImagePath,
        );
  }
}

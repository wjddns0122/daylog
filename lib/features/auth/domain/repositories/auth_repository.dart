import 'package:daylog/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  });
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
  });
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithKakao();
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> completeProfileSetup({
    required String nickname,
    required String bio,
    String? profileImagePath,
  });
  Future<void> signOut();
  Future<void> deleteAccount();
}

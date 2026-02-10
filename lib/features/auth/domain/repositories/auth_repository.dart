import 'package:daylog/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithKakao();
  Future<void> signOut();
}

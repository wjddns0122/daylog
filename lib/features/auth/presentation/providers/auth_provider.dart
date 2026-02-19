import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Removed unused

// State Class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthRepository());
});

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final firebaseUser = _repository.currentUser;
    if (firebaseUser != null) {
      // Ideally fetch full profile from Firestore here
      state = state.copyWith(user: UserModel.fromFirebaseUser(firebaseUser));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        nickname: nickname,
      );
      // Don't log in immediately if verification is required
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> googleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signInWithGoogle();
      // Repository should return user, but for now we rely on auth state stream or check current user
      // Ideally update repository to return User and update state here.
      final updatedUser = _repository.currentUser;
      if (updatedUser != null) {
        state = state.copyWith(
          isLoading: false,
          user: UserModel.fromFirebaseUser(updatedUser),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithKakao() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithKakao();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

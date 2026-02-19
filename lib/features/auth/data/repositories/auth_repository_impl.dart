import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daylog/features/auth/domain/models/user_model.dart';
import 'package:daylog/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email'],
            );

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        // Auto-patch missing search fields for legacy user docs
        if (data != null && !data.containsKey('nicknameLower')) {
          try {
            final nickname = data['nickname'] as String? ??
                data['displayName'] as String? ??
                '';
            final displayName = data['displayName'] as String? ?? '';
            await _firestore.collection('users').doc(user.uid).update({
              'nicknameLower': nickname.toLowerCase(),
              'displayNameLower': displayName.toLowerCase(),
            });
          } catch (_) {
            // Non-critical: search might not work for this user yet
          }
        }
        return UserModel.fromDocument(doc);
      }

      // Auto-create user doc if missing (emulator or legacy accounts)
      final fallbackName =
          user.displayName ?? user.email?.split('@').first ?? '';
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: fallbackName,
        photoUrl: user.photoURL,
        nickname: fallbackName,
        isVerified: user.emailVerified,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore.collection('users').doc(user.uid).set({
          ...newUser.toJson(),
          'nicknameLower': (newUser.nickname ?? '').toLowerCase(),
          'displayNameLower': newUser.displayName.toLowerCase(),
          'loginMethod': 'unknown',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // If Firestore write fails (e.g. rules), still return the model
      }

      return newUser;
    });
  }

  @override
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return null;

      // Fetch user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }

      // Auto-create user doc if missing (emulator or legacy accounts)
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? email.split('@').first,
        nickname: user.displayName ?? email.split('@').first,
        photoUrl: user.photoURL,
        isVerified: user.emailVerified,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...newUser.toJson(),
        'nicknameLower': (newUser.nickname ?? '').toLowerCase(),
        'displayNameLower': newUser.displayName.toLowerCase(),
        'loginMethod': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return null;

      // Create new user in Firestore
      final newUser = UserModel(
        uid: user.uid,
        email: email,
        displayName: name,
        nickname: nickname,
        photoUrl: null,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...newUser.toJson(),
        'nicknameLower': nickname.toLowerCase(),
        'displayNameLower': name.toLowerCase(),
        'name':
            name, // Store real name explicitly if needed, or rely on internal logic
        'loginMethod': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        return await _syncUserToFirestore(
          uid: user.uid,
          email: user.email ?? '',
          nickname: user.displayName,
          photoUrl: user.photoURL,
          loginMethod: 'google',
        );
      }
    } catch (e) {
      // Handle error (log it)
      rethrow;
    }
    return null;
  }

  @override
  Future<UserModel?> signInWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          // If canceled or failed, try account login
          if (error is PlatformException && error.code == 'CANCELED') {
            return null;
          }
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final kakaoUser = await kakao.UserApi.instance.me();

      final firebaseUser = _firebaseAuth.currentUser ??
          (await _firebaseAuth.signInAnonymously()).user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'Could not establish Firebase session for Kakao login.',
        );
      }

      final uid = firebaseUser.uid;
      final email = kakaoUser.kakaoAccount?.email ?? '';
      final nickname = kakaoUser.kakaoAccount?.profile?.nickname;
      final photoUrl = kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl;

      return await _syncUserToFirestore(
        uid: uid,
        email: email,
        nickname: nickname,
        photoUrl: photoUrl,
        loginMethod: 'kakao',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> _syncUserToFirestore({
    required String uid,
    required String email,
    String? nickname,
    String? photoUrl,
    required String loginMethod,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: uid,
        email: email,
        displayName: nickname ?? 'User',
        nickname: nickname,
        photoUrl: photoUrl,
        isVerified: true,
        createdAt: DateTime.now(),
      );
      await userRef.set({
        ...newUser.toJson(),
        'nicknameLower': (newUser.nickname ?? '').toLowerCase(),
        'displayNameLower': newUser.displayName.toLowerCase(),
        'loginMethod': loginMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return newUser;
    } else {
      // Update fields if changed?
      // For now, just return existing
      return UserModel.fromDocument(doc);
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found.',
      );
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Password change is only available for email accounts.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      // Kakao logout if needed
      // kakao.UserApi.instance.logout(),
    ]);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl();
}

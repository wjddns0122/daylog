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
      // Fetch details from Firestore to get nickname/etc if needed,
      // or just return basic info. For now, returning User from Firestore preferred.
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        photoUrl: user.photoURL,
        nickname: user.displayName,
      );
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
      // Fallback if user exists in Auth but not Firestore (edge case)
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        nickname: user.displayName,
        photoUrl: user.photoURL,
      );
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
        nickname: nickname,
        photoUrl: null, // Default null for email signup
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...newUser.toJson(),
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

      // NOTE: strict Firebase integration requires Custom Token here.
      // For now, we will just sync to Firestore and return a defined User
      // CAUTION: FirebaseAuth will NOT be signed in for Kakao without Custom Token.
      // This might limit functionality if rules require request.auth.

      final uid = 'kakao:${kakaoUser.id}';
      final email = kakaoUser.kakaoAccount?.email ?? '';
      final nickname = kakaoUser.kakaoAccount?.profile?.nickname;
      final photoUrl = kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl;

      // We might want to create an anonymous firebase user and link?
      // Or just proceed. For strict adherence to "Hybrid Social",
      // we assume a solution exists or will be added.
      // Current path: Sync to Firestore directly.

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
        nickname: nickname,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
      await userRef.set({
        ...newUser.toJson(),
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

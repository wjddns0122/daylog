import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import '../../domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Stream of Auth Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    try {
      // 1. Create User in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;

      // 2. Send Verification Email
      await user.sendEmailVerification();

      // 3. Update Display Name
      await user.updateDisplayName(name);

      // 4. Create User Model
      final newUser = UserModel(
        uid: user.uid,
        email: email,
        displayName: name,
        isVerified: false,
        nickname: nickname,
      );

      // 5. Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toJson());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign In with Email & Password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign In
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;

      // 2. Check Verification
      if (!user.emailVerified) {
        // throw Exception('Email not verified. Please check your inbox.');
        // For development/demo, we might want to allow login without verification or
        // strictly enforce it. Use strict enforcement for now.
        throw Exception('이메일 인증이 필요합니다. 메일함을 확인해주세요.');
      }

      // 3. Fetch User Data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserModel.fromDocument(doc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign In with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign In aborted');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return _signInWithCredential(credential, 'google');
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Sign In with Kakao
  Future<UserModel> signInWithKakao() async {
    try {
      // 1. Check if KakaoTalk is installed
      bool isInstalled = await kakao.isKakaoTalkInstalled();

      // 2. Login with Kakao
      isInstalled
          ? await kakao.UserApi.instance.loginWithKakaoTalk()
          : await kakao.UserApi.instance.loginWithKakaoAccount();

      // 3. Get Kakao User Info
      final kakaoUser = await kakao.UserApi.instance.me();

      // 4. Sign in to Firebase Auth anonymously to get a valid auth token
      //    This is needed for Cloud Functions calls (createPostIntent, etc.)
      UserCredential firebaseCredential;
      if (_auth.currentUser != null) {
        // Already signed in to Firebase Auth, reuse existing session
        firebaseCredential = await _auth.signInAnonymously();
      } else {
        firebaseCredential = await _auth.signInAnonymously();
      }
      final firebaseUser = firebaseCredential.user!;
      final String uid = firebaseUser.uid;

      // 5. Store Kakao profile info in Firestore under Firebase Auth UID
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final newUser = UserModel(
          uid: uid,
          email: kakaoUser.kakaoAccount?.email ?? '',
          displayName:
              kakaoUser.kakaoAccount?.profile?.nickname ?? 'Kakao User',
          photoUrl: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
          isVerified: true,
          nickname: kakaoUser.kakaoAccount?.profile?.nickname,
        );
        await docRef.set(newUser.toJson());
        return newUser;
      } else {
        return UserModel.fromDocument(doc);
      }
    } catch (e) {
      throw Exception('Kakao Sign In failed: $e');
    }
  }

  // Naver Login Removed

  // Internal: Handle Credential Sign In & Firestore Sync
  Future<UserModel> _signInWithCredential(
    AuthCredential credential,
    String provider,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Check if user exists in Firestore
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new user if not exists
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        isVerified: true, // Social logins are verified
        nickname: user.displayName, // Default nickname
      );
      await docRef.set(newUser.toJson());
      return newUser;
    } else {
      return UserModel.fromDocument(doc);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    // await FlutterNaverLogin.logOut();
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 존재하는 이메일입니다.';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      default:
        return '로그인 실패. 다시 시도해주세요.';
    }
  }
}

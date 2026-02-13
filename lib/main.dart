import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:daylog/app/router.dart';
import 'package:daylog/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if we should use Firebase Emulators
  // Only use emulators if explicitly enabled in .env
  final useEmulators = dotenv.env['USE_FIREBASE_EMULATOR'] == 'true';

  if (kDebugMode && useEmulators) {
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('DEBUG: Connected to Firebase Emulators on $host');
    } catch (e) {
      debugPrint('DEBUG: Failed to connect to Firebase Emulators: $e');
    }
  }

  // Initialize Kakao SDK
  final kakaoNativeKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (kakaoNativeKey.isEmpty) {
    debugPrint('WARNING: KAKAO_NATIVE_APP_KEY is missing in .env');
  }

  KakaoSdk.init(nativeAppKey: kakaoNativeKey);

  runApp(const ProviderScope(child: DaylogApp()));
}

class DaylogApp extends ConsumerWidget {
  const DaylogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Daylog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
      ),
      routerConfig: router,
    );
  }
}

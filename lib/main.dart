import 'package:daylog/app/router.dart';
import 'package:daylog/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malay/data/tts_helper.dart';
import 'package:malay/views/pages/home_page.dart';
import 'package:malay/views/pages/login/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:malay/data/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedTheme();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await TtsHelper().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MalayLearningApp(),
    ),
  );
}

class MalayLearningApp extends StatelessWidget {
  const MalayLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malay Learner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        fontFamily: 'San Francisco',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 监听 Firebase 的身份变化流
      // 只要用户登录、注销、或者 App 重启（自动读取缓存），这里都会触发
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 如果正在检查状态（比如刚启动 App 的几毫秒），显示加载圈
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. 如果 snapshot 有数据，说明用户已经登录过了
        if (snapshot.hasData) {
          // 直接进入主页
          return const HomePage();
        }

        // 3. 否则，说明没登录，显示登录页
        return const LoginPage();
      },
    );
  }
}

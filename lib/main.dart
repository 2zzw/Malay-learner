import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malay/data/tts_helper.dart';
import 'package:malay/views/pages/home_page.dart';
import 'package:malay/views/pages/login/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'firebase_options.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:malay/data/podcast_provider.dart'; // 记得加上这行

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedTheme();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await TtsHelper().init();
  print(await getDatabasesPath());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // 主题 Provider
        ChangeNotifierProvider(create: (_) => themeProvider),

        // 播客 Provider
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
      ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

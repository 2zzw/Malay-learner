import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// AUTH SERVICE (Backend Logic)
// =============================================================================

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 模拟模式：如果你还没有配置 firebase_options.dart，设为 true 以测试 UI
  static const bool _mockMode = true; 

  // Stream 用于监听用户登录状态变化
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 邮箱登录
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (_mockMode) {
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
      return null; // 模拟成功，实际返回 null 因为没有真实 User
    }
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // 注册
  Future<UserCredential?> signUp(String email, String password) async {
    if (_mockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return null;
    }
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // 退出登录
  Future<void> signOut() async {
    if (_mockMode) return;
    await _auth.signOut();
  }
}
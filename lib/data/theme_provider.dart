import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. 定义背景图片的模型
class BackgroundOption {
  final String id;
  final String imageUrl;
  final bool isVip;

  BackgroundOption({
    required this.id,
    required this.imageUrl,
    this.isVip = false,
  });
}

// 2. 状态管理器
class ThemeProvider extends ChangeNotifier {
  // 模拟当前用户是否是 VIP (演示用，你可以连接你的 User 数据)
  bool isUserVip = false;

  // 默认背景 (第一张)
  String _currentBackgroundUrl =
      "https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop";

  String get currentBackgroundUrl => _currentBackgroundUrl;

  // 背景库数据
  final List<BackgroundOption> backgrounds = [
    // --- 免费区 ---
    BackgroundOption(
      id: '1',
      imageUrl:
          "https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop",
      isVip: false,
    ),
    BackgroundOption(
      id: '2',
      imageUrl:
          "https://images.unsplash.com/photo-1494438639946-1ebd1d20bf85?q=80&w=1000&auto=format&fit=crop",
      isVip: false,
    ),
    BackgroundOption(
      id: '3',
      imageUrl:
          "https://images.pexels.com/photos/16508831/pexels-photo-16508831.jpeg",
      isVip: false,
    ),

    // --- VIP 区 ---
    BackgroundOption(
      id: '4',
      imageUrl:
          "https://images.unsplash.com/photo-1555680202-c86f0e12f086?q=80&w=1000&auto=format&fit=crop",
      isVip: true,
    ),
    BackgroundOption(
      id: '5',
      imageUrl:
          "https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?q=80&w=1000&auto=format&fit=crop",
      isVip: true,
    ),
    BackgroundOption(
      id: '6',
      imageUrl:
          "https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=1000&auto=format&fit=crop",
      isVip: true,
    ),
  ];

  // 初始化：加载上次保存的选择
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('selected_bg');
    if (savedUrl != null) {
      _currentBackgroundUrl = savedUrl;
      notifyListeners();
    }
  }

  // 切换背景的方法
  Future<void> changeBackground(BackgroundOption option) async {
    // 检查权限
    if (option.isVip && !isUserVip) {
      throw "需要 VIP 才能解锁此背景";
    }

    _currentBackgroundUrl = option.imageUrl;

    // 保存到本地
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_bg', option.imageUrl);

    // 通知所有页面刷新
    notifyListeners();
  }

  // 切换 VIP 状态 (仅用于测试)
  void toggleVipStatus() {
    isUserVip = !isUserVip;
    notifyListeners();
  }
}

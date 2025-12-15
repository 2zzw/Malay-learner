import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义你的 BackgroundOption 类 (如上所示)
class BackgroundOption {
  final String id;
  final String imageUrl;
  final bool isVip;
  final bool isLocal;

  const BackgroundOption({
    required this.id,
    required this.imageUrl,
    this.isVip = false,
    this.isLocal = false,
  });
}

class ThemeProvider extends ChangeNotifier {
  // 1. 预设的背景列表 (网络图片)
  final List<BackgroundOption> _presetBackgrounds = [
    const BackgroundOption(
      id: '1',
      imageUrl:
          "https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop",
      isVip: false,
    ),
    const BackgroundOption(
      id: '2',
      imageUrl: 'https://picsum.photos/id/1015/600/800',
      isVip: false,
    ),
    const BackgroundOption(
      id: '3',
      imageUrl:
          "https://images.pexels.com/photos/16508831/pexels-photo-16508831.jpeg",
      isVip: true,
    ),
    const BackgroundOption(
      id: '4',
      imageUrl: 'https://picsum.photos/id/1016/600/800',
      isVip: true,
    ),
    const BackgroundOption(
      id: '5',
      imageUrl: 'https://picsum.photos/id/1018/600/800',
      isVip: true,
    ),
    // ... 更多预设
  ];

  // 2. 自定义的背景列表 (本地路径)
  List<BackgroundOption> _customBackgrounds = [];

  String _currentBackgroundUrl =
      "https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop";
  bool _isUserVip = false; // 模拟 VIP 状态

  // Getters
  String get currentBackgroundUrl => _currentBackgroundUrl;
  bool get isUserVip => _isUserVip;

  // [关键] 合并列表：UI 将显示这个列表
  // 顺序：自定义的排前面，预设的排后面
  List<BackgroundOption> get backgrounds => [
    ..._customBackgrounds,
    ..._presetBackgrounds,
  ];

  // 初始化
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载当前选中的背景
    _currentBackgroundUrl =
        prefs.getString('current_bg') ?? _presetBackgrounds.first.imageUrl;

    // [新增] 加载自定义背景列表
    List<String>? savedPaths = prefs.getStringList('custom_bg_paths');
    if (savedPaths != null) {
      _customBackgrounds = savedPaths
          .map(
            (path) => BackgroundOption(
              id: path, // 用路径当 ID
              imageUrl: path,
              isVip: true, // 自定义背景通常视为 VIP 功能
              isLocal: true, // 标记为本地
            ),
          )
          .toList();
    }

    // 模拟检查 VIP
    _isUserVip = true; // 测试时设为 true
    notifyListeners();
  }

  // 切换背景
  Future<void> changeBackground(BackgroundOption option) async {
    if (option.isVip && !_isUserVip) {
      throw Exception("VIP required");
    }

    _currentBackgroundUrl = option.imageUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_bg', _currentBackgroundUrl);
    notifyListeners();
  }

  // [新增] 添加自定义背景
  Future<void> addCustomBackground(String path) async {
    // 1. 创建对象
    final newOption = BackgroundOption(
      id: path,
      imageUrl: path,
      isVip: true,
      isLocal: true,
    );

    // 2. 加到列表最前面
    _customBackgrounds.insert(0, newOption);

    // 3. 自动选中新上传的
    _currentBackgroundUrl = path;

    // 4. 持久化保存
    await _saveCustomPaths();

    // 5. 保存当前选中状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_bg', path);

    notifyListeners();
  }

  // [新增] 删除自定义背景
  Future<void> removeCustomBackground(BackgroundOption option) async {
    // 1. 从列表中移除
    _customBackgrounds.removeWhere((element) => element.id == option.id);

    // 2. 如果删除的是当前正在用的，重置为默认背景
    if (_currentBackgroundUrl == option.imageUrl) {
      _currentBackgroundUrl = _presetBackgrounds.first.imageUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_bg', _currentBackgroundUrl);
    }

    // 3. 更新本地存储的列表
    await _saveCustomPaths();

    // 4. (可选) 删除手机存储里的物理文件以节省空间
    try {
      final file = File(option.imageUrl);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("删除文件失败: $e");
    }

    notifyListeners();
  }

  // 辅助方法：保存路径列表到 SharedPreferences
  Future<void> _saveCustomPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> paths = _customBackgrounds
        .map((e) => e.imageUrl)
        .toList();
    await prefs.setStringList('custom_bg_paths', paths);
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // 预设的背景列表
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
  ];

  // 自定义的背景列表 (本地路径)
  List<BackgroundOption> _customBackgrounds = [];

  String _currentBackgroundUrl =
      "https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop";
  bool _isUserVip = false; // 模拟 VIP 状态

  // Getters
  String get currentBackgroundUrl => _currentBackgroundUrl;
  bool get isUserVip => _isUserVip;

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

    // 加载自定义背景列表
    List<String>? savedPaths = prefs.getStringList('custom_bg_paths');
    if (savedPaths != null) {
      _customBackgrounds = savedPaths
          .map(
            (path) => BackgroundOption(
              id: path,
              imageUrl: path,
              isVip: true,
              isLocal: true,
            ),
          )
          .toList();
    }

    // 检查 VIP
    _isUserVip = false;
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

  // 添加自定义背景
  Future<void> addCustomBackground(String path) async {
    final newOption = BackgroundOption(
      id: path,
      imageUrl: path,
      isVip: true,
      isLocal: true,
    );

    // 2. 加到列表最前面
    _customBackgrounds.insert(0, newOption);

    _currentBackgroundUrl = path;

    await _saveCustomPaths();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_bg', path);

    notifyListeners();
  }

  // 删除自定义背景
  Future<void> removeCustomBackground(BackgroundOption option) async {
    // 从列表中移除
    _customBackgrounds.removeWhere((element) => element.id == option.id);

    // 重置为默认背景
    if (_currentBackgroundUrl == option.imageUrl) {
      _currentBackgroundUrl = _presetBackgrounds.first.imageUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_bg', _currentBackgroundUrl);
    }

    await _saveCustomPaths();

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

  // 保存路径列表到 SharedPreferences
  Future<void> _saveCustomPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> paths = _customBackgrounds
        .map((e) => e.imageUrl)
        .toList();
    await prefs.setStringList('custom_bg_paths', paths);
  }
}

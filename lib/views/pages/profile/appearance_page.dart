// pages/appearance_page.dart
import 'dart:io'; // 用于显示本地图片预览
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 引入选图插件
import 'package:provider/provider.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:malay/views/widgets/theme_widget.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  // 处理上传逻辑
  Future<void> _handleUpload(BuildContext context) async {
    final provider = context.read<ThemeProvider>();

    // 1. 检查 VIP 权限
    if (!provider.isUserVip) {
      _showVipDialog(context);
      return;
    }

    // 2. 打开相册选图
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await provider.addCustomBackground(image.path);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Custom background set!")));
    }
  }

  void _confirmDelete(BuildContext context, BackgroundOption option) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text(
          "Are you sure you want to delete this custom background?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<ThemeProvider>().removeCustomBackground(option);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showVipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("VIP Feature"),
        content: const Text("Upload custom background is a VIP feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 跳转支付页面
            },
            child: const Text("Upgrade"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final backgrounds = themeProvider.backgrounds;

    return Scaffold(
      appBar: AppBar(title: const Text("Theme")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              // 数量 +1，因为多了一个上传按钮
              itemCount: backgrounds.length + 1,
              itemBuilder: (context, index) {
                // ==========================================
                // 情况 1: 第一个格子 -> 自定义上传按钮
                // ==========================================
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => _handleUpload(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Upload Custom",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 只有非 VIP 才显示锁图标
                          if (!themeProvider.isUserVip)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "VIP",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                // ==========================================
                // 情况 2: 普通背景图 (index - 1)
                // ==========================================
                final bgOption = backgrounds[index - 1];
                final isSelected =
                    themeProvider.currentBackgroundUrl == bgOption.imageUrl;
                final isLocked = bgOption.isVip && !themeProvider.isUserVip;

                return GestureDetector(
                  onTap: () async {
                    try {
                      await context.read<ThemeProvider>().changeBackground(
                        bgOption,
                      );
                    } catch (e) {
                      _showVipDialog(context); // 复用上面的弹窗
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: UniversalBackgroundImage(
                          imageUrl: bgOption.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 3),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        ),
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, color: Colors.amber, size: 40),
                                Text(
                                  "VIP",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (bgOption.isLocal)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(context, bgOption),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

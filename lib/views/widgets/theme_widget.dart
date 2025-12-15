// lib/views/widgets/universal_background_image.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniversalBackgroundImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const UniversalBackgroundImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 如果是网络图片
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }
    // 2. 否则认为是本地文件路径
    else {
      // 【关键修复】处理可能存在的 file:// 前缀
      String cleanPath = imageUrl;
      if (imageUrl.startsWith('file://')) {
        // 去掉前缀，保留后面的路径
        cleanPath = imageUrl.substring(7);
      }

      // 调试用：打印路径检查文件是否存在
      final file = File(cleanPath);
      if (!file.existsSync()) {
        print("❌ [UniversalBackgroundImage] 文件不存在: $cleanPath");
      }

      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // 调试用：打印具体报错信息
          print("❌ [UniversalBackgroundImage] 加载失败: $error");
          print("❌ [UniversalBackgroundImage] 原始路径: $imageUrl");

          // 临时改成红色，方便你确认是不是这里出错了。
          // 如果你在屏幕上看到红色（或者透过磨砂看到粉色），说明就是 Image.file 读不到文件。
          return Container(color: Colors.red.withOpacity(0.3));
        },
      );
    }
  }
}

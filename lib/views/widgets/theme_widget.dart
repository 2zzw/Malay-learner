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
    // 2.本地文件
    else {
      String cleanPath = imageUrl;
      if (imageUrl.startsWith('file://')) {
        cleanPath = imageUrl.substring(7);
      }

      final file = File(cleanPath);
      if (!file.existsSync()) {
        print("❌ [UniversalBackgroundImage] 文件不存在: $cleanPath");
      }

      return Image.file(file, fit: fit);
    }
  }
}

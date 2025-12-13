import 'package:flutter/material.dart';

// 把这个函数复制到你的代码里 (例如放在 class 外面)
void showTopMessage(BuildContext context, String message) {
  OverlayEntry? overlayEntry;

  // 移除 Overlay 的函数
  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10, // 也就是状态栏高度 + 10px 间距
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87, // 深色背景
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // 插入到屏幕中
  Overlay.of(context).insert(overlayEntry!);

  // 2秒后自动消失
  Future.delayed(const Duration(seconds: 2), () {
    if (overlayEntry != null) {
      removeOverlay();
    }
  });
}

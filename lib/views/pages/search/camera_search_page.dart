import 'package:flutter/material.dart';
import 'search_page.dart'; // 为了使用 Word 模型
import '../word_detail_page.dart'; // 为了跳转

class CameraSearchPage extends StatefulWidget {
  const CameraSearchPage({super.key});

  @override
  State<CameraSearchPage> createState() => _CameraSearchPageState();
}

class _CameraSearchPageState extends State<CameraSearchPage>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  // 模拟长按后的识别逻辑
  void _startScanning() {
    setState(() => _isScanning = true);
    _scanController.repeat(reverse: true);

    // 模拟 1.5秒后识别出结果
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isScanning = false);
        _scanController.stop();
        _showResultDialog();
      }
    });
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    _scanController.reset();
  }

  // 弹出识别结果卡片
  void _showResultDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Detected Word",
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.teal, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Makan",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "/ma-kan/",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Def: To put food into your mouth and swallow it.",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: const Text(
                    "Saya suka makan nasi lemak.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        // 点击查看详情
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailPage(),
                            ),
                          );
                        },
                        child: const Text("View Detail"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 模拟摄像头预览背景 (使用模糊图片模拟)
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
            color: Colors.black45, // 压暗背景
            colorBlendMode: BlendMode.darken,
          ),

          // 2. 顶部工具栏
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Focus Word",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 中间取景框
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 扫描框
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // 四角高亮装饰
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _Corner(isTop: true, isLeft: true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _Corner(isTop: true, isLeft: false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _Corner(isTop: false, isLeft: true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _Corner(isTop: false, isLeft: false),
                      ),
                      // 中心十字
                      const Center(
                        child: Icon(Icons.add, color: Colors.white54, size: 30),
                      ),
                      // 扫描时的动态效果
                      if (_isScanning)
                        Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Align word within frame",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // 4. 底部操作区
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onLongPress: _startScanning,
                  onLongPressUp: _stopScanning,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isScanning ? 90 : 80,
                    height: _isScanning ? 90 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(
                        color: _isScanning ? Colors.blue : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isScanning
                              ? Colors.blue
                              : Colors.blue.shade400,
                        ),
                        child: const Center(
                          child: Text(
                            "Scan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Long press to scan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 辅助组件：角落对焦线
class _Corner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _Corner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    const double size = 20;
    const double thickness = 3;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}

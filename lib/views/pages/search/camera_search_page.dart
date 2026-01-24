import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:malay/data/word_model.dart';
import 'package:malay/utils/show_top_message.dart';
import 'package:malay/views/pages/word_detail_page.dart';
import 'package:translator/translator.dart';
import '../../../data/database_helper.dart';
import '../../../data/tts_helper.dart';
import 'package:flutter/services.dart';

class CameraOcrPage extends StatefulWidget {
  const CameraOcrPage({super.key});

  @override
  State<CameraOcrPage> createState() => _CameraOcrPageState();
}

class _CameraOcrPageState extends State<CameraOcrPage> {
  CameraController? _controller;
  final translator = GoogleTranslator();
  final ImagePicker _picker = ImagePicker();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSentence = false;

  // 百度 API Key
  final String _apiKey = "5xrVbswskRM8RcBFteZCJ8dR";
  final String _secretKey = "PXtcKUPC2MtIzRUdpo3jnWjuzZZLbMyr";
  String? _baiduToken;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _fetchBaiduToken();
  }

  @override
  void dispose() {
    TtsHelper().stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await TtsHelper().speak(text);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("没有检测到相机，可能是模拟器");
      if (mounted) setState(() => _isCameraInitialized = false);
      return;
    }
    final rearCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _fetchBaiduToken() async {
    try {
      final url = Uri.parse(
        "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=$_apiKey&client_secret=$_secretKey",
      );
      final response = await http.post(url);
      final data = jsonDecode(response.body);
      _baiduToken = data['access_token'];
    } catch (e) {
      debugPrint("Token获取失败: $e");
    }
  }

  // 拍照取词 (长按触发)
  Future<void> _onLongPressStart() async {
    if (_isProcessing) return;
    // 如果相机没初始化，无法拍照，直接返回或提示
    if (!_isCameraInitialized || _controller == null) {
      _showToast("The camera is not available");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await _controller!.takePicture();
      File imageFile = File(photo.path);
      await _processImagePipeline(imageFile);
    } catch (e) {
      _showToast("Failed to take photo: $e");
      setState(() => _isProcessing = false);
    }
  }

  // 相册选图
  Future<void> _onGalleryPressed() async {
    if (_isProcessing) return;

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        File imageFile = File(photo.path);
        await _processImagePipeline(imageFile);
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showToast("Failed to pick image: $e");
    }
  }

  // 裁剪 -> OCR -> 后端 -> 弹窗
  Future<void> _processImagePipeline(File imageToProcess) async {
    try {
      // 裁剪
      File croppedImage = await _cropImageToFocusArea(imageToProcess);

      // 百度 OCR
      String? recognizedWord = await _performBaiduOcr(croppedImage);
      _isSentence = recognizedWord?.trim().contains(' ') ?? true;

      if (recognizedWord != null && recognizedWord.isNotEmpty) {
        // 数据库查词
        if (_isSentence) {
          if (mounted) _showSentCard(recognizedWord);
        } else {
          Word? wordInfo = await DatabaseHelper().getWordDetail(recognizedWord);
          if (mounted) _showWordCard(wordInfo);
        }
      } else {
        _showToast("No word recognized");
      }
    } catch (e) {
      _showToast("Processing failed: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 图片裁剪逻辑
  Future<File> _cropImageToFocusArea(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) return imageFile;

    int cropW = (original.width * 0.8).toInt();
    int cropH = (original.height * 0.15).toInt();
    int x = (original.width - cropW) ~/ 2;
    int y = (original.height - cropH) ~/ 2;

    img.Image cropped = img.copyCrop(
      original,
      x: x,
      y: y,
      width: cropW,
      height: cropH,
    );

    File newFile = File(imageFile.path.replaceFirst('.jpg', '_crop.jpg'));
    await newFile.writeAsBytes(img.encodeJpg(cropped));
    return newFile;
  }

  // 百度 OCR 请求
  Future<String?> _performBaiduOcr(File image) async {
    if (_baiduToken == null) await _fetchBaiduToken();
    if (_baiduToken == null) return null;

    final bytes = await image.readAsBytes();
    String base64Img = base64Encode(bytes);
    String encodedImg = Uri.encodeComponent(base64Img);

    final url = Uri.parse(
      "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=$_baiduToken",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: "image=$encodedImg&language_type=ENG",
      );

      final data = jsonDecode(response.body);
      if (data['words_result'] != null &&
          (data['words_result'] as List).isNotEmpty) {
        return data['words_result'][0]['words'];
      }
    } catch (e) {
      debugPrint("OCR error: $e");
    }
    return null;
  }

  // --- UI 组件 ---

  void _showWordCard(Word? info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * (_isSentence ? 0.6 : 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              _buildWordView(info),
            ],
          ),
        );
      },
    );
  }

  void _showSentCard(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * (_isSentence ? 0.6 : 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              _buildSentenceView(text), //如果是句子
            ],
          ),
        );
      },
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double scanW = MediaQuery.of(context).size.width * 0.8;
    double scanH = 100.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 相机预览
          if (_isCameraInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  "模拟器模式\n左下角选图，长按按钮无效",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ),
            ),

          // 2. 挖孔遮罩层
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54,
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanW,
                    height: scanH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              // 关键：确保不被刘海屏遮挡
              child: Padding(
                padding: const EdgeInsets.all(16.0), // 给一点边距
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // 退出页面
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54, // 半透明黑底，保证在亮色背景也能看清
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close, // 使用 X 号
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 3. 扫描框装饰
          Center(
            child: Container(
              width: scanW,
              height: scanH,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.greenAccent : Colors.white70,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isProcessing
                  ? const Center(
                      child: Text(
                        "识别中...",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Center(child: Icon(Icons.add, color: Colors.white30)),
            ),
          ),

          // 4. 底部提示
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: const Text(
              "Tap to Scan",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // --- 新增：左下角相册按钮 ---
          Positioned(
            left: 30,
            bottom: 65, // 垂直高度大致对齐中间大按钮的中心
            child: GestureDetector(
              onTap: _onGalleryPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // 5. 长按按钮 (保持居中，仅用于拍照)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onLongPress: _onLongPressStart, // 只保留长按
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isProcessing ? 85 : 75,
                  height: _isProcessing ? 85 : 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isProcessing
                          ? Colors.greenAccent
                          : Colors.grey[300]!,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(
                          _isProcessing ? 0.5 : 0,
                        ),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search,
                    size: 35,
                    color: _isProcessing ? Colors.green : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceView(String text) {
    // 使用 FutureBuilder 同时并发请求中文和英文翻译
    return FutureBuilder(
      future: Future.wait([
        translator.translate(text, from: 'ms', to: 'zh-cn'), // 马 -> 中
        translator.translate(text, from: 'ms', to: 'en'), // 马 -> 英
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text("translate failed"));
        }

        final results = snapshot.data as List<Translation>;
        final String zhText = results[0].text;
        final String enText = results[1].text;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // 中文翻译
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "CN",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "中文",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              zhText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 20),

            // 英文翻译
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "EN",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "English",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 30),
            // 句子也可以加入生词本（可选）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    showTopMessage(
                      context,
                      'Successfully copied to the clipboard.',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Copy"),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 场景 B: 单词视图 (你原来的代码封装)
  // ==========================================
  Widget _buildWordView(Word? info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              info?.word ?? '',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                // 这里调用发音
                _speak(info?.word ?? '');
              },
              icon: const Icon(Icons.volume_up, color: Colors.blue, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "EN",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              info?.english ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                decoration: TextDecoration.underline,
                decorationColor: Colors.black12,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "CN",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              info?.chinese ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                decoration: TextDecoration.underline,
                decorationColor: Colors.black12,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 这里记得调用你之前写的 FirebaseHelper().addFavorite()
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordDetailPage(word: info!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Details"),
          ),
        ),
      ],
    );
  }
}

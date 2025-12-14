import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  // 1. 私有构造函数，防止外部直接 new TtsHelper()
  TtsHelper._internal();

  // 2. 静态变量保存唯一实例
  static final TtsHelper _instance = TtsHelper._internal();

  // 3. 工厂构造函数，每次调用 TtsHelper() 都返回同一个 _instance
  factory TtsHelper() => _instance;

  // 内部持有的 flutterTts 对象
  final FlutterTts _flutterTts = FlutterTts();

  // 标记是否已经初始化
  bool _isInitialized = false;

  // 4. 初始化方法 (建议在 App 启动时调用，或者第一次发音前自动调用)
  Future<void> init() async {
    if (_isInitialized) return; // 避免重复初始化

    // 设置语言 (马来语)
    await _flutterTts.setLanguage("ms-MY");

    // 设置语速 (0.5 是半速，根据需要调整)
    await _flutterTts.setSpeechRate(0.3);

    // 设置音量
    await _flutterTts.setVolume(1.0);

    // iOS 必须设置这个，否则静音模式下没声音
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ]);

    // 监听错误 (可选)
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    _isInitialized = true;
  }

  // 5. 核心功能：朗读
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // 确保已初始化 (防御性编程)
    if (!_isInitialized) {
      await init();
    }

    // 停止上一次的播放 (防止重音) 并播放新的
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  // 6. 停止播放 (通常在页面销毁时调用)
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

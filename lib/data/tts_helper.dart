import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  TtsHelper._internal();

  static final TtsHelper _instance = TtsHelper._internal();

  factory TtsHelper() => _instance;

  final FlutterTts _flutterTts = FlutterTts();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("ms-MY");
    await _flutterTts.setSpeechRate(0.3);
    await _flutterTts.setVolume(1.0);

    // iOS 设置，否则静音模式下没声音
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ]);

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (!_isInitialized) {
      await init();
    }

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../data/word_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordDetailPage extends StatefulWidget {
  final Word word;

  const WordDetailPage({super.key, required this.word});

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  late final Word word;
  late FlutterTts? flutterTts;

  @override
  void initState() {
    super.initState();
    word = widget.word;
    initTts(); // 初始化TTS
  }

  // 3. 初始化配置
  Future<void> initTts() async {
    flutterTts = FlutterTts();

    // 设置语言为马来语 (Malaysia)
    // 如果手机没有马来语包，它可能会回退到默认语言，建议用户在手机设置里下载语音包
    await flutterTts?.setLanguage("ms-MY");

    // 可选：设置语速 (0.0 ~ 1.0)
    await flutterTts?.setSpeechRate(0.5);

    // 可选：设置音量 (0.0 ~ 1.0)
    await flutterTts?.setVolume(1.0);

    // iOS 特殊处理：确保在静音模式下也能发声
    await flutterTts?.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
    );
  }

  @override
  void dispose() {
    flutterTts?.stop(); // 页面销毁时停止播放
    super.dispose();
  }

  // 4. 发音函数
  Future<void> _speak(String text) async {
    // 这里的 word.text 是你要读的单词
    await flutterTts?.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<ThemeProvider>().currentBackgroundUrl;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border,
              color: Colors.black87,
              size: 28,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(bgUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withValues(alpha: 0.6)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 15),

                  _buildCombinedExamplesCard(),

                  const SizedBox(height: 15),

                  _buildPhrasesCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            InkWell(
              // 5. 用 InkWell 或 GestureDetector 包裹你的 Container
              onTap: () => _speak(word.word), // 点击调用发音
              borderRadius: BorderRadius.circular(20), // 只有 InkWell 需要这个来适配圆角
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "MY",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),
            Text(
              word.phonetic,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontFamily: 'San Francisco',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              word.english,
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

        const SizedBox(height: 16),
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
              word.chinese,
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
      ],
    );
  }

  Widget _buildCombinedExamplesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (word.sentences.isNotEmpty) _buildSingleExample(word.sentences[0]),

          if (word.sentences.length > 1) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
            const SizedBox(height: 16),
            _buildSingleExample(word.sentences[1]),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleExample(Map<String, dynamic> sentence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          // 5. 用 InkWell 或 GestureDetector 包裹你的 Container
          onTap: () => _speak(sentence['malay']), // 点击调用发音
          borderRadius: BorderRadius.circular(20),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                height: 1.4,
                fontFamily: 'San Francisco',
              ),
              children: _highlightKeyword(sentence['malay']!, word.word),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sentence['english'] ?? '',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sentence['chinese'] ?? '',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPhrasesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8), // 减少内边距，利用 ListTile
      decoration: _cardDecoration(),
      child: Column(
        children: word.collocations.asMap().entries.map((entry) {
          final index = entry.key;
          final phrase = entry.value;
          final phraseEnglish = phrase['meaning']?['english'] ?? '';
          final phraseChinese = phrase['meaning']?['chinese'] ?? '';
          final isLast = index == word.collocations.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                minLeadingWidth: 10,
                title: InkWell(
                  // 5. 用 InkWell 或 GestureDetector 包裹你的 Container
                  onTap: () => _speak(phrase['phrase']), // 点击调用发音
                  borderRadius: BorderRadius.circular(20),
                  child: Text(
                    phrase['phrase']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phraseEnglish,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phraseChinese,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.grey.withValues(alpha: 0.1),
                  indent: 56,
                  endIndent: 20,
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  List<TextSpan> _highlightKeyword(String sentence, String keyword) {
    if (keyword.isEmpty) return [TextSpan(text: sentence)];
    List<TextSpan> spans = [];
    String lowerSentence = sentence.toLowerCase();
    String lowerKeyword = keyword.toLowerCase();
    int start = 0;
    int indexOfKeyword = lowerSentence.indexOf(lowerKeyword);

    while (indexOfKeyword != -1) {
      if (indexOfKeyword > start) {
        spans.add(TextSpan(text: sentence.substring(start, indexOfKeyword)));
      }
      spans.add(
        TextSpan(
          text: sentence.substring(
            indexOfKeyword,
            indexOfKeyword + keyword.length,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold), // 加粗
        ),
      );
      start = indexOfKeyword + keyword.length;
      indexOfKeyword = lowerSentence.indexOf(lowerKeyword, start);
    }
    if (start < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(start)));
    }
    return spans;
  }
}

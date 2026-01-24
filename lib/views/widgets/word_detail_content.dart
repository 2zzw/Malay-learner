import 'package:flutter/material.dart';
import '../../../data/word_model.dart';
import '../../data/tts_helper.dart';

class WordDetailContent extends StatelessWidget {
  final Word word;

  const WordDetailContent({super.key, required this.word});

  // 内部统一的发音处理
  Future<void> _speak(String text) async {
    await TtsHelper().speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 15),
        _buildCombinedExamplesCard(),
        const SizedBox(height: 15),
        _buildPhrasesCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- 头部区域 (单词、音标、释义) ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.word,
          style: const TextStyle(
            fontFamily: 'Serif',
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 发音按钮
            InkWell(
              onTap: () => _speak(word.word),
              borderRadius: BorderRadius.circular(20),
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
        // 英文释义
        _buildMeaningRow("EN", word.english),
        const SizedBox(height: 10),
        // 中文释义
        _buildMeaningRow("CN", word.chinese),
      ],
    );
  }

  Widget _buildMeaningRow(String tag, String text) {
    return Row(
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
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              decoration: TextDecoration.underline,
              decorationColor: Colors.black12,
              decorationStyle: TextDecorationStyle.dashed,
            ),
          ),
        ),
      ],
    );
  }

  // --- 例句卡片 ---
  Widget _buildCombinedExamplesCard() {
    if (word.sentences.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSingleExample(word.sentences[0]),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
            const SizedBox(width: 16),
            InkWell(
              onTap: () => _speak(sentence['malay']),
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 24,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (sentence['english'] != null)
          Text(
            sentence['english'],
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        if (sentence['chinese'] != null)
          Text(
            sentence['chinese'],
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  // --- 短语/搭配卡片 ---
  Widget _buildPhrasesCard() {
    if (word.collocations.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.4,
                            fontFamily: 'San Francisco',
                          ),
                          children: _highlightKeyword(
                            phrase['phrase']!,
                            word.word,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _speak(phrase['phrase']),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (phraseEnglish.isNotEmpty)
                      Text(
                        phraseEnglish,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (phraseChinese.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phraseChinese,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.grey.withValues(alpha: 0.1),
                  indent: 20,
                  endIndent: 20,
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- 工具方法 ---
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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

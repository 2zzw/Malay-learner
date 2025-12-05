import 'dart:ui';
import 'package:flutter/material.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

class WordData {
  final String word;
  final String phonetic;
  final String simpleDefinition;
  final List<ExampleData> examples; // 例句列表
  final List<PhraseData> phrases; // 新增：词组搭配列表

  WordData({
    required this.word,
    required this.phonetic,
    required this.simpleDefinition,
    required this.examples,
    required this.phrases,
  });
}

class ExampleData {
  final String sentence;
  final String translation;
  final String keyword;

  ExampleData({
    required this.sentence,
    required this.translation,
    required this.keyword,
  });
}

class PhraseData {
  final String phrase;
  final String translation;

  PhraseData({required this.phrase, required this.translation});
}

// 模拟数据：Makan
final mockData = WordData(
  word: "makan",
  phonetic: "/ma-kan/",
  simpleDefinition: "v. 吃，进食；耗费",
  examples: [
    // 只要两个例句
    ExampleData(
      sentence: "Saya hendak makan nasi lemak pagi ini.",
      translation: "我今早想吃椰浆饭。",
      keyword: "makan",
    ),
    ExampleData(
      sentence: "Projek ini makan banyak masa.",
      translation: "这个项目耗费了大量时间。",
      keyword: "makan",
    ),
  ],
  phrases: [
    PhraseData(phrase: "makan angin", translation: "旅行 / 散心 (字面: 吃风)"),
    PhraseData(phrase: "makan suap", translation: "受贿 / 贪污 (字面: 吃饲料)"),
    PhraseData(phrase: "makan gaji", translation: "打工 / 领薪水"),
  ],
);

// =============================================================================
// WORD DETAIL PAGE
// =============================================================================

class WordDetailPage extends StatelessWidget {
  // 实际项目中可以通过构造函数传入数据
  final WordData data = mockData;

  WordDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          // 1. 背景层：莫奈风格 + 模糊
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withValues(alpha: 0.6)),
          ),

          // 2. 内容层
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header (单词信息) ---
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
          data.word,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
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
                    color: Colors.black.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              data.phonetic,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontFamily: 'San Francisco',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          data.simpleDefinition,
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
    );
  }

  // 构建合并的例句卡片（包含两个例句）
  Widget _buildCombinedExamplesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 例句 1
          if (data.examples.isNotEmpty) _buildSingleExample(data.examples[0]),

          // 分隔线
          if (data.examples.length > 1) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 16),
            // 例句 2
            _buildSingleExample(data.examples[1]),
          ],
        ],
      ),
    );
  }

  // 单个例句组件
  Widget _buildSingleExample(ExampleData example) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              height: 1.4,
              fontFamily: 'San Francisco',
            ),
            children: _highlightKeyword(example.sentence, example.keyword),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          example.translation,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 构建词组搭配卡片
  Widget _buildPhrasesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8), // 减少内边距，利用 ListTile
      decoration: _cardDecoration(),
      child: Column(
        children: data.phrases.asMap().entries.map((entry) {
          final index = entry.key;
          final phrase = entry.value;
          final isLast = index == data.phrases.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                minLeadingWidth: 10,
                leading: const Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: Colors.teal,
                ),
                title: Text(
                  phrase.phrase,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  phrase.translation,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.grey.withOpacity(0.1),
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
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
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

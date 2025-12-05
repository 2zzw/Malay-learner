import 'package:flutter/material.dart';
import '../word_detail_page.dart'; // 导入单词详情页

class WordListPage extends StatelessWidget {
  final String bookTitle;

  const WordListPage({super.key, required this.bookTitle});

  // 模拟单词列表
  static const List<String> words = [
    "delve",
    "exact",
    "exactly",
    "elicit",
    "traditional",
    "lack",
    "regent",
    "burgeon",
    "argue",
    "arguably",
    "barely",
    "hierarchy",
    "guidance",
    "easy-going",
    "makan",
    "minum",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 纯白背景
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$bookTitle Vocabulary",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列表头部信息 (如: Word List 1 94词)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              "Word List 1  ·  ${words.length} words",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),

          // 单词列表
          Expanded(
            child: ListView.separated(
              itemCount: words.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 20),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  title: Text(
                    words[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // 稍微加粗，类似原图
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    // 跳转到详情页
                    _navigateToDetail(context, words[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String word) {
    // 构造模拟数据跳转
    final detailData = WordData(
      word: word,
      phonetic: "/.../",
      simpleDefinition: "v. Definition of $word",
      examples: [
        ExampleData(
          sentence: "Example sentence for $word.",
          translation: "$word 的例句翻译。",
          keyword: word,
        ),
      ],
      phrases: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordDetailPage(),
      ), // 需传入 data: detailData
    );
  }
}

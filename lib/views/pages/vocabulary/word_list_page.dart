import 'package:flutter/material.dart';
// 1. 导入你的 DatabaseHelper 和 Word 模型
import '../../../data/database_helper.dart'; // 请确保路径正确
import '../../../data/word_model.dart';
import '../../../views/pages/word_detail_page.dart';

class WordListPage extends StatefulWidget {
  const WordListPage({super.key, required this.bookTitle});

  final String bookTitle; // 这里就是 category

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late Future<List<Word>> _searchResults;

  // 修改：从 SQLite 获取数据
  Future<List<Word>> _fetchWords(String category) async {
    // 调用我们在 DatabaseHelper 里新写的方法
    return await DatabaseHelper().getWordsByCategory(category);
  }

  @override
  void initState() {
    super.initState();
    _searchResults = _fetchWords(widget.bookTitle);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Word>>(
      future: _searchResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No words found in this category'));
        }

        final words = snapshot.data!;

        return WordListState(words: words);
      },
    );
  }
}

// WordListState 保持原样，没有任何逻辑需要改动
class WordListState extends StatelessWidget {
  final List<Word> words;

  const WordListState({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          words.isNotEmpty ? words[0].category : 'Vocabulary',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              "Word List · ${words.length} words",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
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
                    words[index].word,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WordDetailPage(word: words[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

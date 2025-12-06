import 'package:flutter/material.dart';
import 'package:malay/views/pages/search/search_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/word_model.dart';
import '../../../views/pages/word_detail_page.dart';

class WordListPage extends StatefulWidget {
  const WordListPage({super.key, required this.bookTitle});

  final String bookTitle;

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late final String bookTitle;
  late Future<List<Word>> _searchResults;

  Future<List<Word>> _fetchWords(String category) async {
    String baseUrl = 'http://127.0.0.1:8000';
    final url = Uri.parse('$baseUrl/words/category/$category');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load words');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Word.fromJson(json)).toList();
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
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No words found'));
        }

        final words = snapshot.data!;

        return WordListState(words: words);
      },
    );
  }
}

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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search, color: Colors.black87),
        //     onPressed: () {

        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.visibility_outlined, color: Colors.black87),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列表头部信息
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

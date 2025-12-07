import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:provider/provider.dart';
import 'camera_search_page.dart'; // 导入相机页
import '../word_detail_page.dart'; // 导入详情页
import '../../../data/word_model.dart';

// =============================================================================
// SEARCH PAGE UI
// =============================================================================
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 初始显示全部或最近搜索（这里模拟为空或全部）
    _searchResults = [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = [];
        // TODO: Implement actual search logic using _fetchWords or similar
        // For now, keeping it empty as we're not fetching data yet
      }
    });
  }

  List<Word> _filterWords(String query) {
    return _searchResults
        .where(
          (word) =>
              word.word.toLowerCase().contains(query.toLowerCase()) ||
              word.english.toLowerCase().contains(query.toLowerCase()) ||
              word.category.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
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
        title: const Text(
          "Kamus (Dictionary)",
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 背景层：高模糊处理，保证文字可读性
          Image.network(bgUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.white.withOpacity(0.85)),
          ),

          // 2. 内容层
          SafeArea(
            child: Column(
              children: [
                // 搜索框区域
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Hero(
                    tag: 'searchBar',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: "Search Malay or English...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.teal,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CameraSearchPage(),
                                  ),
                                );
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 结果列表
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _searchResults.length,
                    separatorBuilder: (ctx, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final word = _searchResults[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        title: Text(
                          word.word,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          word.english,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade300,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailPage(word: word),
                            ),
                          );
                        },
                      );
                    },
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

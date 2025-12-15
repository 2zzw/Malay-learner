import 'dart:async'; // 1. 引入 Timer 需要的库
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malay/views/widgets/theme_widget.dart';
import 'package:provider/provider.dart';
import 'package:malay/data/theme_provider.dart';
import './camera_search_page.dart';
import '../word_detail_page.dart';
import '../../../data/word_model.dart';
import '../../../data/database_helper.dart'; // 2. 引入数据库帮助类

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _searchResults = [];
  bool _isLoading = false; // 增加加载状态
  Timer? _debounce; // 3. 定义防抖计时器

  @override
  void dispose() {
    _debounce?.cancel(); // 页面销毁时记得关掉计时器
    _searchController.dispose();
    super.dispose();
  }

  // 4. 核心搜索逻辑
  void _onSearchChanged(String query) {
    // 如果之前的计时器还在跑，就取消它（说明用户又打字了）
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 启动一个新的计时器，300ms 后执行查询
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true; // 显示加载圈
      });

      // 调用数据库查询
      List<Word> results = await DatabaseHelper().searchByKeyword(query);

      // 更新 UI
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
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
          // 1. 背景层
          UniversalBackgroundImage(imageUrl: bgUrl),
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
                          onChanged: _onSearchChanged, // 绑定上面的搜索函数
                          autofocus: true, // 建议进入页面自动弹出键盘
                          decoration: InputDecoration(
                            hintText: "Search Malay / English / 中文...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.teal,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 如果有内容，显示清空按钮
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CameraOcrPage(),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _searchResults.isEmpty &&
                            _searchController.text.isNotEmpty
                      ? Center(
                          child: Text(
                            "No words found",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _searchResults.length,
                          separatorBuilder: (ctx, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final word = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: word.word,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: "  "),
                                    TextSpan(
                                      text: word.phonetic, // 加上音标更专业
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Text(
                                "${word.chinese} · ${word.english}", // 同时显示中文和英文含义
                                style: TextStyle(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                    builder: (context) =>
                                        WordDetailPage(word: word),
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

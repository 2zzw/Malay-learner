import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/firebase_helper.dart';
import '../../../data/database_helper.dart';
import '../../../data/word_model.dart';
import '../word_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // 定义一个 Future 用于存储加载任务
  late Future<List<Word>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  // 刷新列表的方法
  void _refreshList() {
    setState(() {
      _favoritesFuture = _loadFavorites();
    });
  }

  // 核心加载逻辑
  Future<List<Word>> _loadFavorites() async {
    try {
      // 1. 检查登录状态
      // 为了符合 Firebase 安全规则，必须登录。这里演示使用匿名登录。
      if (FirebaseAuth.instance.currentUser == null) {
        print("用户未登录，正在进行匿名登录...");
        await FirebaseAuth.instance.signInAnonymously();
      }

      // 2. 从 Firebase 获取收藏的 ID 列表
      // IDs 类似于 ["makan", "minum", "tidur"]
      final List<String> favIds = await FirebaseHelper().getFavoriteIds();

      if (favIds.isEmpty) {
        return []; // 如果云端没有数据，直接返回空列表
      }

      // 3. 根据 ID 从本地 SQLite 获取单词的详细信息
      // 这一步利用了我们刚才在 DatabaseHelper 里写的 getWordsByIds
      return await DatabaseHelper().getWordsByIds(favIds);
    } catch (e) {
      print("加载生词本出错: $e");
      // 抛出错误以便 FutureBuilder捕获并显示
      throw Exception("Failed to load favorites: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // 使用 RefreshIndicator 支持下拉刷新
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshList();
          await _favoritesFuture; // 等待刷新完成
        },
        child: FutureBuilder<List<Word>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            // 1. 加载中状态
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. 错误状态
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Load failed. Pull to refresh.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Error: ${snapshot.error}', // 调试用，上线可隐藏
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            // 3. 空数据状态
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go add some words!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              );
            }

            // 4. 显示列表
            final words = snapshot.data!;

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(), // 保证即使只有几行也能下拉刷新
              itemCount: words.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 20),
              itemBuilder: (context, index) {
                final word = words[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    word.word, // 马来语单词
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "${word.english} · ${word.chinese}", // 英文 · 中文
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () async {
                    // 跳转到详情页
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordDetailPage(word: word),
                      ),
                    );

                    // ⚠️ 关键步骤：
                    // 当从详情页返回时（await 结束），说明用户可能在详情页取消了收藏。
                    // 所以我们需要重新刷新列表，把取消收藏的词去掉。
                    _refreshList();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

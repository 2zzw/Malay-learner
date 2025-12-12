import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 请确保引入了你的 DatabaseHelper
import '../../../data/database_helper.dart';
import 'package:malay/data/theme_provider.dart'; // 你的主题 Provider
import 'word_list_page.dart'; // 你的单词列表页

// 1. 数据模型保持不变
class BookData {
  final String title;
  final String subtitle;
  final Color coverColor;
  final double heightRatio;
  final int numWords;

  BookData({
    required this.title,
    required this.subtitle,
    required this.coverColor,
    this.heightRatio = 1.0,
    required this.numWords,
  });
}

class VocabularyBookPage extends StatefulWidget {
  const VocabularyBookPage({super.key});

  @override
  State<VocabularyBookPage> createState() => _VocabularyBookPageState();
}

class _VocabularyBookPageState extends State<VocabularyBookPage> {
  // 2. 创建一个 Future 变量
  late Future<List<BookData>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  // 3. 核心逻辑：从数据库加载并转换为 BookData
  Future<List<BookData>> _loadBooks() async {
    // 调用 Helper 获取数据
    // 结果可能是: [{'category': 'Basic', 'count': 5}, {'category': 'Food', 'count': 10}]
    final data = await DatabaseHelper().getBooksFromDB();

    // 将数据库原始数据转换为 UI 需要的 BookData 对象
    return data.map((item) {
      String category = item['category'] ?? 'Uncategorized';
      int count = item['count'] ?? 0;

      // 这里调用一个辅助函数，根据分类名获取对应的 颜色/副标题
      // 这样既能用真实数据，又能保留你的设计风格
      return _mapCategoryToBookStyle(category, count);
    }).toList();
  }

  // 4. 样式映射配置 (保留你的设计精髓)
  BookData _mapCategoryToBookStyle(String category, int count) {
    switch (category) {
      case "Basic":
        return BookData(
          title: "Basic",
          subtitle: "Asas",
          coverColor: Colors.teal.shade300,
          numWords: count,
        );
      case "Daily":
        return BookData(
          title: "Daily",
          subtitle: "Harian",
          coverColor: Colors.orange.shade300,
          numWords: count,
        );
      case "Market":
        return BookData(
          title: "Market",
          subtitle: "Pasaran",
          coverColor: Colors.indigo.shade300,
          numWords: count,
        );
      case "Food":
        return BookData(
          title: "Food",
          subtitle: "Makanan",
          coverColor: Colors.red.shade300,
          numWords: count,
        );
      case "Campus":
        return BookData(
          title: "Campus",
          subtitle: "Kampus",
          coverColor: Colors.purple.shade300,
          numWords: count,
        );
      case "Travel":
        return BookData(
          title: "Travel",
          subtitle: "Perjalanan",
          coverColor: Colors.blue.shade300,
          numWords: count,
        );
      default:
        // 如果数据库里有新分类（比如用户自定义的），给一个默认样式
        return BookData(
          title: category,
          subtitle: "Lain-lain",
          coverColor: Colors.grey.shade400,
          numWords: count,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<ThemeProvider>().currentBackgroundUrl;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Pustaka (Library)",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.black87),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(bgUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),
          SafeArea(
            // 5. 使用 FutureBuilder 等待数据库返回
            child: FutureBuilder<List<BookData>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "空空如也\n请先在生词本或首页添加单词",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // 数据拿到后，进行左右分栏
                final books = snapshot.data!;
                final leftColumn = <BookData>[];
                final rightColumn = <BookData>[];

                for (var i = 0; i < books.length; i++) {
                  if (i % 2 == 0) {
                    leftColumn.add(books[i]);
                  } else {
                    rightColumn.add(books[i]);
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildColumn(context, leftColumn)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildColumn(context, rightColumn)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, List<BookData> books) {
    return Column(
      children: books.map((book) => _BookCard(book: book)).toList(),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookData book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // 传递书名（分类名）给列表页，以便查询该分类下的所有词
            builder: (context) => WordListPage(bookTitle: book.title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height:
            180 *
            book.heightRatio, // 这里的比例目前是 1.0，你可以根据 numWords 动态调整高度让 UI 更生动
        width: 140,
        decoration: BoxDecoration(
          color: book.coverColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 显示真实的单词数量
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${book.numWords} 词',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Icon(
                Icons.bookmark,
                color: Colors.white.withValues(alpha: 0.3),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

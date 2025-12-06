import 'dart:ui';
import 'package:flutter/material.dart';
import 'word_list_page.dart';

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

final List<BookData> mockBooks = [
  BookData(
    title: "Basic",
    subtitle: "Asas",
    coverColor: Colors.teal.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
  BookData(
    title: "Daily",
    subtitle: "Harian",
    coverColor: Colors.orange.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
  BookData(
    title: "Market",
    subtitle: "Pasaran",
    coverColor: Colors.indigo.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
  BookData(
    title: "Food",
    subtitle: "Makanan",
    coverColor: Colors.red.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
  BookData(
    title: "Campus",
    subtitle: "Kampus",
    coverColor: Colors.purple.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
  BookData(
    title: "Travel",
    subtitle: "Perjalanan",
    coverColor: Colors.blue.shade300,
    heightRatio: 1.0,
    numWords: 100,
  ),
];

class VocabularyBookPage extends StatelessWidget {
  const VocabularyBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final leftColumn = <BookData>[];
    final rightColumn = <BookData>[];

    for (var i = 0; i < mockBooks.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(mockBooks[i]);
      } else {
        rightColumn.add(mockBooks[i]);
      }
    }

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
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildColumn(context, leftColumn)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildColumn(context, rightColumn)),
                ],
              ),
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
            builder: (context) => WordListPage(bookTitle: book.title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180 * book.heightRatio,
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
                  // const SizedBox(height: 4),
                  // Text(
                  //   '${book.numWords} words',
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: Colors.white.withValues(alpha: 0.8),
                  //   ),
                  // ),
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

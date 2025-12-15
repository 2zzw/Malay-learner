import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malay/views/widgets/theme_widget.dart';
import 'package:provider/provider.dart';
import 'package:malay/data/firebase_helper.dart';
import 'package:malay/data/theme_provider.dart';
import '../../../data/word_model.dart';
import '../../data/tts_helper.dart';
// 引入刚刚新建的组件
import 'package:malay/views/widgets/word_detail_content.dart';

class WordDetailPage extends StatefulWidget {
  final Word word;

  const WordDetailPage({super.key, required this.word});

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  late final Word word;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    word = widget.word;
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    bool status = await FirebaseHelper().isFavorite(widget.word.id);
    if (mounted) {
      setState(() {
        isBookmarked = status;
      });
    }
  }

  @override
  void dispose() {
    TtsHelper().stop();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isBookmarked = !isBookmarked;
    });

    try {
      if (isBookmarked) {
        await FirebaseHelper().addFavorite(widget.word.id);
      } else {
        await FirebaseHelper().removeFavorite(widget.word.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isBookmarked = !isBookmarked;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.orange : Colors.black87,
              size: 28,
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景
          UniversalBackgroundImage(imageUrl: bgUrl),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withValues(alpha: 0.6)),
          ),

          // 内容区域
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              // 直接使用复用组件
              child: WordDetailContent(word: word),
            ),
          ),
        ],
      ),
    );
  }
}

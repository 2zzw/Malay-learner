// lib/views/widgets/word_card_modal.dart
import 'package:flutter/material.dart';
import 'package:malay/data/database_helper.dart';
import 'package:malay/data/word_model.dart';
import 'package:malay/data/tts_helper.dart';

class WordCardModal extends StatefulWidget {
  final String queryWord;

  const WordCardModal({super.key, required this.queryWord});

  @override
  State<WordCardModal> createState() => _WordCardModalState();
}

class _WordCardModalState extends State<WordCardModal> {
  bool _isLoading = true;
  Word? _wordInfo;

  @override
  void initState() {
    super.initState();
    _fetchWordData();
  }

  Future<void> _fetchWordData() async {
    final results = await DatabaseHelper().searchByKeyword(widget.queryWord);

    // 找到完全匹配的，或者取第一个
    Word? match;
    if (results.isNotEmpty) {
      // 优先找完全一样的
      match = results.firstWhere(
        (w) => w.word.toLowerCase() == widget.queryWord.toLowerCase(),
        orElse: () => results.first,
      );
    }

    if (mounted) {
      setState(() {
        _wordInfo = match;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wordInfo == null
          ? _buildNotFoundView()
          : _buildWordDetailView(_wordInfo!),
    );
  }

  Widget _buildNotFoundView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.queryWord,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text("未在词库中找到该词", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildWordDetailView(Word word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              word.word,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => TtsHelper().speak(word.word),
              icon: const Icon(Icons.volume_up, color: Colors.blue, size: 30),
            ),
          ],
        ),
        Text(
          "/${word.phonetic}/",
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),
        Text(word.chinese, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 5),
        Text(
          word.english,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("加入生词本"),
          ),
        ),
      ],
    );
  }
}

// 供外部调用的便捷函数
void showSmartWordCard(BuildContext context, String word) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WordCardModal(queryWord: word),
  );
}

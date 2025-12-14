// lib/views/pages/podcast/podcast_article_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malay/data/podcast_provider.dart';
import '../../widgets/word_card_modal.dart'; // 引入第一步写的卡片
import '../../widgets/mini_player.dart'; // 复用播放器逻辑(可选，或者用大播放器)

class PodcastArticlePage extends StatelessWidget {
  const PodcastArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PodcastProvider>();
    final episode = provider.currentEpisode;

    if (episode == null) return const Scaffold(); // 异常情况

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("正在播放"), // 或者显示文章标题
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. 大封面区域 (模仿 Apple Music 详情)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    episode.coverUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 简单进度条
                      LinearProgressIndicator(
                        value: provider.duration.inSeconds > 0
                            ? provider.position.inSeconds /
                                  provider.duration.inSeconds
                            : 0,
                        backgroundColor: Colors.grey[200],
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(provider.position),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatDuration(provider.duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 2. 可点击的文本区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableTextWrapper(
                text: episode.content,
                onWordTap: (word) {
                  // 核心：点击单词弹出详情
                  showSmartWordCard(context, word);
                },
              ),
            ),
          ),
        ],
      ),
      // 详情页底部也放一个播放控制栏，或者更复杂的控制面板
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, size: 36),
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              FloatingActionButton(
                onPressed: () =>
                    provider.isPlaying ? provider.pause() : provider.resume(),
                child: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, size: 36),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

// === 辅助组件：将长文本拆分为可点击的单词 ===
class SelectableTextWrapper extends StatelessWidget {
  final String text;
  final Function(String) onWordTap;

  const SelectableTextWrapper({
    super.key,
    required this.text,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    // 简单的按空格拆分
    // 如果需要处理标点符号（如 "makan." -> "makan"），需要用正则拆分
    // 这里使用简单的 split，实际生产建议用 RegExp
    List<String> words = text.split(' ');

    return Wrap(
      spacing: 4, // 单词间距
      runSpacing: 6, // 行间距
      children: words.map((rawWord) {
        // 去除标点符号，以便查词准确
        String cleanWord = rawWord.replaceAll(RegExp(r'[^\w\s]+'), '');

        return GestureDetector(
          onTap: () {
            if (cleanWord.isNotEmpty) {
              onWordTap(cleanWord);
            }
          },
          child: Text(
            rawWord, // 显示时保留标点
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
}

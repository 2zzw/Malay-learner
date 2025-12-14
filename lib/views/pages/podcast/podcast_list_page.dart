// lib/views/pages/podcast/podcast_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malay/data/podcast_provider.dart';
import '../../widgets/mini_player.dart';

class PodcastListPage extends StatefulWidget {
  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> {
  // 模拟数据
  final List<PodcastEpisode> episodes = [
    PodcastEpisode(
      id: '1',
      title: 'Ep 1: Introduction to Malay',
      content: 'Selamat pagi kawan kawan. Hari ini kita belajar bahasa Melayu. Ini adalah pelajaran pertama.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // 测试音频
      coverUrl: 'https://picsum.photos/200/200?random=1',
    ),
    PodcastEpisode(
      id: '2',
      title: 'Ep 2: Ordering Food',
      content: 'Saya nak makan nasi lemak. Nasi lemak sangat sedap dan pedas.',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://picsum.photos/200/200?random=2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Malay Podcast")),
      // 使用 Stack 将 MiniPlayer 悬浮在最下方
      body: Stack(
        children: [
          // 列表内容
          ListView.separated(
            padding: const EdgeInsets.only(bottom: 80), // 留出底部播放器的空间
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(episode.coverUrl, width: 50, height: 50, fit: BoxFit.cover),
                ),
                title: Text(episode.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("2 mins • Beginner"),
                trailing: const Icon(Icons.play_circle_outline, color: Colors.teal),
                onTap: () {
                  // 点击列表开始播放
                  context.read<PodcastProvider>().playEpisode(episode);
                },
              );
            },
          ),

          // 悬浮的底部播放器
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea( // 适配 iPhone 底部黑条
              child: MiniPlayer(),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/views/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/podcast_provider.dart';
import '../pages/podcast/podcast_article_page.dart'; // 下一步会创建

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听 Provider
    final provider = context.watch<PodcastProvider>();
    final episode = provider.currentEpisode;

    // 如果没有正在播放的，直接返回空盒子（不显示）
    if (episode == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // 点击整个条，进入文章详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true, // iOS 风格的从下往上弹出
            builder: (context) => const PodcastArticlePage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8), // 悬浮感边距
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95), // 稍微一点透明
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 封面图
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(episode.coverUrl, width: 48, height: 48, fit: BoxFit.cover),
              ),
            ),
            
            // 标题
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),

            // 控制按钮
            IconButton(
              icon: Icon(provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: () {
                if (provider.isPlaying) {
                  provider.pause();
                } else {
                  provider.resume();
                }
              },
            ),
            
            // 关闭按钮
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
              onPressed: () {
                provider.close();
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
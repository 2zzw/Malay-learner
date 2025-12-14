// lib/data/podcast_provider.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// 定义一个简单的播客模型
class PodcastEpisode {
  final String id;
  final String title;
  final String content; // 文章内容
  final String audioUrl;
  final String coverUrl;

  PodcastEpisode({
    required this.id,
    required this.title,
    required this.content,
    required this.audioUrl,
    required this.coverUrl,
  });
}

class PodcastProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  PodcastEpisode? _currentEpisode;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  PodcastEpisode? get currentEpisode => _currentEpisode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  PodcastProvider() {
    // 监听播放状态
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // 监听进度
    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    
    // 监听播放结束
    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  // 播放指定剧集
  Future<void> playEpisode(PodcastEpisode episode) async {
    // 如果点击的是当前正在放的，就只切换暂停/播放
    if (_currentEpisode?.id == episode.id) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume();
      }
    } else {
      // 播放新的
      _currentEpisode = episode;
      await _audioPlayer.stop();
      // 这里使用 UrlSource，如果是本地资源用 AssetSource
      await _audioPlayer.play(UrlSource(episode.audioUrl));
    }
    notifyListeners();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // 关闭播放器（清除当前选中）
  Future<void> close() async {
    await _audioPlayer.stop();
    _currentEpisode = null;
    _position = Duration.zero;
    notifyListeners();
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malay/views/pages/search/search_page.dart';
import 'package:malay/views/pages/vocabulary/vocabulary_book_page.dart';
import 'package:malay/views/pages/stats_page.dart';
import 'package:malay/views/pages/profile/profile_page.dart';
import 'package:malay/views/pages/learning_session_page.dart';
import 'package:malay/views/pages/ai_assistant_page.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:provider/provider.dart';

// =============================================================================
// 2. MODELS
// =============================================================================

class DailyContent {
  final String imageUrl;
  final MalayProverb proverb;

  DailyContent({required this.imageUrl, required this.proverb});
}

class MalayProverb {
  final String malay;
  final String english;

  MalayProverb({required this.malay, required this.english});
}

class UserStats {
  final int newWordsCount;
  final int reviewWordsCount;

  UserStats({required this.newWordsCount, required this.reviewWordsCount});
}

// =============================================================================
// 3. DATA REPOSITORY (Mock Data)
// =============================================================================

class AppRepository {
  static DailyContent getTodayContent() {
    return DailyContent(
      // 莫奈风格睡莲/风景画，符合原图色调
      imageUrl:
          'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
      proverb: MalayProverb(
        malay: "Sediakan payung sebelum hujan.",
        english:
            "Prepare the umbrella before it rains. (Better safe than sorry)",
      ),
    );
  }

  static UserStats getUserStats() {
    return UserStats(newWordsCount: 15, reviewWordsCount: 42);
  }
}

// =============================================================================
// 4. CORE WIDGETS (Reused Components)
// =============================================================================

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color tint;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.2,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.tint = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final borderR = borderRadius ?? BorderRadius.circular(20);

    Widget container = ClipRRect(
      borderRadius: borderR,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint.withOpacity(opacity),
            borderRadius: borderR,
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }
    return container;
  }
}

// =============================================================================
// 5. FEATURE WIDGETS
// =============================================================================

// 顶部栏：头像与搜索
class TopBar extends StatelessWidget {
  final VoidCallback onAvatarTap;
  final VoidCallback onSearchTap;

  const TopBar({
    super.key,
    required this.onAvatarTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/7.x/notionists/png?seed=Alex',
                ),
                backgroundColor: Color(0xFFFFF3E0),
              ),
            ),
          ),
          GlassContainer(
            borderRadius: BorderRadius.circular(30),
            padding: const EdgeInsets.all(8),
            opacity: 0.3,
            onTap: onSearchTap,
            child: const Icon(Icons.search, color: Colors.black87, size: 24),
          ),
        ],
      ),
    );
  }
}

// 中部：每日谚语卡片
class ProverbCard extends StatelessWidget {
  final MalayProverb proverb;

  const ProverbCard({super.key, required this.proverb});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.6,
      borderRadius: BorderRadius.circular(32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Colors.black45,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            proverb.malay,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, width: 30, color: Colors.black12),
          const SizedBox(height: 12),
          Text(
            proverb.english,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// 核心功能：Learn 和 Review 按钮
class StudyActionArea extends StatelessWidget {
  final UserStats stats;
  final Function(String) onAction;

  const StudyActionArea({
    super.key,
    required this.stats,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StudyCard(
            title: "Learn",
            count: stats.newWordsCount,
            subtitle: "New words",
            icon: Icons.school_outlined,
            colorAccent: Colors.teal.shade800,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LearningSessionPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StudyCard(
            title: "Review",
            count: stats.reviewWordsCount,
            subtitle: "To review",
            icon: Icons.loop_rounded,
            colorAccent: Colors.orange.shade800,
            onTap: () => onAction('review'),
          ),
        ),
      ],
    );
  }
}

class _StudyCard extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color colorAccent;
  final VoidCallback onTap;

  const _StudyCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.colorAccent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      opacity: 0.75,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(icon, size: 20, color: colorAccent.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: colorAccent,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 底部导航 Dock：词书，AI，进度
class BottomDock extends StatelessWidget {
  final Function(String) onNavTap;

  const BottomDock({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.85,
      blur: 20,
      borderRadius: BorderRadius.circular(40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DockItem(
            icon: Icons.menu_book_rounded,
            label: "Vocab",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularyBookPage(),
                ),
              );
            },
          ),
          // AI 按钮稍微大一点，突出显示
          _DockItem(
            icon: Icons.auto_awesome,
            label: "AI Chat",
            isHighlight: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIAssistantPage(),
                ),
              );
            },
          ),
          _DockItem(
            icon: Icons.bar_chart_rounded,
            label: "Progress",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    this.isHighlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isHighlight ? 12 : 8),
            decoration: BoxDecoration(
              color: isHighlight ? Colors.black87 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isHighlight ? Colors.white : Colors.black54,
              size: isHighlight ? 24 : 24,
            ),
          ),
          if (!isHighlight) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 6. MAIN PAGE LAYOUT
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DailyContent _content = AppRepository.getTodayContent();
  final UserStats _stats = AppRepository.getUserStats();

  void _navTo(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text("$title Page Content")),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<ThemeProvider>().currentBackgroundUrl;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 背景层
          Image.network(
            bgUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade300),
          ),
          // 遮罩层：确保底部文字可读
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          // 2. 内容层
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 顶部：头像 & 搜索
                  TopBar(
                    onAvatarTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    onSearchTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // 中部：谚语
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProverbCard(proverb: _content.proverb),
                  ),

                  const Spacer(flex: 3),

                  // 中下部：学习入口 (Learn & Review)
                  // 按照原图风格，放在底部Dock上方
                  StudyActionArea(
                    stats: _stats,
                    onAction: (type) => _navTo(
                      type == 'learn' ? "New Session" : "Review Session",
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 底部：功能 Dock (词书，AI，进度)
                  BottomDock(
                    onNavTap: (type) {
                      switch (type) {
                        case 'vocab':
                          _navTo("Vocabulary");
                          break;
                        case 'ai':
                          _navTo("AI Assistant");
                          break;
                        case 'progress':
                          _navTo("Statistics");
                          break;
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

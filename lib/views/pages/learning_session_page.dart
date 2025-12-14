import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // 需要添加 collection 依赖用于 shuffle
import 'package:malay/data/firebase_helper.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:malay/views/widgets/word_detail_content.dart';
import 'package:provider/provider.dart';
import '../../data/word_model.dart';
import '../../data/database_helper.dart';
import '../../data/tts_helper.dart'; // 引用我们之前封装的 TTS
// 引入你的 WordDetailContent 组件 (单词详情视图)
// import 'word_detail_content.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<StudyItem> _studyQueue = [];
  bool _isLoading = true;
  StudyItem? _currentItem;
  // 界面状态控制
  bool _showResult = false; // 是否正在展示结果/详情
  bool _isAnswerCorrect = false; // 上一次回答是否正确
  Word? _selectedOption;
  bool _isSpellingChecked = false;

  // 拼写相关
  TextEditingController _spellingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  // 初始化学习组
  Future<void> _initSession() async {
    setState(() => _isLoading = true);

    List<StudyItem> items = [];

    // A. 尝试从数据库加载“上次没学完的”
    final cachedData = await DatabaseHelper().getCachedSession();

    if (cachedData.isNotEmpty) {
      print("发现未完成的学习会话，正在恢复...");

      // 1. 提取所有单词 ID
      List<String> wordIds = cachedData
          .map((e) => e['word_id'] as String)
          .toList();

      // 2. 查出这些单词的完整信息
      List<Word> words = await DatabaseHelper().getWordsByIds(wordIds);

      // 3. 重组 StudyItem 队列
      for (var row in cachedData) {
        String id = row['word_id'];
        int stageIndex = row['stage'];
        bool isError = row['is_error'] == 1;

        // 找到对应的 Word 对象
        Word? word = words.firstWhereOrNull((w) => w.id == id);
        if (word != null) {
          // 重新生成混淆项 (混淆项随机生成即可，不需要严格存库)
          List<Word> distractors = await DatabaseHelper().getRandomDistractors(
            3,
            word.id,
          );

          items.add(
            StudyItem(
              word: word,
              distractors: distractors,
              // 恢复进度
              stage: StudyStage.values[stageIndex],
              // 如果之前错过，这里可以标记 (需要 StudyItem 支持记录 isError，或者简单恢复 stage 即可)
            ),
          );
        }
      }
    } else {
      // B. 如果没有缓存，说明是新的一组，执行之前的逻辑
      print("开启新的学习会话");
      List<Word> words = await DatabaseHelper().getPrioritizedStudyGroup(
        'Basic',
        10,
      );

      // [关键] 立即把这组新词存入缓存表
      await DatabaseHelper().initSessionCache(words);

      for (var word in words) {
        List<Word> distractors = await DatabaseHelper().getRandomDistractors(
          3,
          word.id,
        );
        items.add(StudyItem(word: word, distractors: distractors));
      }
    }

    if (mounted) {
      setState(() {
        _studyQueue = items;
        _isLoading = false;
        if (_studyQueue.isNotEmpty) {
          _nextWord();
        } else {
          _showSessionComplete(); // 极少情况：缓存里是空的但查出来了
        }
      });
    }
  }

  // 核心调度逻辑：获取下一个任务
  void _nextWord() {
    // 过滤出未完成的
    var pending = _studyQueue.where((i) => i.stage != StudyStage.done).toList();

    if (pending.isEmpty) {
      // 全部学完，弹出结算页面
      _showSessionComplete();
      return;
    }

    // 简单的轮询策略：取第一个。
    // 如果你想让同一个词连续学完4关，就一直用同一个。
    // 如果想穿插学习（推荐），就每次 shuffle 或者取下一个。
    // 这里使用：如果上一个还没做完且答对了，继续它的下一关（趁热打铁）；否则换一个词。

    setState(() {
      _showResult = false;
      _isAnswerCorrect = false;
      _selectedOption = null;
      _isSpellingChecked = false;
      _spellingController.clear();
      // 如果当前词还存在且没学完，优先继续学它 (符合图片逻辑 "下一词" 可能指同一个词的新阶段)
      // 但通常背单词软件会穿插。这里按你的需求：
      // "前一个学习完成才会出现下一种" -> 这意味着必须通关。
      // 我们从 pending 里找一个即可。
      _currentItem = pending.first;

      // 如果是听力题，自动播放发音
      if (_currentItem!.stage == StudyStage.audioSelection ||
          _currentItem!.stage == StudyStage.recall) {
        TtsHelper().speak(_currentItem!.word.word);
      }
    });
  }

  void _handleOptionSelected(Word selected) {
    // 如果已经选过（主要是针对答错后的状态），禁止再次点击其他选项
    if (_selectedOption != null) return;

    setState(() {
      _selectedOption = selected;
    });

    bool isCorrect = selected.id == _currentItem!.word.id;

    if (isCorrect) {
      // 情况 A: 选对了 -> 直接进入详情页 (原有逻辑)
      _handleResult(true);
    } else {
      // 情况 B: 选错了 -> 仅仅更新 UI (变红变绿)，暂停跳转
      // 此时界面会重绘，根据 _selectedOption 显示颜色
      // 等待用户点击底部的“继续”按钮来调用 _handleResult(false)

      // 可选：答错时播放一个错误音效或震动
    }
  }

  void _handleRecall(bool known) {
    // 认识 -> 正确， 不认识 -> 错误
    _handleResult(known);
  }

  void _handleSpellingCheck() {
    String input = _spellingController.text.trim().toLowerCase();
    String target = _currentItem!.word.word.toLowerCase();
    bool correct = input == target;
    // 拼写题如果错了，通常不立即跳转，而是显示红绿字母。这里为了简化逻辑，统一处理。
    // 你的需求是：拼写错误 -> 标红标绿 -> 继续 -> 详情 -> 下一词
    _handleResult(correct);
  }

  // 统一处理结果
  void _handleResult(bool correct) {
    setState(() {
      _isAnswerCorrect = correct;
      _showResult = true; // 切换到详情/结果模式
    });

    if (correct) {
      // 只有在显示结果界面点击“下一词”时才真正 promote，但为了逻辑简单，这里预处理
      // 实际 promote 在点击 next 按钮时触发
      TtsHelper().speak(_currentItem!.word.word); // 答对了读一遍
    } else {
      // 答错了，进度清零
      _currentItem!.reset();
      DatabaseHelper().updateSessionProgress(_currentItem!.word.id, 0, true);
      // 重新生成一下混淆项，防止下次记住位置
      // (可选优化) _refreshDistractors(_currentItem!);
    }
  }

  // 点击“下一词”按钮
  void _onNextPressed() async {
    if (_isAnswerCorrect) {
      _currentItem!.promote();
      if (_currentItem!.stage == StudyStage.done) {
        // 记录到数据库：今日完成 +1
        await DatabaseHelper().updateWordProgress(_currentItem!.word.id, true);
        await DatabaseHelper().removeSessionItem(_currentItem!.word.id);
      } else {
        // 把这个词移到队列末尾，产生间隔效果 (Spaced Repetition inside session)
        _studyQueue.remove(_currentItem!);
        _studyQueue.add(_currentItem!);
        await DatabaseHelper().updateSessionProgress(
          _currentItem!.word.id,
          _currentItem!.stage.index,
          false, // 没错
        );
      }
    } else {
      await DatabaseHelper().updateWordProgress(_currentItem!.word.id, false);
      await DatabaseHelper().updateSessionProgress(
        _currentItem!.word.id,
        0, // 重置回第 0 关
        true, // 标记错过
      );
      // 答错了，已经 reset 过了，移到末尾稍后重试
      _studyQueue.remove(_currentItem!);
      _studyQueue.add(_currentItem!);
    }

    _nextWord();
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("今日任务完成！"),
        content: const Text("你已经完成了本组 10 个单词的学习。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // 返回主页
            child: const Text("太棒了"),
          ),
        ],
      ),
    );
  }

  // [新增] 退出页面的处理逻辑
  Future<bool> _onWillPop() async {
    try {
      // 触发云端同步
      await FirebaseHelper().syncProgressToCloud();
    } catch (e) {
      print("同步失败: $e");
      // 可以选择提示用户，或者默默失败下次再传
    }

    // 允许退出
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<ThemeProvider>().currentBackgroundUrl;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentItem == null) return const Scaffold();

    return PopScope(
      canPop: false, // 禁止直接退出，必须走 onPopInvoked
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 执行同步逻辑
        bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(child: Image.network(bgUrl, fit: BoxFit.cover)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent, // 关键：Scaffold 透明
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Text(
                "Study (${_studyQueue.where((i) => i.stage == StudyStage.done).length}/10)",
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () async {
                  bool shouldPop = await _onWillPop();
                  if (shouldPop && context.mounted) Navigator.of(context).pop();
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value:
                      _studyQueue
                          .where((i) => i.stage == StudyStage.done)
                          .length /
                      10.0,
                  backgroundColor: Colors.black12, // 轨道颜色淡一点
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.teal,
                  ), // 进度条颜色
                  minHeight: 4, // 稍微粗一点点更现代
                ),
              ),
            ),
            body: SafeArea(
              // 必须加 SafeArea，否则内容会跑进状态栏和 AppBar 里面
              // 只要顶部不要被挡住，bottom 可以设为 false 让背景延伸到底部
              top: true,
              bottom: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 背景层 (保持 App 统一调性)
                  Image.network(bgUrl, fit: BoxFit.cover),
                  // 叠加层：使背景变淡，让前台内容清晰
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // 顶部进度点 (表示当前单词的 4 个阶段)
                            _buildStageIndicators(),

                            Expanded(
                              child: _showResult
                                  ? _buildResultView() // 结果/详情页
                                  : _buildQuestionView(), // 题目页
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 顶部 4 个小进度条/点
  Widget _buildStageIndicators() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          bool active = index < _currentItem!.progress;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: active ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  // 构建问题视图 (根据当前阶段)
  Widget _buildQuestionView() {
    switch (_currentItem!.stage) {
      case StudyStage.definitionSelection:
        return _buildSelectionMode(hideWord: false, hideAudio: false);
      case StudyStage.recall:
        return _buildRecallMode();
      case StudyStage.audioSelection:
        return _buildSelectionMode(hideWord: true, hideAudio: false); // 模糊单词
      case StudyStage.spelling:
        return _buildSpellingMode();
      default:
        return const SizedBox();
    }
  }

  // 构建结果/详情视图 (复用单词详情组件)
  Widget _buildResultView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            // 增加一点内边距，防止内容贴边
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            // 这里直接放你的复用组件
            child: WordDetailContent(word: _currentItem!.word),
          ),
        ),

        // 底部控制栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isAnswerCorrect &&
                    _currentItem!.stage == StudyStage.recall)
                  // 如果是“记错了”，显示这个
                  const Text(
                    "Keep going! Progress reset.",
                    style: TextStyle(color: Colors.orange),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswerCorrect
                          ? Colors.green
                          : Colors.blue,
                    ),
                    child: const Text(
                      "下一词 / Next Word",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 模式 1 & 3: 选择题 (图一 & 图三) ---
  Widget _buildSelectionMode({
    required bool hideWord,
    required bool hideAudio,
  }) {
    List<Word> options = [..._currentItem!.distractors, _currentItem!.word];
    // 当前正确答案的 ID
    final String correctId = _currentItem!.word.id;
    // 是否已经做出了选择（且选错了，因为选对直接跳走了）
    final bool hasSelectedWrong =
        _selectedOption != null && _selectedOption!.id != correctId;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          if (hideWord)
            // 图三：模糊单词
            Text(
              _currentItem!.word.word.replaceAll(RegExp(r'[a-zA-Z]'), '*'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            )
          else
            Text(
              _currentItem!.word.word,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => TtsHelper().speak(_currentItem!.word.word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up, size: 18),
                  const SizedBox(width: 8),
                  Text("/${_currentItem!.word.phonetic}/"),
                ],
              ),
            ),
          ),

          const Spacer(),
          ...options.map((option) {
            Color borderColor = Colors.grey.shade300;
            Color bgColor = Colors.transparent;
            Color textColor = Colors.black87;

            if (hasSelectedWrong) {
              if (option.id == correctId) {
                // 1. 正确答案：始终变绿
                borderColor = Colors.green;
                bgColor = Colors.green.shade50;
                textColor = Colors.green.shade800;
              } else if (option.id == _selectedOption!.id) {
                // 2. 用户选的错误项：变红
                borderColor = Colors.red;
                bgColor = Colors.red.shade50;
                textColor = Colors.red.shade800;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: bgColor, // 动态背景
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: borderColor,
                      width:
                          hasSelectedWrong &&
                              (option.id == correctId ||
                                  option.id == _selectedOption!.id)
                          ? 2
                          : 1,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  // 如果已经选错了，就禁用点击，防止乱点
                  onPressed: hasSelectedWrong
                      ? null
                      : () => _handleOptionSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.chinese,
                            style: TextStyle(
                              color: textColor, // 动态文字颜色
                              fontSize: 16,
                              fontWeight:
                                  hasSelectedWrong &&
                                      (option.id == correctId ||
                                          option.id == _selectedOption!.id)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 可选：添加对错图标
                        if (hasSelectedWrong && option.id == correctId)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (hasSelectedWrong &&
                            option.id == _selectedOption!.id)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // “看答案”按钮
          const SizedBox(height: 10),
          if (hasSelectedWrong)
            // 状态 B: 选错了，显示“继续”按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handleResult(false), // 点击继续，进入详情页（算作错误）
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "继续",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            )
          else
            // 状态 A: 还没选，显示“看答案” (相当于放弃)
            TextButton(
              onPressed: () => _handleResult(false),
              child: const Text("看答案", style: TextStyle(color: Colors.grey)),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- 模式 2: 回想 (图二) ---
  Widget _buildRecallMode() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            _currentItem!.word.word,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => TtsHelper().speak(_currentItem!.word.word),
                child: const Icon(Icons.volume_up_rounded),
              ),
              const SizedBox(width: 10),
              Text(
                "/${_currentItem!.word.phonetic}/",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // 模糊块
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 40),
          // 例句 (挖空单词)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Dogs _______ from wolves.", // 这里应该动态生成挖空例句
              style: TextStyle(fontSize: 18),
            ),
          ),

          const Spacer(),

          // 底部两个大按钮
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _handleRecall(false), // 不认识
                    child: const Text(
                      "不认识",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _handleRecall(true), // 认识
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text(
                      "认识",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 模式 4: 拼写 (图四) ---
  Widget _buildSpellingMode() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("拼写练习", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          // --- 核心区域：输入框 vs 结果展示 ---
          if (!_isSpellingChecked)
            // 状态 A: 用户正在输入
            TextField(
              controller: _spellingController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Type here...",
                hintStyle: TextStyle(color: Colors.black12),
              ),
              // 按回车键直接触发检查
              onSubmitted: (_) => _performSpellingCheck(),
            )
          else
            // 状态 B: 结果展示 (显示红绿色的文字)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                children: _buildColoredSpelling(_spellingController.text),
              ),
            ),

          const SizedBox(height: 10),

          // --- 新增：发音按钮 ---
          GestureDetector(
            onTap: () => TtsHelper().speak(_currentItem!.word.word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up, size: 18),
                  const SizedBox(width: 8),
                  Text("/${_currentItem!.word.phonetic}/"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
          // 提示 (中文释义)
          Text(
            _currentItem!.word.chinese,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const Spacer(),

          // --- 底部按钮 ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              // 如果没检查，点击执行检查；如果已检查，点击继续进入详情页
              onPressed: _isSpellingChecked
                  ? () =>
                        _handleResult(_isAnswerCorrect) // 传递之前计算好的结果
                  : _performSpellingCheck,
              style: ElevatedButton.styleFrom(
                // 检查后根据对错显示 绿/红，未检查显示 蓝
                backgroundColor: _isSpellingChecked
                    ? (_isAnswerCorrect ? Colors.green : Colors.red)
                    : Colors.blue,
              ),
              child: Text(
                _isSpellingChecked ? "继续 / Continue" : "确定 / Done",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [新增] 执行拼写检查 (更新 UI，暂不跳转)
  void _performSpellingCheck() {
    if (_spellingController.text.isEmpty) return;

    String input = _spellingController.text.trim().toLowerCase();
    String target = _currentItem!.word.word.toLowerCase();
    bool correct = input == target;

    setState(() {
      _isSpellingChecked = true;
      _isAnswerCorrect = correct; // 临时保存结果，供 _handleResult 使用
    });

    // 如果拼对了，自动读一遍
    if (correct) {
      TtsHelper().speak(_currentItem!.word.word);
    }
  }

  // [新增] 构建彩色文字的逻辑
  List<TextSpan> _buildColoredSpelling(String input) {
    List<TextSpan> spans = [];
    String target = _currentItem!.word.word.toLowerCase();
    String userInput = input.toLowerCase();

    for (int i = 0; i < input.length; i++) {
      Color color = Colors.red; // 默认红色

      // 如果下标在目标长度内，且字符一致，则标绿
      if (i < target.length && userInput[i] == target[i]) {
        color = Colors.green;
      }

      spans.add(
        TextSpan(
          text: input[i], // 显示用户输入的原始字符（保留大小写）
          style: TextStyle(color: color),
        ),
      );
    }
    return spans;
  }
}

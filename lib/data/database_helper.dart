import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; // 用于读取 assets
import 'package:malay/data/word_model.dart';
import 'package:path/path.dart'; // 用于处理路径 join
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // 单例模式：确保全局只有一个数据库连接
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    // 1. 获取手机内部存储的数据库路径
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "malay_learning.db");

    // 2. 检查文件是否已经存在
    var exists = await databaseExists(path);

    if (!exists) {
      // 3. 如果不存在（说明是第一次安装），从 Assets 复制过去
      print("正在从 Assets 复制数据库...");

      try {
        // 创建目录（防止父目录不存在）
        await Directory(dirname(path)).create(recursive: true);

        // 读取 Assets 中的原始数据
        ByteData data = await rootBundle.load(
          join("assets", "malay_learning.db"),
        );
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // 写入到手机文件系统
        await File(path).writeAsBytes(bytes, flush: true);
        print("数据库复制完成！");
      } catch (e) {
        print("数据库复制失败: $e");
      }
    } else {
      print("数据库已存在，直接打开。");
    }

    // 4. 打开数据库 (readOnly: true 可以保护数据不被意外修改)
    return await openDatabase(path, readOnly: false, version: 3);
  }

  // --- 查询功能 ---

  /// 通用查询函数
  /// [keyword]: 搜索关键词 (比如 "ma")
  /// [type]: 词性筛选 (比如 "verb", 可选)
  /// [limit]: 限制返回数量 (防止一次查出几万条卡死)
  Future<List<Map<String, dynamic>>> searchWords({
    String? keyword,
    String? type,
    int limit = 50,
  }) async {
    final db = await database;

    // 1. 构建基本的 SQL 语句
    // 1=1 是个小技巧，方便后面通过 AND 拼接条件
    String sql = "SELECT * FROM words WHERE 1=1";
    List<dynamic> args = [];

    // 2. 动态拼接条件

    // 如果有关键词 (模糊查询)
    if (keyword != null && keyword.isNotEmpty) {
      sql += " AND word LIKE ?";
      args.add("$keyword%"); // 'ma%' 表示匹配以 ma 开头的单词
      // 如果想搜包含，用 "%$keyword%"，但效率会变低
    }

    // 如果有词性筛选
    if (type != null && type.isNotEmpty && type != "全部") {
      sql += " AND type = ?";
      args.add(type);
    }

    // 3. 添加排序和限制
    // 按照单词长度排序（通常用户想找短的匹配词），再按字母序
    sql += " ORDER BY length(word) ASC, word ASC LIMIT ?";
    args.add(limit);

    // 4. 执行查询
    final List<Map<String, dynamic>> result = await db.rawQuery(sql, args);
    return result;
  }

  // 获取某个单词的详细信息
  Future<Word?> getWordDetail(String exactWord) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      "words",
      where: "malay_word = ?",
      whereArgs: [exactWord],
      limit: 1,
    );

    // 1. 创建一个可修改的副本 (Map 从数据库读出来通常是只读的)
    final mutableMap = Map<String, dynamic>.from(maps[0]);

    // 2. 处理 JSON 字段：SQLite 取出来是 String，需要解码
    // 如果 sentences 字段存在且是字符串，尝试解码
    if (mutableMap['sentences'] != null && mutableMap['sentences'] is String) {
      try {
        mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
      } catch (e) {
        print('Error decoding sentences: $e');
        mutableMap['sentences'] = [];
      }
    }

    // 如果 collocations 字段存在且是字符串，尝试解码
    if (mutableMap['collocations'] != null &&
        mutableMap['collocations'] is String) {
      try {
        mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
      } catch (e) {
        print('Error decoding collocations: $e');
        mutableMap['collocations'] = [];
      }
    }

    // 3. ⚠️ 字段名兼容处理 (非常重要)
    // 你的 Word.fromJson 找的是 'malay_word'，但数据库字段可能是 'word'
    // 这里做一个手动映射，防止数据取不到
    if (!mutableMap.containsKey('malay_word') &&
        mutableMap.containsKey('word')) {
      mutableMap['malay_word'] = mutableMap['word'];
    }
    if (!mutableMap.containsKey('english_meaning') &&
        mutableMap.containsKey('meaning')) {
      // 假设数据库里的 meaning 对应 english_meaning，或者是结构体
      // 如果 meaning 也是 JSON 字符串，记得像上面一样 decode
      // mutableMap['english_meaning'] = mutableMap['meaning'];
    }

    // 4. 转换为 Word 对象
    return Word.fromJson(mutableMap);
    // return results.isNotEmpty ? results.first : null;
  }

  // 获取所有词书（其实就是按 category 分组统计）
  Future<List<Map<String, dynamic>>> getBooksFromDB() async {
    final db = await database;

    // 假设你的表有 category 字段。
    // 这句 SQL 的意思是：找出所有不同的分类，并计算每个分类下有多少个单词
    // 结果类似：[{category: 'Food', count: 12}, {category: 'Travel', count: 5}]
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM words 
      GROUP BY category
    ''');

    return maps;
  }

  // --- 将此方法添加到 DatabaseHelper 类中 ---

  /// 根据 Category 获取单词列表，并转换为 List<Word>
  Future<List<Word>> getWordsByCategory(String category) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'category = ?',
      whereArgs: [category],
    );

    return maps.map((map) {
      // 1. 创建一个可修改的副本 (Map 从数据库读出来通常是只读的)
      final mutableMap = Map<String, dynamic>.from(map);

      // 2. 处理 JSON 字段：SQLite 取出来是 String，需要解码
      // 如果 sentences 字段存在且是字符串，尝试解码
      if (mutableMap['sentences'] != null &&
          mutableMap['sentences'] is String) {
        try {
          mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
        } catch (e) {
          print('Error decoding sentences: $e');
          mutableMap['sentences'] = [];
        }
      }

      // 如果 collocations 字段存在且是字符串，尝试解码
      if (mutableMap['collocations'] != null &&
          mutableMap['collocations'] is String) {
        try {
          mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
        } catch (e) {
          print('Error decoding collocations: $e');
          mutableMap['collocations'] = [];
        }
      }

      // 3. ⚠️ 字段名兼容处理 (非常重要)
      // 你的 Word.fromJson 找的是 'malay_word'，但数据库字段可能是 'word'
      // 这里做一个手动映射，防止数据取不到
      if (!mutableMap.containsKey('malay_word') &&
          mutableMap.containsKey('word')) {
        mutableMap['malay_word'] = mutableMap['word'];
      }
      if (!mutableMap.containsKey('english_meaning') &&
          mutableMap.containsKey('meaning')) {
        // 假设数据库里的 meaning 对应 english_meaning，或者是结构体
        // 如果 meaning 也是 JSON 字符串，记得像上面一样 decode
        // mutableMap['english_meaning'] = mutableMap['meaning'];
      }

      // 4. 转换为 Word 对象
      return Word.fromJson(mutableMap);
    }).toList();
  }

  // 根据一组 ID 获取单词详情 (用于配合 Firebase)
  Future<List<Word>> getWordsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await database;

    // 动态构建问号占位符: "?, ?, ?, ?"
    String placeholders = List.filled(ids.length, '?').join(',');

    // 查询这些 ID 对应的所有单词
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id IN ($placeholders)', // 使用 IN 语法
      whereArgs: ids,
    );

    // 注意：SQLite 返回的顺序可能和 ids 列表顺序不一致
    // 如果需要严格按收藏时间排序，需要在内存里重新排一下，或者用更复杂的 SQL

    // ... 这里接你之前的 maps.map 转换逻辑 ...
    return maps.map((map) {
      // 1. 创建一个可修改的副本 (Map 从数据库读出来通常是只读的)
      final mutableMap = Map<String, dynamic>.from(map);

      // 2. 处理 JSON 字段：SQLite 取出来是 String，需要解码
      // 如果 sentences 字段存在且是字符串，尝试解码
      if (mutableMap['sentences'] != null &&
          mutableMap['sentences'] is String) {
        try {
          mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
        } catch (e) {
          print('Error decoding sentences: $e');
          mutableMap['sentences'] = [];
        }
      }

      // 如果 collocations 字段存在且是字符串，尝试解码
      if (mutableMap['collocations'] != null &&
          mutableMap['collocations'] is String) {
        try {
          mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
        } catch (e) {
          print('Error decoding collocations: $e');
          mutableMap['collocations'] = [];
        }
      }

      // 3. ⚠️ 字段名兼容处理 (非常重要)
      // 你的 Word.fromJson 找的是 'malay_word'，但数据库字段可能是 'word'
      // 这里做一个手动映射，防止数据取不到
      if (!mutableMap.containsKey('malay_word') &&
          mutableMap.containsKey('word')) {
        mutableMap['malay_word'] = mutableMap['word'];
      }
      if (!mutableMap.containsKey('english_meaning') &&
          mutableMap.containsKey('meaning')) {
        // 假设数据库里的 meaning 对应 english_meaning，或者是结构体
        // 如果 meaning 也是 JSON 字符串，记得像上面一样 decode
        // mutableMap['english_meaning'] = mutableMap['meaning'];
      }

      // 4. 转换为 Word 对象
      return Word.fromJson(mutableMap);
    }).toList();
  }

  // --- 多语言搜索功能 ---
  Future<List<Word>> searchByKeyword(String query) async {
    final db = await database;

    // 使用 OR 逻辑同时查询三个字段
    // %query% 表示模糊匹配（包含即可，不用完全相等）
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM words 
      WHERE malay_word LIKE ? 
      OR english_meaning LIKE ? 
      OR chinese_meaning LIKE ?
      LIMIT 50
    ''',
      ['%$query%', '%$query%', '%$query%'],
    );

    // 将数据库结果转换为 Word 对象列表
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);

      // 处理 JSON 字符串解码 (为了防止解析错误，加上 try-catch)
      if (mutableMap['sentences'] != null &&
          mutableMap['sentences'] is String) {
        try {
          mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
        } catch (e) {
          mutableMap['sentences'] = [];
        }
      }
      if (mutableMap['collocations'] != null &&
          mutableMap['collocations'] is String) {
        try {
          mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
        } catch (e) {
          mutableMap['collocations'] = [];
        }
      }
      // 兼容旧字段名
      if (!mutableMap.containsKey('malay_word') &&
          mutableMap.containsKey('word')) {
        mutableMap['malay_word'] = mutableMap['word'];
      }

      return Word.fromJson(mutableMap);
    }).toList();
  }

  // 修改 database_helper.dart

  // 1. 获取用于混淆的随机单词 (排除正确答案)
  Future<List<Word>> getRandomDistractors(
    int count,
    String correctWordId,
  ) async {
    final db = await database;
    // 随机取 count 个不等于 correctWordId 的词
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM words WHERE id != ? ORDER BY RANDOM() LIMIT ?',
      [correctWordId, count],
    );
    return maps.map((e) => Word.fromJson(e)).toList(); // 假设你有 fromJson
  }

  // 2. [核心逻辑] 获取今日学习列表 (优先级算法)
  // 优先级：没学完的(正在复习队列且时间到了) > 新词 (随机)
  Future<List<Word>> getPrioritizedStudyGroup(
    String category,
    int limit,
  ) async {
    final db = await database;
    int now = DateTime.now().millisecondsSinceEpoch;

    List<Word> studyList = [];

    // A. 先获取 "该复习了" 或者 "学了一半" 的词
    // 条件：在 stats 表中，且 next_review_at 小于等于现在
    final List<Map<String, dynamic>> dueWordsMaps = await db.rawQuery(
      '''
    SELECT w.*, s.status, s.streak 
    FROM words w
    INNER JOIN user_word_stats s ON w.id = s.word_id
    WHERE s.next_review_at <= ? AND w.category = ?
    ORDER BY s.next_review_at ASC
    LIMIT ?
  ''',
      [now, category, limit],
    );

    studyList.addAll(dueWordsMaps.map((e) => Word.fromJson(e)));

    // B. 如果数量不够 10 个，从新词里随机补齐
    if (studyList.length < limit) {
      int remaining = limit - studyList.length;

      // 查出不在 stats 表里的词 (即从未学过的词)
      final List<Map<String, dynamic>> newWordsMaps = await db.rawQuery(
        '''
      SELECT * FROM words 
      WHERE id NOT IN (SELECT word_id FROM user_word_stats) AND category = ?
      ORDER BY RANDOM() 
      LIMIT ?
    ''',
        [category, remaining],
      );

      studyList.addAll(newWordsMaps.map((e) => Word.fromJson(e)));
    }

    return studyList;
  }

  // 3. [核心逻辑] 更新单个单词的学习进度 (艾宾浩斯简化版算法)
  Future<void> updateWordProgress(String wordId, bool isCorrect) async {
    final db = await database;
    int now = DateTime.now().millisecondsSinceEpoch;

    // 先查一下现在的状态
    final List<Map<String, dynamic>> stats = await db.query(
      'user_word_stats',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    int streak = 0;
    int status = 0;

    if (stats.isNotEmpty) {
      streak = stats.first['streak'] as int;
      status = stats.first['status'] as int;
    }

    int nextReview = 0;

    if (isCorrect) {
      // 答对了：增加 streak，延长复习间隔
      streak++;
      status = 1; // 标记为学习中

      // 间隔算法 (单位：天)
      // streak 1 -> 1天后
      // streak 2 -> 2天后
      // streak 3 -> 4天后
      // streak 4 -> 7天后 (已掌握)
      int daysToAdd = 1;
      if (streak == 1)
        daysToAdd = 1;
      else if (streak == 2)
        daysToAdd = 2;
      else if (streak == 3)
        daysToAdd = 4;
      else {
        daysToAdd = 7;
        status = 2; // 认为已掌握
      }

      nextReview = now + (daysToAdd * 24 * 60 * 60 * 1000);
    } else {
      // 答错了：重置 streak，马上复习 (比如 5 分钟后或明天)
      streak = 0;
      status = 1;
      nextReview = now; // 设为现在，意味着下次获取列表立刻出现
    }

    // 使用 INSERT OR REPLACE 自动处理新增或更新
    await db.rawInsert(
      '''
    INSERT OR REPLACE INTO user_word_stats (word_id, status, next_review_at, last_studied_at, streak)
    VALUES (?, ?, ?, ?, ?)
  ''',
      [wordId, status, nextReview, now, streak],
    );
  }

  // 4. 获取所有待同步的数据 (用于 Firestore)
  Future<List<Map<String, dynamic>>> getAllStats() async {
    final db = await database;
    return await db.query('user_word_stats');
  }

  // --- 新增：会话缓存相关方法 ---

  // 1. 初始化缓存：当开启新的一组学习时，把这 10 个词存入缓存
  Future<void> initSessionCache(List<Word> words) async {
    final db = await database;
    final batch = db.batch();

    // 先清空旧的（防止意外残留）
    batch.delete('study_session_cache');

    // 插入新的
    int now = DateTime.now().millisecondsSinceEpoch;
    for (var word in words) {
      batch.insert('study_session_cache', {
        'word_id': word.id,
        'stage': 0, // 默认从第0关开始
        'is_error': 0,
        'created_at': now,
      });
    }
    await batch.commit();
  }

  // 2. 更新单个单词进度：每过一关调用一次
  Future<void> updateSessionProgress(
    String wordId,
    int stage,
    bool isError,
  ) async {
    final db = await database;
    await db.update(
      'study_session_cache',
      {'stage': stage, 'is_error': isError ? 1 : 0},
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  // 3. 移除缓存：当一个单词彻底学完 (Done) 时调用
  Future<void> removeSessionItem(String wordId) async {
    final db = await database;
    await db.delete(
      'study_session_cache',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  // 4. 检查是否有未完成的会话 (用于恢复)
  Future<List<Map<String, dynamic>>> getCachedSession() async {
    final db = await database;
    return await db.query('study_session_cache', orderBy: 'created_at ASC');
  }
}

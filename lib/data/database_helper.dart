import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:malay/data/word_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
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
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "malay_learning.db");
    var exists = await databaseExists(path);

    if (!exists) {
      print("正在从 Assets 复制数据库...");

      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(
          join("assets", "malay_learning.db"),
        );
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print("数据库复制完成！");
      } catch (e) {
        print("数据库复制失败: $e");
      }
    } else {
      print("数据库已存在，直接打开。");
    }
    return await openDatabase(path, readOnly: false, version: 3);
  }

  // --- 查询功能 ---
  Future<List<Map<String, dynamic>>> searchWords({
    String? keyword,
    String? type,
    int limit = 50,
  }) async {
    final db = await database;

    String sql = "SELECT * FROM words WHERE 1=1";
    List<dynamic> args = [];

    if (keyword != null && keyword.isNotEmpty) {
      sql += " AND word LIKE ?";
      args.add("$keyword%");
    }

    if (type != null && type.isNotEmpty && type != "全部") {
      sql += " AND type = ?";
      args.add(type);
    }
    sql += " ORDER BY length(word) ASC, word ASC LIMIT ?";
    args.add(limit);

    final List<Map<String, dynamic>> result = await db.rawQuery(sql, args);
    return result;
  }

  // 获取某个单词的详细信息
  Future<Word?> getWordDetail(String exactWord) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      "words",
      where: "malay_word = ? COLLATE NOCASE",
      whereArgs: [exactWord],
      limit: 1,
    );

    final mutableMap = Map<String, dynamic>.from(maps[0]);

    if (mutableMap['sentences'] != null && mutableMap['sentences'] is String) {
      try {
        mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
      } catch (e) {
        print('Error decoding sentences: $e');
        mutableMap['sentences'] = [];
      }
    }

    if (mutableMap['collocations'] != null &&
        mutableMap['collocations'] is String) {
      try {
        mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
      } catch (e) {
        print('Error decoding collocations: $e');
        mutableMap['collocations'] = [];
      }
    }

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

    return Word.fromJson(mutableMap);
  }

  // 获取所有词书（其实就是按 category 分组统计）
  Future<List<Map<String, dynamic>>> getBooksFromDB() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM words 
      GROUP BY category
    ''');

    return maps;
  }

  /// 根据 Category 获取单词列表，并转换为 List<Word>
  Future<List<Word>> getWordsByCategory(String category) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'category = ?',
      whereArgs: [category],
    );

    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);

      if (mutableMap['sentences'] != null &&
          mutableMap['sentences'] is String) {
        try {
          mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
        } catch (e) {
          print('Error decoding sentences: $e');
          mutableMap['sentences'] = [];
        }
      }

      if (mutableMap['collocations'] != null &&
          mutableMap['collocations'] is String) {
        try {
          mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
        } catch (e) {
          print('Error decoding collocations: $e');
          mutableMap['collocations'] = [];
        }
      }

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

      return Word.fromJson(mutableMap);
    }).toList();
  }

  // 根据一组 ID 获取单词详情 (用于配合 Firebase)
  Future<List<Word>> getWordsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await database;

    String placeholders = List.filled(ids.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);

      if (mutableMap['sentences'] != null &&
          mutableMap['sentences'] is String) {
        try {
          mutableMap['sentences'] = jsonDecode(mutableMap['sentences']);
        } catch (e) {
          print('Error decoding sentences: $e');
          mutableMap['sentences'] = [];
        }
      }

      if (mutableMap['collocations'] != null &&
          mutableMap['collocations'] is String) {
        try {
          mutableMap['collocations'] = jsonDecode(mutableMap['collocations']);
        } catch (e) {
          print('Error decoding collocations: $e');
          mutableMap['collocations'] = [];
        }
      }
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

      return Word.fromJson(mutableMap);
    }).toList();
  }

  // --- 多语言搜索功能 ---
  Future<List<Word>> searchByKeyword(String query) async {
    final db = await database;

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

    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);

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
      if (!mutableMap.containsKey('malay_word') &&
          mutableMap.containsKey('word')) {
        mutableMap['malay_word'] = mutableMap['word'];
      }

      return Word.fromJson(mutableMap);
    }).toList();
  }

  // 1. 获取用于混淆的随机单词 (排除正确答案)
  Future<List<Word>> getRandomDistractors(
    int count,
    String correctWordId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM words WHERE id != ? ORDER BY RANDOM() LIMIT ?',
      [correctWordId, count],
    );
    return maps.map((e) => Word.fromJson(e)).toList();
  }

  // 获取今日学习列表 (优先级算法)
  // 优先级：没学完的(正在复习队列且时间到了) > 新词 (随机)
  Future<List<Word>> getPrioritizedStudyGroup(
    String category,
    int limit,
  ) async {
    final db = await database;
    int now = DateTime.now().millisecondsSinceEpoch;

    List<Word> studyList = [];

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

    if (studyList.length < limit) {
      int remaining = limit - studyList.length;

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

  // 更新单个单词的学习进度 (艾宾浩斯简化版算法)
  Future<void> updateWordProgress(String wordId, bool isCorrect) async {
    final db = await database;
    int now = DateTime.now().millisecondsSinceEpoch;

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
      streak++;
      status = 1;

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
        status = 2;
      }

      nextReview = now + (daysToAdd * 24 * 60 * 60 * 1000);
    } else {
      streak = 0;
      status = 1;
      nextReview = now;
    }

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

  // 当开启新的一组学习时，把这 10 个词存入缓存
  Future<void> initSessionCache(List<Word> words) async {
    final db = await database;
    final batch = db.batch();

    batch.delete('study_session_cache');

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

  // 移除缓存：当一个单词彻底学完 (Done) 时调用
  Future<void> removeSessionItem(String wordId) async {
    final db = await database;
    await db.delete(
      'study_session_cache',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  // 检查是否有未完成的会话 (用于恢复)
  Future<List<Map<String, dynamic>>> getCachedSession() async {
    final db = await database;
    return await db.query('study_session_cache', orderBy: 'created_at ASC');
  }
}

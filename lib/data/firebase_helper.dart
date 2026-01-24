import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:malay/data/database_helper.dart';

class FirebaseHelper {
  // 获取当前登录用户
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // 获取该用户的 favorites 集合引用
  CollectionReference? get _favoritesRef {
    final user = currentUser;
    if (user == null) return null; // 如果没登录，返回空
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  // 1. 添加收藏 (同步到云端)
  Future<void> addFavorite(String wordId) async {
    if (_favoritesRef == null) return;

    // 使用 wordId 作为文档 ID，防止重复
    await _favoritesRef!.doc(wordId).set({
      'wordId': wordId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. 移除收藏
  Future<void> removeFavorite(String wordId) async {
    if (_favoritesRef == null) return;
    await _favoritesRef!.doc(wordId).delete();
  }

  // 3. 检查是否已收藏 (单次检查)
  Future<bool> isFavorite(String wordId) async {
    if (_favoritesRef == null) return false;
    final doc = await _favoritesRef!.doc(wordId).get();
    return doc.exists;
  }

  // 4. 获取所有收藏的 ID 列表
  Future<List<String>> getFavoriteIds() async {
    if (_favoritesRef == null) return [];

    final snapshot = await _favoritesRef!
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> syncProgressToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. 从 SQLite 获取所有学习记录
    List<Map<String, dynamic>> localStats = await DatabaseHelper()
        .getAllStats();

    if (localStats.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final userStatsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('word_stats');

    // 2. 批量写入
    for (var stat in localStats) {
      var docRef = userStatsRef.doc(stat['word_id']);
      batch.set(docRef, {
        'status': stat['status'],
        'next_review_at': stat['next_review_at'],
        'last_studied_at': stat['last_studied_at'],
        'streak': stat['streak'],
        'synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    print("✅ 云端同步完成");
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      'addedAt': FieldValue.serverTimestamp(), // 使用服务器时间
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

  // 4. 获取所有收藏的 ID 列表 (关键步骤)
  Future<List<String>> getFavoriteIds() async {
    if (_favoritesRef == null) return [];

    final snapshot = await _favoritesRef!
        .orderBy('addedAt', descending: true)
        .get();

    // 把取出来的文档 ID 变成一个 List<String>
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}

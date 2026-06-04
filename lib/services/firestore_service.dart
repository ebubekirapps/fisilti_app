import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addPost(Post post) async {
    debugPrint("Firestore'a yazma basladi");

    await _db.collection('posts').doc(post.id).set({
      'id': post.id,
      'content': post.content,
      'category': post.category,
      'type': post.type,
      'nickname': post.nickname,
      'createdAt': Timestamp.fromDate(post.createdAt),
    }).timeout(const Duration(seconds: 8));

    debugPrint("Firestore'a yazma tamamlandi");
  }

  Stream<List<Post>> watchPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Post(
          id: data['id'] ?? doc.id,
          content: data['content'] ?? '',
          category: data['category'] ?? 'Günlük Yaşam',
          type: data['type'] ?? 'Dert',
          nickname: data['nickname'] ?? '@anonim',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<void> deletePost(String postId) async {
    debugPrint("Firestore post silme basladi: $postId");

    await _db.collection('posts').doc(postId).delete();

    debugPrint("Firestore post silme tamamlandi");
  }

  Future<void> addComment({
  required String postId,
  required String commentId,
  required String content,
  required String nickname,
  String? parentCommentId,
}) async {
  debugPrint("Firestore yorum yazma basladi");

  await _db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .doc(commentId)
      .set({
    'id': commentId,
    'postId': postId,
    'content': content,
    'nickname': nickname,
    'parentCommentId': parentCommentId,
    'createdAt': Timestamp.now(),
    'likeCount': 0,
  }).timeout(const Duration(seconds: 8));

  debugPrint("Firestore yorum yazma tamamlandi");
}
}
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
}
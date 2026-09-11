import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/blog_history_entry.dart';

class BlogHistoryStore extends ChangeNotifier {
  BlogHistoryStore._();

  static final instance = BlogHistoryStore._();

  List<BlogHistoryEntry> _entries = [];
  bool _loaded = false;

  List<BlogHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await _collection(user.uid)
        .orderBy('createdAt', descending: true)
        .get();
    _entries = snapshot.docs.map((doc) {
      final data = doc.data();
      return BlogHistoryEntry(
        id: doc.id,
        topic: data['topic'] as String,
        audience: data['audience'] as String,
        blog: data['blog'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
    _loaded = true;
    notifyListeners();
  }

  void reset() {
    _entries = [];
    _loaded = false;
    notifyListeners();
  }

  Future<void> add({
    required String topic,
    required String audience,
    required String blog,
  }) async {
    await load();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final createdAt = DateTime.now();
    final reference = await _collection(user.uid).add({
      'topic': topic,
      'audience': audience,
      'blog': blog,
      'createdAt': Timestamp.fromDate(createdAt),
    });
    final entry = BlogHistoryEntry(
        id: reference.id,
        topic: topic,
        audience: audience,
        blog: blog,
        createdAt: createdAt);
    _entries = [entry, ..._entries];
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection(user.uid).doc(id).delete();
    _entries = _entries.where((entry) => entry.id != id).toList();
    notifyListeners();
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blogs');
  }
}

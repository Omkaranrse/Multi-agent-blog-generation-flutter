import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/blog_history_entry.dart';

class BlogHistoryStore extends ChangeNotifier {
  BlogHistoryStore._();

  static final instance = BlogHistoryStore._();
  static const _storageKey = 'draftline.blog_history';

  List<BlogHistoryEntry> _entries = [];
  bool _loaded = false;

  List<BlogHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();
    final rawEntries = preferences.getStringList(_storageKey) ?? [];
    _entries = rawEntries
        .map((raw) => BlogHistoryEntry.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add({
    required String topic,
    required String audience,
    required String blog,
  }) async {
    await load();
    final entry = BlogHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      topic: topic,
      audience: audience,
      blog: blog,
      createdAt: DateTime.now(),
    );
    _entries = [entry, ..._entries];
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

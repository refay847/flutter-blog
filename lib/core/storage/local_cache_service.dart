// lib/core/storage/local_cache_service.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localCacheServiceProvider = Provider<LocalCacheService>(
  (ref) => LocalCacheService(),
);

/// Caches blog data + the offline action queue.
/// User/session caching lives in [TokenStorage] instead — no need to
/// duplicate it here.
class LocalCacheService {
  static const _blogsKey = 'cache.blogs';
  static const _pendingActionsKey = 'cache.pending_actions';

  Future<void> saveBlogs(List<Map<String, dynamic>> blogsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blogsKey, jsonEncode(blogsJson));
  }

  Future<List<Map<String, dynamic>>> getBlogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_blogsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingActionsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> savePendingActions(List<Map<String, dynamic>> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingActionsKey, jsonEncode(actions));
  }

  Future<void> addPendingAction(Map<String, dynamic> action) async {
    final actions = await getPendingActions();
    actions.add(action);
    await savePendingActions(actions);
  }

  /// Call on logout so the next user doesn't see a stale offline queue
  /// or someone else's cached feed.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_blogsKey);
    await prefs.remove(_pendingActionsKey);
  }
}
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the active walk on disk so it survives a killed app process.
abstract class WalkSessionStore {
  Future<Map<String, Object?>?> load();

  Future<void> save(Map<String, Object?> json);

  Future<void> clear();
}

class PrefsWalkSessionStore implements WalkSessionStore {
  const PrefsWalkSessionStore();

  static const _key = 'vauvau_active_walk_v1';

  @override
  Future<Map<String, Object?>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } catch (error) {
      debugPrint('Walk session load failed: $error');
      return null;
    }
  }

  @override
  Future<void> save(Map<String, Object?> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(json));
    } catch (error) {
      debugPrint('Walk session save failed: $error');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (error) {
      debugPrint('Walk session clear failed: $error');
    }
  }
}

class MemoryWalkSessionStore implements WalkSessionStore {
  Map<String, Object?>? stored;

  @override
  Future<Map<String, Object?>?> load() async => stored;

  @override
  Future<void> save(Map<String, Object?> json) async {
    // Round-trip through JSON like the real store does.
    stored = Map<String, Object?>.from(jsonDecode(jsonEncode(json)) as Map);
  }

  @override
  Future<void> clear() async => stored = null;
}

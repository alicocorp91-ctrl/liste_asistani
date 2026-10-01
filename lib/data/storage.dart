import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences üzerinde JSON okuma/yazma. Her liste ayrı anahtarda
/// tutulur; böylece tek bir listedeki değişiklik tüm veriyi yeniden yazmaz.
class Storage {
  Storage._(this._prefs);
  final SharedPreferences _prefs;

  static Future<Storage> open() async =>
      Storage._(await SharedPreferences.getInstance());

  // Anahtarlar
  static const keyTheme = 'settings.theme';
  static const keyBrightness = 'settings.brightness';
  static const keyListIndex = 'lists.index'; // List<String> id
  static String keyList(String id) => 'lists.item.$id';
  static const keyCustomTemplates = 'catalog.customTemplates';
  static String keyCustomItems(String templateId) =>
      'catalog.customItems.$templateId';
  static String keyDisabled(String templateId) =>
      'catalog.disabled.$templateId';
  static const keyFirstLaunch = 'app.firstLaunchDone';

  dynamic getJson(String key) {
    final s = _prefs.getString(key);
    if (s == null || s.isEmpty) return null;
    try {
      return jsonDecode(s);
    } catch (e) {
      debugPrint('Storage: bozuk JSON ($key): $e');
      return null;
    }
  }

  Future<void> setJson(String key, dynamic value) async {
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, jsonEncode(value));
  }

  Future<void> remove(String key) => _prefs.remove(key);

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? const [];
  Future<void> setStringList(String key, List<String> v) =>
      _prefs.setStringList(key, v);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int v) => _prefs.setInt(key, v);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool v) => _prefs.setBool(key, v);

  /// Tüm uygulama verisini tek JSON olarak döndürür (yedekleme).
  Map<String, dynamic> exportAll() {
    final out = <String, dynamic>{};
    for (final k in _prefs.getKeys()) {
      if (k.startsWith('lists.') ||
          k.startsWith('catalog.') ||
          k.startsWith('settings.')) {
        out[k] = _prefs.get(k);
      }
    }
    return out;
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    for (final e in data.entries) {
      final v = e.value;
      if (v is String) {
        await _prefs.setString(e.key, v);
      } else if (v is List) {
        await _prefs.setStringList(e.key, v.map((x) => x.toString()).toList());
      } else if (v is int) {
        await _prefs.setInt(e.key, v);
      } else if (v is bool) {
        await _prefs.setBool(e.key, v);
      }
    }
  }
}

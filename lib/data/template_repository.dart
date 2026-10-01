import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/template.dart';

/// Yerleşik şablonları assets/data/templates/ altından yükler.
class TemplateRepository {
  static const _dir = 'assets/data/templates';

  /// Not: rootBundle.loadString() 50 KB üzeri dosyalar için ayrı bir isolate
  /// (compute) kullanır; bu, widget testlerindeki fake-async ortamında hiç
  /// tamamlanmaz. Bu yüzden ham baytları okuyup burada çözüyoruz.
  Future<String> _readAsset(String path) async {
    final data = await rootBundle.load(path);
    return utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<List<ListTemplate>> loadBuiltIn() async {
    final ids = await _loadIndex();
    final out = <ListTemplate>[];
    for (final id in ids) {
      try {
        final raw = await _readAsset('$_dir/$id.json');
        final json = jsonDecode(raw) as Map<String, dynamic>;
        out.add(ListTemplate.fromJson(json));
      } catch (e, st) {
        debugPrint('Şablon yüklenemedi: $id -> $e\n$st');
      }
    }
    return out;
  }

  Future<List<String>> _loadIndex() async {
    try {
      final raw = await _readAsset('$_dir/index.json');
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('index.json okunamadı: $e');
      return const [
        'seyahat',
        'market',
        'piknik',
        'mangal',
        'kamp',
        'plaj',
        'tasinma'
      ];
    }
  }
}

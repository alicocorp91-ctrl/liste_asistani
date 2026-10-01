import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/storage.dart';
import '../data/template_repository.dart';
import '../models/template.dart';

/// Şablon kataloğu: yerleşik + kullanıcı tanımlı şablonlar, özel kalemler,
/// pasife alınmış kalemler. Yerleşik veriler diske yazılmaz; sadece "fark" saklanır.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._storage, this._repo);

  final Storage _storage;
  final TemplateRepository _repo;
  final _uuid = const Uuid();

  List<ListTemplate> _builtIn = [];
  List<ListTemplate> _custom = [];
  final Map<String, List<CatalogItem>> _customItems = {};
  final Map<String, Set<String>> _disabled = {};
  bool _loading = true;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;

  /// Tüm şablonlar (yerleşik önce). Özel kalemler dahil edilmiş halde.
  List<ListTemplate> get templates =>
      [..._builtIn, ..._custom].map(_withCustomItems).toList();

  ListTemplate? templateById(String id) {
    for (final t in [..._builtIn, ..._custom]) {
      if (t.id == id) return _withCustomItems(t);
    }
    return null;
  }

  bool isDisabled(String templateId, String itemId) =>
      _disabled[templateId]?.contains(itemId) ?? false;

  int disabledCount(String templateId) => _disabled[templateId]?.length ?? 0;

  List<CatalogItem> customItemsOf(String templateId) =>
      List.unmodifiable(_customItems[templateId] ?? const []);

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _builtIn = await _repo.loadBuiltIn();
      _loadCustomTemplates();
      for (final t in [..._builtIn, ..._custom]) {
        _loadCustomItems(t.id);
        _loadDisabled(t.id);
      }
      if (_builtIn.isEmpty) _error = 'Yerleşik şablonlar yüklenemedi.';
    } catch (e, st) {
      debugPrint('CatalogProvider init: $e\n$st');
      _error = 'Katalog yüklenirken hata oluştu.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Yükleme ───────────────────────────────────────────────────────────────
  void _loadCustomTemplates() {
    final raw = _storage.getJson(Storage.keyCustomTemplates);
    _custom = [];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            _custom.add(ListTemplate.fromJson(Map<String, dynamic>.from(e))
                .copyWith(isCustom: true));
          } catch (err) {
            debugPrint('Özel şablon atlandı: $err');
          }
        }
      }
    }
  }

  void _loadCustomItems(String templateId) {
    final raw = _storage.getJson(Storage.keyCustomItems(templateId));
    final out = <CatalogItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            out.add(CatalogItem.fromJson(Map<String, dynamic>.from(e))
                .copyWith(isCustom: true));
          } catch (_) {}
        }
      }
    }
    _customItems[templateId] = out;
  }

  void _loadDisabled(String templateId) {
    _disabled[templateId] =
        _storage.getStringList(Storage.keyDisabled(templateId)).toSet();
  }

  ListTemplate _withCustomItems(ListTemplate t) {
    final extra = _customItems[t.id];
    if (extra == null || extra.isEmpty) return t;
    return t.copyWith(items: [...t.items, ...extra]);
  }

  // ── Kalem aktif/pasif ─────────────────────────────────────────────────────
  Future<void> setItemEnabled(
      String templateId, String itemId, bool enabled) async {
    final set = _disabled.putIfAbsent(templateId, () => <String>{});
    if (enabled) {
      set.remove(itemId);
    } else {
      set.add(itemId);
    }
    notifyListeners();
    await _storage.setStringList(Storage.keyDisabled(templateId), set.toList());
  }

  Future<void> resetDisabled(String templateId) async {
    _disabled[templateId] = {};
    notifyListeners();
    await _storage.remove(Storage.keyDisabled(templateId));
  }

  // ── Özel kalemler ─────────────────────────────────────────────────────────
  Future<CatalogItem> addCustomItem(String templateId, CatalogItem item) async {
    final created = item.copyWith(id: 'c_${_uuid.v4()}', isCustom: true);
    _customItems.putIfAbsent(templateId, () => []).add(created);
    notifyListeners();
    await _saveCustomItems(templateId);
    return created;
  }

  Future<void> updateCustomItem(String templateId, CatalogItem item) async {
    final list = _customItems[templateId];
    if (list == null) return;
    final i = list.indexWhere((e) => e.id == item.id);
    if (i == -1) return;
    list[i] = item.copyWith(isCustom: true);
    notifyListeners();
    await _saveCustomItems(templateId);
  }

  Future<void> deleteCustomItem(String templateId, String itemId) async {
    _customItems[templateId]?.removeWhere((e) => e.id == itemId);
    notifyListeners();
    await _saveCustomItems(templateId);
  }

  Future<void> _saveCustomItems(String templateId) => _storage.setJson(
      Storage.keyCustomItems(templateId),
      (_customItems[templateId] ?? []).map((e) => e.toJson()).toList());

  // ── Özel şablonlar ────────────────────────────────────────────────────────
  Future<ListTemplate> addCustomTemplate(ListTemplate t) async {
    final created =
        t.copyWith(id: 'ct_${_uuid.v4()}', isCustom: true, items: const []);
    _custom.add(created);
    _customItems[created.id] = [];
    _disabled[created.id] = {};
    notifyListeners();
    await _saveCustomTemplates();
    return created;
  }

  Future<void> updateCustomTemplate(ListTemplate t) async {
    final i = _custom.indexWhere((e) => e.id == t.id);
    if (i == -1) return;
    _custom[i] = t.copyWith(isCustom: true, items: const []);
    // Kaldırılan kategorilere bağlı özel kalemleri ilk kategoriye taşı
    final catIds = t.categories.map((c) => c.id).toSet();
    final fallback =
        t.categories.isNotEmpty ? t.categories.first.id : 'general';
    final items = _customItems[t.id];
    if (items != null) {
      for (var k = 0; k < items.length; k++) {
        if (!catIds.contains(items[k].category)) {
          items[k] = items[k].copyWith(category: fallback);
        }
      }
      await _saveCustomItems(t.id);
    }
    notifyListeners();
    await _saveCustomTemplates();
  }

  Future<void> deleteCustomTemplate(String id) async {
    _custom.removeWhere((e) => e.id == id);
    _customItems.remove(id);
    _disabled.remove(id);
    notifyListeners();
    await _saveCustomTemplates();
    await _storage.remove(Storage.keyCustomItems(id));
    await _storage.remove(Storage.keyDisabled(id));
  }

  Future<void> _saveCustomTemplates() => _storage.setJson(
      Storage.keyCustomTemplates, _custom.map((e) => e.toJson()).toList());

  /// Dışa/içe aktarma sonrası yeniden yükleme
  Future<void> reload() => init();
}

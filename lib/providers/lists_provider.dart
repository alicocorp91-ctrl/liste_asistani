import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/utils.dart';
import '../data/storage.dart';
import '../models/template.dart';
import '../models/user_list.dart';
import '../services/notification_service.dart';

/// Kullanıcı listeleri: oluşturma, kalem işlemleri, arşiv, hatırlatıcılar.
class ListsProvider extends ChangeNotifier {
  ListsProvider(this._storage, this._notifications);

  final Storage _storage;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  List<UserList> _lists = [];
  bool _loading = true;

  bool get isLoading => _loading;
  List<UserList> get all => List.unmodifiable(_lists);

  List<UserList> get active => _sorted(_lists.where((l) => !l.isArchived));
  List<UserList> get archived => _lists.where((l) => l.isArchived).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  UserList? byId(String id) => _lists.firstWhereOrNull((l) => l.id == id);

  List<UserList> _sorted(Iterable<UserList> src) {
    final favs = src.where((l) => l.isFavorite).toList();
    final rest = src.where((l) => !l.isFavorite);
    return [..._sortedByDate(favs), ..._sortedByDate(rest)];
  }

  List<UserList> _sortedByDate(Iterable<UserList> src) {
    final withDate = src.where((l) => l.startDate != null && !l.isPast).toList()
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    final noDate = src.where((l) => l.startDate == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final past = src.where((l) => l.startDate != null && l.isPast).toList()
      ..sort((a, b) => b.startDate!.compareTo(a.startDate!));
    return [...withDate, ...noDate, ...past];
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final ids = _storage.getStringList(Storage.keyListIndex);
      final out = <UserList>[];
      for (final id in ids) {
        final raw = _storage.getJson(Storage.keyList(id));
        if (raw is Map) {
          try {
            out.add(UserList.fromJson(Map<String, dynamic>.from(raw)));
          } catch (e) {
            debugPrint('Liste okunamadı ($id): $e');
          }
        }
      }
      _lists = out;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Kaydetme ──────────────────────────────────────────────────────────────
  Future<void> _saveIndex() => _storage.setStringList(
      Storage.keyListIndex, _lists.map((l) => l.id).toList());

  Future<void> _save(UserList l) =>
      _storage.setJson(Storage.keyList(l.id), l.toJson());

  Future<void> _update(UserList updated) async {
    final i = _lists.indexWhere((l) => l.id == updated.id);
    if (i == -1) return;
    _lists[i] = updated;
    notifyListeners();
    await _save(updated);
  }

  // ── Öneri üretimi ─────────────────────────────────────────────────────────
  /// Şablon + cevaplara göre önerilen kalemleri üretir (listeye eklemeden).
  List<ListItem> suggestItems({
    required ListTemplate template,
    required Map<String, String> answers,
    required int days,
    required bool Function(String itemId) isDisabled,
    DateTime? eventDate,
  }) {
    final out = <ListItem>[];
    for (final c in template.items) {
      if (isDisabled(c.id)) continue;
      if (!c.when.matches(answers)) continue;
      out.add(_fromCatalog(c, days, eventDate));
    }
    return out;
  }

  ListItem _fromCatalog(CatalogItem c, int days, DateTime? eventDate) {
    DateTime? reminder;
    if (c.daysBefore != null && eventDate != null) {
      final d = dateOnly(eventDate).subtract(Duration(days: c.daysBefore!));
      reminder = DateTime(d.year, d.month, d.day, 10);
    }
    return ListItem(
      id: _uuid.v4(),
      catalogId: c.id,
      name: c.name,
      categoryId: c.category,
      quantity: c.qty?.compute(days),
      unit: c.unit,
      note: c.note,
      reminderAt: reminder,
      isEssential: c.essential,
    );
  }

  /// Katalog kalemini var olan bir listeye uygun ListItem'a çevirir.
  ListItem itemFromCatalog(UserList list, CatalogItem c) =>
      _fromCatalog(c, list.days, list.startDate);

  // ── Liste CRUD ────────────────────────────────────────────────────────────
  Future<UserList> createList({
    required ListTemplate template,
    required String name,
    required Map<String, String> fields,
    required Map<String, String> answers,
    DateTime? startDate,
    DateTime? endDate,
    required List<ListItem> items,
  }) async {
    final now = DateTime.now();
    final list = UserList(
      id: _uuid.v4(),
      templateId: template.id,
      templateName: template.name,
      icon: template.icon,
      color: template.color,
      name: name.trim(),
      kind: template.kind,
      quickAdd: template.quickAdd,
      fields: fields,
      answers: answers,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
      updatedAt: now,
      sections: template.sections,
      categories: template.categories,
      items: items,
    );
    _lists.insert(0, list);
    notifyListeners();
    await _save(list);
    await _saveIndex();
    return list;
  }

  Future<void> rename(String id, String name) async {
    final l = byId(id);
    if (l == null || name.trim().isEmpty) return;
    await _update(l.copyWith(name: name.trim()));
  }

  Future<void> updateMeta(String id,
      {Map<String, String>? fields,
      DateTime? start,
      DateTime? end,
      bool clearDates = false}) async {
    final l = byId(id);
    if (l == null) return;
    await _update(l.copyWith(
      fields: fields,
      startDate: start,
      endDate: end,
      clearStart: clearDates,
      clearEnd: clearDates,
    ));
  }

  Future<void> setArchived(String id, bool archived) async {
    final l = byId(id);
    if (l == null) return;
    if (archived) await _cancelAllReminders(l);
    await _update(l.copyWith(isArchived: archived));
    if (!archived) await _rescheduleAll(byId(id)!);
  }

  Future<UserList?> duplicate(String id, {bool resetChecks = true}) async {
    final src = byId(id);
    if (src == null) return null;
    final now = DateTime.now();
    final copy = src.copyWith(
      id: _uuid.v4(),
      name: '${src.name} (kopya)',
      createdAt: now,
      updatedAt: now,
      isArchived: false,
      items: src.items
          .map((i) => ListItem(
                id: _uuid.v4(),
                catalogId: i.catalogId,
                name: i.name,
                categoryId: i.categoryId,
                isChecked: resetChecks ? false : i.isChecked,
                quantity: i.quantity,
                unit: i.unit,
                note: i.note,
                isEssential: i.isEssential,
                isCustom: i.isCustom,
                stockQty: i.stockQty,
              ))
          .toList(),
    );
    _lists.insert(0, copy);
    notifyListeners();
    await _save(copy);
    await _saveIndex();
    return copy;
  }

  Future<void> delete(String id) async {
    final l = byId(id);
    if (l == null) return;
    await _cancelAllReminders(l);
    _lists.removeWhere((x) => x.id == id);
    notifyListeners();
    await _storage.remove(Storage.keyList(id));
    await _saveIndex();
  }

  Future<void> resetChecks(String id) async {
    final l = byId(id);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items.map((i) => i.copyWith(isChecked: false)).toList()));
  }

  Future<void> setFavorite(String id, bool fav) async {
    final l = byId(id);
    if (l == null) return;
    await _update(l.copyWith(isFavorite: fav));
  }

  // ── Stok (inventory) işlemleri ────────────────────────────────────────────
  Future<void> setStock(String listId, String itemId, int stock) async {
    final l = byId(listId);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items
            .map((i) =>
                i.id == itemId ? i.copyWith(stockQty: stock.clamp(0, 9999)) : i)
            .toList()));
  }

  /// Hedef (gereken) ve stok miktarını birlikte ayarlar.
  Future<void> setStockLevels(String listId, String itemId,
      {required int need, required int stock}) async {
    final l = byId(listId);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items
            .map((i) => i.id == itemId
                ? i.copyWith(
                    quantity: need.clamp(1, 9999),
                    stockQty: stock.clamp(0, 9999))
                : i)
            .toList()));
  }

  /// Stokta var/yok hızlı geçişi: eksikse stoğu gereken miktara tamamlar,
  /// tamsa sıfırlar.
  Future<void> toggleStock(String listId, String itemId) async {
    final l = byId(listId);
    final i = l?.items.firstWhereOrNull((x) => x.id == itemId);
    if (l == null || i == null) return;
    await setStock(listId, itemId, i.isMissing ? i.needQty : 0);
  }

  /// Tüm kalemleri stokta / stok yok yapar.
  Future<void> setAllStock(String listId, bool full) async {
    final l = byId(listId);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items
            .map((i) => i.copyWith(stockQty: full ? i.needQty : 0))
            .toList()));
  }

  /// Aktarma için hedef olabilecek listeler: kaynağın kendisi hariç, arşivde
  /// olmayan stok listeleri (önce market şablonundan olanlar).
  List<UserList> transferTargets(String sourceId) {
    final out = _lists
        .where((l) => l.id != sourceId && !l.isArchived && l.isInventory)
        .toList()
      ..sort((a, b) {
        final am = a.templateId == 'market' ? 0 : 1;
        final bm = b.templateId == 'market' ? 0 : 1;
        if (am != bm) return am - bm;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return out;
  }

  static const transferCategoryId = 'transfer';

  /// Kaynak listedeki eksikleri hedef (alışveriş) listesine aktarır.
  /// Aynı adlı kalem hedefte varsa kopya üretmez; miktarını eksik kadar
  /// günceller ve işaretini kaldırır. Döndürülen değer: eklenen + güncellenen.
  Future<int> transferMissing(String sourceId, String targetId) async {
    final src = byId(sourceId);
    final dst = byId(targetId);
    if (src == null || dst == null || sourceId == targetId) return 0;
    final missing = src.missingItems;
    if (missing.isEmpty) return 0;

    final byName = <String, ListItem>{
      for (final i in dst.items) normalizeTr(i.name.trim()): i,
    };
    final dstCatIds = dst.categories.map((c) => c.id).toSet();
    final dstCatByName = <String, String>{
      for (final c in dst.categories) normalizeTr(c.name): c.id,
    };
    var categories = dst.categories;
    var items = List<ListItem>.from(dst.items);
    var count = 0;

    for (final m in missing) {
      final key = normalizeTr(m.name.trim());
      final existing = byName[key];
      if (existing != null) {
        final idx = items.indexWhere((i) => i.id == existing.id);
        items[idx] = existing.copyWith(
          quantity: m.toBuy,
          unit: (existing.unit == null || existing.unit!.isEmpty)
              ? m.unit
              : existing.unit,
          isChecked: false,
        );
        count++;
        continue;
      }
      // Kategori eşleme: aynı id → aynı ad → 'transfer' kategorisi
      String catId;
      final srcCat = src.categoryById(m.categoryId);
      if (dstCatIds.contains(m.categoryId)) {
        catId = m.categoryId;
      } else if (srcCat != null &&
          dstCatByName.containsKey(normalizeTr(srcCat.name))) {
        catId = dstCatByName[normalizeTr(srcCat.name)]!;
      } else {
        catId = transferCategoryId;
        if (!dstCatIds.contains(transferCategoryId)) {
          categories = [
            ...categories,
            TemplateCategory(
              id: transferCategoryId,
              name: 'Aktarılan eksikler',
              icon: 'move_to_inbox',
              color: '#78909C',
              section: dst.sections.isNotEmpty ? dst.sections.first.id : 'main',
            ),
          ];
          dstCatIds.add(transferCategoryId);
        }
      }
      final item = ListItem(
        id: _uuid.v4(),
        catalogId: null,
        name: m.name,
        categoryId: catId,
        quantity: m.toBuy,
        unit: m.unit,
        note: 'Eksik: ${src.name}',
        isEssential: m.isEssential,
        isCustom: true,
      );
      items.add(item);
      byName[key] = item;
      count++;
    }
    await _update(dst.copyWith(items: items, categories: categories));
    return count;
  }

  // ── Kalem işlemleri ───────────────────────────────────────────────────────
  Future<void> toggleItem(String listId, String itemId) async {
    final l = byId(listId);
    if (l == null) return;
    ListItem? changed;
    final items = l.items.map((i) {
      if (i.id != itemId) return i;
      changed = i.copyWith(isChecked: !i.isChecked);
      return changed!;
    }).toList();
    await _update(l.copyWith(items: items));
    if (changed != null) await _syncReminder(l.id, l.name, changed!);
  }

  Future<void> updateItem(String listId, ListItem item) async {
    final l = byId(listId);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items.map((i) => i.id == item.id ? item : i).toList()));
    await _syncReminder(l.id, l.name, item);
  }

  Future<void> setQuantity(String listId, String itemId, int? qty) async {
    final l = byId(listId);
    if (l == null) return;
    await _update(l.copyWith(
        items: l.items
            .map((i) => i.id == itemId
                ? i.copyWith(quantity: qty, clearQuantity: qty == null)
                : i)
            .toList()));
  }

  Future<void> removeItem(String listId, String itemId) async {
    final l = byId(listId);
    if (l == null) return;
    await _notifications.cancel(_notifId(listId, itemId));
    await _update(
        l.copyWith(items: l.items.where((i) => i.id != itemId).toList()));
  }

  Future<void> removeItems(String listId, Set<String> itemIds) async {
    final l = byId(listId);
    if (l == null) return;
    for (final id in itemIds) {
      await _notifications.cancel(_notifId(listId, id));
    }
    await _update(l.copyWith(
        items: l.items.where((i) => !itemIds.contains(i.id)).toList()));
  }

  Future<ListItem> addCustomItem(String listId,
      {required String name,
      required String categoryId,
      int? quantity,
      String? unit,
      String? note,
      int stockQty = 0}) async {
    final l = byId(listId)!;
    final item = ListItem(
      id: _uuid.v4(),
      name: name.trim(),
      categoryId: categoryId,
      quantity: quantity,
      unit: unit,
      note: note,
      isCustom: true,
      stockQty: stockQty,
    );
    await _update(l.copyWith(items: [...l.items, item]));
    return item;
  }

  /// Hızlı ekleme: metin katalogdaki bir kalemle (ad olarak) eşleşiyorsa onu,
  /// yoksa 'other' (ya da ilk) kategoriye serbest kalem ekler.
  /// Listede aynı adlı kalem zaten varsa onu işaretsiz yapar ve döndürür.
  Future<ListItem?> quickAdd(String listId, String text,
      {ListTemplate? template,
      CatalogItem? catalogItem,
      int? quantity,
      String? unit}) async {
    final l = byId(listId);
    final name = text.trim();
    if (l == null || name.isEmpty) return null;
    final key = normalizeTr(name);
    final existing =
        l.items.firstWhereOrNull((i) => normalizeTr(i.name) == key);
    if (existing != null) {
      final needsReset =
          existing.isChecked || (l.isInventory && existing.inStock);
      if (needsReset || quantity != null) {
        await updateItem(
            listId,
            existing.copyWith(
                isChecked: needsReset ? false : existing.isChecked,
                stockQty: needsReset && l.isInventory ? 0 : null,
                quantity: quantity ?? existing.quantity,
                unit: unit ?? existing.unit));
      }
      return byId(listId)!.items.firstWhere((i) => i.id == existing.id);
    }
    final c = catalogItem ??
        template?.items.firstWhereOrNull((x) => normalizeTr(x.name) == key);
    final catIds = l.categories.map((x) => x.id).toSet();
    ListItem item;
    if (c != null && catIds.contains(c.category)) {
      item = _fromCatalog(c, l.days, l.startDate);
    } else {
      final catId = catIds.contains('other')
          ? 'other'
          : (l.categories.isNotEmpty ? l.categories.first.id : 'other');
      item = ListItem(
        id: _uuid.v4(),
        name: c?.name ?? name,
        categoryId: catId,
        quantity: c?.qty?.compute(l.days),
        unit: c?.unit,
        isCustom: true,
      );
    }
    // Sesle/elle verilen adet ve birim katalog varsayılanını ezer.
    // "adet" birimini boş bırakırız; arayüz "×2" şeklinde gösterir.
    if (quantity != null) {
      item = item.copyWith(
          quantity: quantity,
          unit: (unit == null || unit == 'adet') ? item.unit : unit);
    } else if (unit != null && unit != 'adet') {
      item = item.copyWith(unit: unit);
    }
    await _update(l.copyWith(items: [...l.items, item]));
    return item;
  }

  /// Katalogdan seçilen kalemleri ekler (zaten listede olanları atlar).
  Future<int> addItems(String listId, List<ListItem> items) async {
    final l = byId(listId);
    if (l == null) return 0;
    final existing =
        l.items.map((i) => i.catalogId).whereType<String>().toSet();
    final fresh = items
        .where((i) => i.catalogId == null || !existing.contains(i.catalogId))
        .toList();
    if (fresh.isEmpty) return 0;
    await _update(l.copyWith(items: [...l.items, ...fresh]));
    return fresh.length;
  }

  Future<void> setReminder(
      String listId, String itemId, DateTime? at, bool enabled) async {
    final l = byId(listId);
    if (l == null) return;
    ListItem? changed;
    final items = l.items.map((i) {
      if (i.id != itemId) return i;
      changed = at == null
          ? i.copyWith(clearReminder: true)
          : i.copyWith(reminderAt: at, reminderEnabled: enabled);
      return changed!;
    }).toList();
    await _update(l.copyWith(items: items));
    if (changed != null) await _syncReminder(l.id, l.name, changed!);
  }

  /// Tarihli listelerde tüm hatırlatıcıları aç/kapat
  Future<void> setAllReminders(String listId, bool enabled) async {
    final l = byId(listId);
    if (l == null) return;
    final items = l.items
        .map((i) =>
            i.reminderAt == null ? i : i.copyWith(reminderEnabled: enabled))
        .toList();
    await _update(l.copyWith(items: items));
    for (final i in items) {
      await _syncReminder(l.id, l.name, i);
    }
  }

  int pendingReminderCount(UserList l) => l.items
      .where((i) =>
          i.reminderEnabled &&
          !i.isChecked &&
          i.reminderAt != null &&
          i.reminderAt!.isAfter(DateTime.now()))
      .length;

  // ── Bildirim senkronu ─────────────────────────────────────────────────────
  int _notifId(String listId, String itemId) => stableHash('$listId|$itemId');

  Future<void> _syncReminder(String listId, String listName, ListItem i) async {
    final id = _notifId(listId, i.id);
    if (i.reminderEnabled &&
        !i.isChecked &&
        i.reminderAt != null &&
        i.reminderAt!.isAfter(DateTime.now())) {
      await _notifications.schedule(
        id: id,
        title: listName,
        body: '${i.name} — zamanı geldi!',
        at: i.reminderAt!,
        payload: listId,
      );
    } else {
      await _notifications.cancel(id);
    }
  }

  Future<void> _cancelAllReminders(UserList l) async {
    for (final i in l.items) {
      await _notifications.cancel(_notifId(l.id, i.id));
    }
  }

  Future<void> _rescheduleAll(UserList l) async {
    for (final i in l.items) {
      await _syncReminder(l.id, l.name, i);
    }
  }

  /// Uygulama açılışında (yeniden kurulum / cihaz yeniden başlatma sonrası) planları tazele.
  Future<void> rescheduleEverything() async {
    for (final l in _lists.where((l) => !l.isArchived)) {
      await _rescheduleAll(l);
    }
  }

  // ── Paylaşım metni ────────────────────────────────────────────────────────
  String shareText(UserList l,
      {bool onlyUnchecked = false, bool onlyMissing = false}) {
    final b = StringBuffer();
    b.writeln('📋 ${l.name}');
    if (l.subtitle.isNotEmpty) b.writeln(l.subtitle);
    if (onlyMissing && l.isInventory) {
      b.writeln('🛒 Eksikler (${l.missingCount} kalem)');
    } else {
      b.writeln('${l.checkedCount}/${l.totalCount} tamamlandı');
      if (l.isInventory) b.writeln('${l.missingCount} eksik');
    }
    for (final s in l.sections) {
      final cats = l.categoriesOf(s.id);
      final sectionItems = l.itemsOfSection(s.id);
      if (sectionItems.isEmpty) continue;
      if (l.hasSections) b.writeln('\n═══ ${upperTr(s.name)} ═══');
      for (final c in cats) {
        var items = l.itemsOfCategory(c.id);
        if (onlyUnchecked) items = items.where((i) => !i.isChecked).toList();
        if (onlyMissing && l.isInventory) {
          items = items.where((i) => i.isMissing).toList();
        }
        if (items.isEmpty) continue;
        b.writeln('\n${c.name}');
        for (final i in items) {
          if (onlyMissing && l.isInventory) {
            b.writeln('☐ ${i.name} (${i.toBuyLabel})');
            continue;
          }
          final q = l.isInventory
              ? ' [stok ${i.stockLabel}${i.isMissing ? ' ⚠' : ''}]'
              : (i.quantityLabel.isEmpty ? '' : ' (${i.quantityLabel})');
          b.writeln('${i.isChecked ? '☑' : '☐'} ${i.name}$q');
        }
      }
    }
    b.writeln('\n— Liste Asistanı');
    return b.toString();
  }

  Future<void> reload() => init();
}

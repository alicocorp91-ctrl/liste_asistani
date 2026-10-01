import '../core/utils.dart';
import 'template.dart';

/// Kullanıcının oluşturduğu bir liste. Şablondan bağımsız çalışabilmesi için
/// bölüm ve kategori tanımlarını kendi içinde taşır (snapshot).
class UserList {
  final String id;
  final String templateId;
  final String templateName;
  final String icon;
  final String color;
  final String name;
  final ListKind kind;
  final bool isFavorite;

  /// Liste ekranının altında hızlı ekleme çubuğu (market).
  final bool quickAdd;
  final Map<String, String> fields;
  final Map<String, String> answers;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final List<TemplateSection> sections;
  final List<TemplateCategory> categories;
  final List<ListItem> items;

  const UserList({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.icon,
    required this.color,
    required this.name,
    this.kind = ListKind.checklist,
    this.isFavorite = false,
    this.quickAdd = false,
    this.fields = const {},
    this.answers = const {},
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    required this.sections,
    required this.categories,
    this.items = const [],
  });

  // ── Hesaplanan ────────────────────────────────────────────────────────────
  int get totalCount => items.length;
  int get checkedCount => items.where((i) => i.isChecked).length;
  double get progress => totalCount == 0 ? 0 : checkedCount / totalCount;
  bool get isComplete => totalCount > 0 && checkedCount == totalCount;

  /// Malzeme/stok listesi mi? (piknik, kamp, market ve stok takibi açık özel tipler)
  bool get isInventory => kind == ListKind.inventory;

  /// Stok listesinde stoğu gereken miktarın altında olan kalemler.
  List<ListItem> get missingItems =>
      isInventory ? items.where((i) => i.isMissing).toList() : const [];
  int get missingCount => missingItems.length;
  int get inStockCount => isInventory ? totalCount - missingCount : 0;

  /// Gün sayısı (miktar hesabı için). Tarih yoksa 1.
  int get days {
    if (startDate == null) return 1;
    if (endDate == null) return 1;
    if (endDate!.isBefore(startDate!)) return 1;
    return dateOnly(endDate!).difference(dateOnly(startDate!)).inDays + 1;
  }

  bool get hasDate => startDate != null;

  bool get isPast {
    final ref = endDate ?? startDate;
    if (ref == null) return false;
    return DateTime.now()
        .isAfter(DateTime(ref.year, ref.month, ref.day, 23, 59, 59));
  }

  bool get hasSections => sections.length > 1;

  String get subtitle {
    final parts = <String>[];
    final from = fields['from'], to = fields['to'];
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      parts.add('$from → $to');
    } else {
      for (final v in fields.values) {
        if (v.trim().isNotEmpty) parts.add(v.trim());
      }
    }
    if (startDate != null) parts.add(fmtRange(startDate, endDate));
    return parts.join(' · ');
  }

  TemplateCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<TemplateCategory> categoriesOf(String sectionId) =>
      categories.where((c) => c.section == sectionId).toList();

  List<ListItem> itemsOfCategory(String categoryId) =>
      items.where((i) => i.categoryId == categoryId).toList();

  List<ListItem> itemsOfSection(String sectionId) {
    final catIds = categoriesOf(sectionId).map((c) => c.id).toSet();
    return items.where((i) => catIds.contains(i.categoryId)).toList();
  }

  int checkedInSection(String sectionId) =>
      itemsOfSection(sectionId).where((i) => i.isChecked).length;

  UserList copyWith({
    String? id,
    String? name,
    ListKind? kind,
    bool? isFavorite,
    bool? quickAdd,
    Map<String, String>? fields,
    Map<String, String>? answers,
    DateTime? startDate,
    bool clearStart = false,
    DateTime? endDate,
    bool clearEnd = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    List<TemplateSection>? sections,
    List<TemplateCategory>? categories,
    List<ListItem>? items,
    String? icon,
    String? color,
  }) =>
      UserList(
        id: id ?? this.id,
        templateId: templateId,
        templateName: templateName,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        isFavorite: isFavorite ?? this.isFavorite,
        quickAdd: quickAdd ?? this.quickAdd,
        fields: fields ?? this.fields,
        answers: answers ?? this.answers,
        startDate: clearStart ? null : (startDate ?? this.startDate),
        endDate: clearEnd ? null : (endDate ?? this.endDate),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        isArchived: isArchived ?? this.isArchived,
        sections: sections ?? this.sections,
        categories: categories ?? this.categories,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'templateName': templateName,
        'icon': icon,
        'color': color,
        'name': name,
        'kind': kind.name,
        'isFavorite': isFavorite,
        'quickAdd': quickAdd,
        'fields': fields,
        'answers': answers,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isArchived': isArchived,
        'sections': sections.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory UserList.fromJson(Map<String, dynamic> j) {
    Map<String, String> strMap(dynamic raw) => raw is Map
        ? {
            for (final e in raw.entries)
              e.key.toString(): e.value?.toString() ?? ''
          }
        : {};
    List<T> lst<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw is! List) return [];
      final out = <T>[];
      for (final e in raw) {
        if (e is Map) {
          try {
            out.add(f(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      return out;
    }

    final templateId = j['templateId']?.toString() ?? 'custom';
    // Eski kayıtlarda 'kind' yok: malzeme şablonları için stok modu varsayılır.
    final kind = j['kind'] != null
        ? ListKind.parse(j['kind'].toString())
        : (const {'market', 'piknik', 'kamp', 'mangal'}.contains(templateId)
            ? ListKind.inventory
            : ListKind.checklist);
    return UserList(
      id: j['id'] as String,
      templateId: templateId,
      templateName: j['templateName']?.toString() ?? 'Liste',
      icon: j['icon']?.toString() ?? 'list_alt',
      color: j['color']?.toString() ?? '#607D8B',
      name: j['name']?.toString() ?? 'Liste',
      kind: kind,
      isFavorite: j['isFavorite'] as bool? ?? false,
      quickAdd: j['quickAdd'] as bool? ?? (templateId == 'market'),
      fields: strMap(j['fields']),
      answers: strMap(j['answers']),
      startDate: parseDate(j['startDate']),
      endDate: parseDate(j['endDate']),
      createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(j['updatedAt']) ?? DateTime.now(),
      isArchived: j['isArchived'] as bool? ?? false,
      sections: lst(j['sections'], TemplateSection.fromJson),
      categories: lst(j['categories'], TemplateCategory.fromJson),
      items: lst(j['items'], ListItem.fromJson),
    );
  }
}

/// Listeye kopyalanmış tek bir kalem.
class ListItem {
  final String id;
  final String? catalogId;
  final String name;
  final String categoryId;
  final bool isChecked;
  final int? quantity;
  final String? unit;
  final String? note;
  final DateTime? reminderAt;
  final bool reminderEnabled;
  final bool isEssential;
  final bool isCustom;

  /// Stok listelerinde eldeki miktar (gereken miktar = [quantity] ?? 1).
  final int stockQty;

  const ListItem({
    required this.id,
    this.catalogId,
    required this.name,
    required this.categoryId,
    this.isChecked = false,
    this.quantity,
    this.unit,
    this.note,
    this.reminderAt,
    this.reminderEnabled = false,
    this.isEssential = false,
    this.isCustom = false,
    this.stockQty = 0,
  });

  String get quantityLabel {
    if (quantity == null) return '';
    return unit == null || unit!.isEmpty ? '$quantity' : '$quantity $unit';
  }

  // ── Stok (inventory) ──────────────────────────────────────────────────────
  /// Gereken miktar; miktar tanımsızsa 1 kabul edilir.
  int get needQty => quantity ?? 1;
  bool get isMissing => stockQty < needQty;
  bool get inStock => !isMissing;

  /// Alınması gereken miktar (eksik).
  int get toBuy => (needQty - stockQty).clamp(0, 1 << 30);

  /// "1/2 paket" biçiminde stok etiketi.
  String get stockLabel {
    final u = unit == null || unit!.isEmpty ? '' : ' $unit';
    return '$stockQty/$needQty$u';
  }

  String get toBuyLabel {
    final u = unit == null || unit!.isEmpty ? '' : ' $unit';
    return '$toBuy$u';
  }

  ListItem copyWith({
    String? name,
    String? categoryId,
    bool? isChecked,
    int? quantity,
    bool clearQuantity = false,
    String? unit,
    String? note,
    bool clearNote = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool? reminderEnabled,
    bool? isEssential,
    int? stockQty,
  }) =>
      ListItem(
        id: id,
        catalogId: catalogId,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        isChecked: isChecked ?? this.isChecked,
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        unit: unit ?? this.unit,
        note: clearNote ? null : (note ?? this.note),
        reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
        reminderEnabled:
            clearReminder ? false : (reminderEnabled ?? this.reminderEnabled),
        isEssential: isEssential ?? this.isEssential,
        isCustom: isCustom,
        stockQty: stockQty ?? this.stockQty,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'catalogId': catalogId,
        'name': name,
        'categoryId': categoryId,
        'isChecked': isChecked,
        'quantity': quantity,
        'unit': unit,
        'note': note,
        'reminderAt': reminderAt?.toIso8601String(),
        'reminderEnabled': reminderEnabled,
        'isEssential': isEssential,
        'isCustom': isCustom,
        'stockQty': stockQty,
      };

  factory ListItem.fromJson(Map<String, dynamic> j) => ListItem(
        id: j['id'] as String,
        catalogId: j['catalogId']?.toString(),
        name: j['name']?.toString() ?? '',
        categoryId: j['categoryId']?.toString() ?? 'other',
        isChecked: j['isChecked'] as bool? ?? false,
        quantity: (j['quantity'] as num?)?.toInt(),
        unit: j['unit']?.toString(),
        note: j['note']?.toString(),
        reminderAt: parseDate(j['reminderAt']),
        reminderEnabled: j['reminderEnabled'] as bool? ?? false,
        isEssential: j['isEssential'] as bool? ?? false,
        isCustom: j['isCustom'] as bool? ?? false,
        stockQty: (j['stockQty'] as num?)?.toInt() ?? 0,
      );
}

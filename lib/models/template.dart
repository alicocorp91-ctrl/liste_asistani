import 'dart:math' as math;

/// Liste tipi (şablon). Yerleşik olanlar assets/data/templates/*.json'dan,
/// kullanıcı tanımlı olanlar SharedPreferences'tan yüklenir. Aynı şemayı paylaşırlar.
class ListTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color; // #RRGGBB
  /// checklist: tek seferlik kontrol listesi. inventory: malzeme/stok listesi
  /// (her kalemde gereken + stok miktarı, eksik takibi, markete aktarma).
  final ListKind kind;

  /// false: öneri ekranında hiçbir kalem ön seçili gelmez (market gibi
  /// "aklıma geldikçe eklerim" listeleri için).
  final bool preselect;

  /// true: liste ekranının altında hızlı ekleme çubuğu gösterilir.
  final bool quickAdd;
  final DateMode dateMode;
  final String dateLabel;
  final String? endDateLabel;
  final List<TextFieldDef> textFields;
  final List<FilterDef> filters;
  final List<TemplateSection> sections;
  final List<TemplateCategory> categories;
  final List<CatalogItem> items;
  final bool isCustom;

  const ListTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.icon,
    required this.color,
    this.kind = ListKind.checklist,
    this.preselect = true,
    this.quickAdd = false,
    this.dateMode = DateMode.none,
    this.dateLabel = 'Tarih',
    this.endDateLabel,
    this.textFields = const [],
    this.filters = const [],
    required this.sections,
    required this.categories,
    this.items = const [],
    this.isCustom = false,
  });

  bool get hasSections => sections.length > 1;
  bool get isInventory => kind == ListKind.inventory;

  TemplateCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  TemplateSection? sectionById(String id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<TemplateCategory> categoriesOf(String sectionId) =>
      categories.where((c) => c.section == sectionId).toList();

  /// Filtre cevapları verilmemişse varsayılanlarla doldurur.
  Map<String, String> defaultAnswers() =>
      {for (final f in filters) f.id: f.defaultOption};

  ListTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    ListKind? kind,
    bool? preselect,
    bool? quickAdd,
    DateMode? dateMode,
    String? dateLabel,
    String? endDateLabel,
    List<TextFieldDef>? textFields,
    List<FilterDef>? filters,
    List<TemplateSection>? sections,
    List<TemplateCategory>? categories,
    List<CatalogItem>? items,
    bool? isCustom,
  }) =>
      ListTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        kind: kind ?? this.kind,
        preselect: preselect ?? this.preselect,
        quickAdd: quickAdd ?? this.quickAdd,
        dateMode: dateMode ?? this.dateMode,
        dateLabel: dateLabel ?? this.dateLabel,
        endDateLabel: endDateLabel ?? this.endDateLabel,
        textFields: textFields ?? this.textFields,
        filters: filters ?? this.filters,
        sections: sections ?? this.sections,
        categories: categories ?? this.categories,
        items: items ?? this.items,
        isCustom: isCustom ?? this.isCustom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'kind': kind.name,
        'preselect': preselect,
        'quickAdd': quickAdd,
        'dateMode': dateMode.name,
        'dateLabel': dateLabel,
        'endDateLabel': endDateLabel,
        'textFields': textFields.map((e) => e.toJson()).toList(),
        'filters': filters.map((e) => e.toJson()).toList(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
        'isCustom': isCustom,
      };

  factory ListTemplate.fromJson(Map<String, dynamic> j) => ListTemplate(
        id: j['id'] as String,
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'list_alt',
        color: j['color']?.toString() ?? '#607D8B',
        kind: ListKind.parse(j['kind']?.toString()),
        preselect: j['preselect'] as bool? ?? true,
        quickAdd: j['quickAdd'] as bool? ?? false,
        dateMode: DateMode.parse(j['dateMode']?.toString()),
        dateLabel: j['dateLabel']?.toString() ?? 'Tarih',
        endDateLabel: j['endDateLabel']?.toString(),
        textFields: _list(j['textFields'], TextFieldDef.fromJson),
        filters: _list(j['filters'], FilterDef.fromJson),
        sections: _list(j['sections'], TemplateSection.fromJson),
        categories: _list(j['categories'], TemplateCategory.fromJson),
        items: _list(j['items'], CatalogItem.fromJson),
        isCustom: j['isCustom'] as bool? ?? false,
      );
}

enum ListKind {
  checklist,
  inventory;

  static ListKind parse(String? s) => ListKind.values
      .firstWhere((e) => e.name == s, orElse: () => ListKind.checklist);
}

enum DateMode {
  none,
  single,
  range;

  static DateMode parse(String? s) => DateMode.values
      .firstWhere((e) => e.name == s, orElse: () => DateMode.none);
}

class TextFieldDef {
  final String id;
  final String label;
  final String hint;
  const TextFieldDef({required this.id, required this.label, this.hint = ''});
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'hint': hint};
  factory TextFieldDef.fromJson(Map<String, dynamic> j) => TextFieldDef(
      id: j['id'] as String,
      label: j['label']?.toString() ?? '',
      hint: j['hint']?.toString() ?? '');
}

class FilterOption {
  final String id;
  final String label;
  final String? icon;
  const FilterOption({required this.id, required this.label, this.icon});
  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, if (icon != null) 'icon': icon};
  factory FilterOption.fromJson(Map<String, dynamic> j) => FilterOption(
      id: j['id'] as String,
      label: j['label']?.toString() ?? '',
      icon: j['icon']?.toString());
}

class FilterDef {
  final String id;
  final String label;
  final String question;
  final List<FilterOption> options;
  final String defaultOption;
  const FilterDef({
    required this.id,
    required this.label,
    required this.question,
    required this.options,
    required this.defaultOption,
  });
  FilterOption? option(String id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'question': question,
        'options': options.map((e) => e.toJson()).toList(),
        'default': defaultOption,
      };
  factory FilterDef.fromJson(Map<String, dynamic> j) => FilterDef(
        id: j['id'] as String,
        label: j['label']?.toString() ?? '',
        question: j['question']?.toString() ?? '',
        options: _list(j['options'], FilterOption.fromJson),
        defaultOption: j['default']?.toString() ?? '',
      );
}

class TemplateSection {
  final String id;
  final String name;
  final String icon;
  const TemplateSection(
      {required this.id, required this.name, required this.icon});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};
  factory TemplateSection.fromJson(Map<String, dynamic> j) => TemplateSection(
      id: j['id'] as String,
      name: j['name']?.toString() ?? '',
      icon: j['icon']?.toString() ?? 'list_alt');
}

class TemplateCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String section;
  const TemplateCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.section,
  });
  TemplateCategory copyWith(
          {String? name, String? icon, String? color, String? section}) =>
      TemplateCategory(
          id: id,
          name: name ?? this.name,
          icon: icon ?? this.icon,
          color: color ?? this.color,
          section: section ?? this.section);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'section': section
      };
  factory TemplateCategory.fromJson(Map<String, dynamic> j) => TemplateCategory(
        id: j['id'] as String,
        name: j['name']?.toString() ?? '',
        icon: j['icon']?.toString() ?? 'category',
        color: j['color']?.toString() ?? '#9E9E9E',
        section: j['section']?.toString() ?? 'main',
      );
}

/// Miktar kuralı: base + ceil(perDay * gün), max ile sınırlı, en az 1.
class QtyRule {
  final int base;
  final double perDay;
  final int? max;
  const QtyRule({this.base = 1, this.perDay = 0, this.max});

  int compute(int days) {
    var q = base + (perDay * days).ceil();
    if (max != null) q = math.min(q, max!);
    return math.max(q, 1);
  }

  Map<String, dynamic> toJson() => {'base': base, 'perDay': perDay, 'max': max};
  factory QtyRule.fromJson(Map<String, dynamic> j) => QtyRule(
        base: (j['base'] as num?)?.toInt() ?? 1,
        perDay: (j['perDay'] as num?)?.toDouble() ?? 0,
        max: (j['max'] as num?)?.toInt(),
      );
}

/// Koşul: VEYA ile bağlı bloklar; her blok içinde filtreler VE ile bağlı,
/// her filtre için seçenekler VEYA ile bağlı. Boş -> her zaman.
class Condition {
  final List<Map<String, List<String>>> blocks;
  const Condition(this.blocks);
  const Condition.always() : blocks = const [];

  bool get isAlways => blocks.isEmpty;

  bool matches(Map<String, String> answers) {
    if (blocks.isEmpty) return true;
    for (final block in blocks) {
      var ok = true;
      for (final e in block.entries) {
        final a = answers[e.key];
        if (a == null || !e.value.contains(a)) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  dynamic toJson() {
    if (blocks.isEmpty) return null;
    if (blocks.length == 1) return blocks.first;
    return blocks;
  }

  factory Condition.fromJson(dynamic raw) {
    if (raw == null) return const Condition.always();
    Map<String, List<String>> parseBlock(dynamic b) {
      if (b is! Map) return {};
      return {
        for (final e in b.entries)
          e.key.toString(): (e.value is List)
              ? (e.value as List).map((x) => x.toString()).toList()
              : <String>[]
      };
    }

    if (raw is List) {
      return Condition(raw.map(parseBlock).where((b) => b.isNotEmpty).toList());
    }
    final b = parseBlock(raw);
    return b.isEmpty ? const Condition.always() : Condition([b]);
  }
}

/// Katalogdaki (kütüphanedeki) kalem tanımı.
class CatalogItem {
  final String id;
  final String name;
  final String category;
  final Condition when;
  final QtyRule? qty;
  final String? unit;
  final bool essential;
  final String? note;
  final int? daysBefore;
  final bool isCustom;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    this.when = const Condition.always(),
    this.qty,
    this.unit,
    this.essential = false,
    this.note,
    this.daysBefore,
    this.isCustom = false,
  });

  CatalogItem copyWith({
    String? id,
    String? name,
    String? category,
    Condition? when,
    QtyRule? qty,
    bool clearQty = false,
    String? unit,
    bool? essential,
    String? note,
    int? daysBefore,
    bool? isCustom,
  }) =>
      CatalogItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        when: when ?? this.when,
        qty: clearQty ? null : (qty ?? this.qty),
        unit: unit ?? this.unit,
        essential: essential ?? this.essential,
        note: note ?? this.note,
        daysBefore: daysBefore ?? this.daysBefore,
        isCustom: isCustom ?? this.isCustom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        if (!when.isAlways) 'when': when.toJson(),
        if (qty != null) 'qty': qty!.toJson(),
        if (unit != null) 'unit': unit,
        if (essential) 'essential': true,
        if (note != null) 'note': note,
        if (daysBefore != null) 'daysBefore': daysBefore,
        if (isCustom) 'isCustom': true,
      };

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        id: j['id'] as String,
        name: j['name']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        when: Condition.fromJson(j['when']),
        qty: j['qty'] is Map
            ? QtyRule.fromJson(Map<String, dynamic>.from(j['qty'] as Map))
            : null,
        unit: j['unit']?.toString(),
        essential: j['essential'] as bool? ?? false,
        note: j['note']?.toString(),
        daysBefore: (j['daysBefore'] as num?)?.toInt(),
        isCustom: j['isCustom'] as bool? ?? false,
      );
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
  if (raw is! List) return [];
  final out = <T>[];
  for (final e in raw) {
    if (e is Map) {
      try {
        out.add(f(Map<String, dynamic>.from(e)));
      } catch (_) {
        // bozuk kaydı atla
      }
    }
  }
  return out;
}

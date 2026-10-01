import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../models/user_list.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
import 'list_detail_screen.dart';

/// Önerilen kalemleri onaylama (oluşturma modu) veya katalogdan ekleme (ekleme modu).
class SelectionScreen extends StatefulWidget {
  const SelectionScreen.create({
    super.key,
    required this.template,
    required this.name,
    required this.fields,
    required this.answers,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.suggested,
  }) : existing = null;

  const SelectionScreen.add(
      {super.key, required this.template, required this.existing})
      : name = '',
        fields = const {},
        answers = const {},
        startDate = null,
        endDate = null,
        days = 1,
        suggested = const [];

  final ListTemplate template;
  final String name;
  final Map<String, String> fields;
  final Map<String, String> answers;
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final List<ListItem> suggested;
  final UserList? existing;

  bool get isAddMode => existing != null;

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  /// Görüntülenen tüm adaylar (catalogId -> ListItem)
  late final Map<String, ListItem> _candidates;
  late final Set<String> _selected; // ListItem.id
  late final Set<String> _suggestedIds;
  bool _showAll = false;
  String _query = '';

  ListTemplate get t => widget.template;
  List<TemplateSection> get sections =>
      widget.isAddMode ? widget.existing!.sections : t.sections;
  List<TemplateCategory> get categories =>
      widget.isAddMode ? widget.existing!.categories : t.categories;

  @override
  void initState() {
    super.initState();
    final lists = context.read<ListsProvider>();
    final catalog = context.read<CatalogProvider>();
    _candidates = {};
    _suggestedIds = {};
    if (widget.isAddMode) {
      final inList = widget.existing!.items
          .map((i) => i.catalogId)
          .whereType<String>()
          .toSet();
      for (final c in t.items) {
        if (inList.contains(c.id)) continue;
        final li = lists.itemFromCatalog(widget.existing!, c);
        _candidates[c.id] = li;
        // Ekleme modunda: cevaplara uyan ve pasif olmayanlar "önerilen" sayılır
        if (c.when.matches(widget.existing!.answers) &&
            !catalog.isDisabled(t.id, c.id)) {
          _suggestedIds.add(li.id);
        }
      }
      _selected = {};
      _showAll = true;
    } else {
      for (final s in widget.suggested) {
        _candidates[s.catalogId ?? s.id] = s;
        _suggestedIds.add(s.id);
      }
      // Katalogdaki geri kalanlar (koşula uymayan / pasif) — "tümünü göster" için
      for (final c in t.items) {
        if (_candidates.containsKey(c.id)) continue;
        final li = ListItem(
          id: 'x_${c.id}',
          catalogId: c.id,
          name: c.name,
          categoryId: c.category,
          quantity: c.qty?.compute(widget.days),
          unit: c.unit,
          note: c.note,
          isEssential: c.essential,
        );
        _candidates[c.id] = li;
      }
      // preselect=false (market): öneriler görünür ama hiçbiri seçili gelmez
      _selected = t.preselect ? _suggestedIds.toSet() : <String>{};
    }
  }

  /// Öneri ekranında adet düzenleme: adayı yeni miktarla değiştirir ve seçer.
  void _changeQty(ListItem i, int delta) {
    final q = ((i.quantity ?? 1) + delta).clamp(1, 999);
    final key = i.catalogId ?? i.id;
    setState(() {
      _candidates[key] = i.copyWith(quantity: q);
      _selected.add(i.id);
    });
  }

  List<ListItem> _visibleItemsOf(String categoryId) {
    final q = normalizeTr(_query.trim());
    return _candidates.values.where((i) {
      if (i.categoryId != categoryId) return false;
      if (!_showAll && !_suggestedIds.contains(i.id)) return false;
      if (q.isNotEmpty && !normalizeTr(i.name).contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(t.color);
    final hasTabs = sections.length > 1;
    final body = hasTabs
        ? TabBarView(children: [for (final s in sections) _sectionList(s.id)])
        : _sectionList(sections.first.id);

    final scaffold = Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isAddMode ? 'Katalogdan ekle' : 'Listeni gözden geçir'),
        actions: [
          if (!widget.isAddMode)
            IconButton(
              tooltip: _showAll ? 'Sadece önerilenler' : 'Tüm kataloğu göster',
              icon: Icon(
                  _showAll ? Icons.filter_alt : Icons.filter_alt_off_outlined),
              onPressed: () => setState(() => _showAll = !_showAll),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(hasTabs ? 104 : 56),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _query = '')),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (hasTabs)
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    for (final s in sections)
                      Tab(text: '${s.name} (${_countSelectedInSection(s.id)})'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selected.isEmpty && !t.preselect && !widget.isAddMode
                      ? 'İstediklerini işaretle (boş da oluşturabilirsin)'
                      : '${_selected.length} kalem seçili',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: color, foregroundColor: Colors.white),
                onPressed:
                    _selected.isEmpty && widget.isAddMode ? null : _confirm,
                icon: Icon(widget.isAddMode ? Icons.playlist_add : Icons.check),
                label: Text(widget.isAddMode ? 'Ekle' : 'Listeyi Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
    return hasTabs
        ? DefaultTabController(length: sections.length, child: scaffold)
        : scaffold;
  }

  int _countSelectedInSection(String sectionId) {
    final catIds = categories
        .where((c) => c.section == sectionId)
        .map((c) => c.id)
        .toSet();
    return _candidates.values
        .where((i) => catIds.contains(i.categoryId) && _selected.contains(i.id))
        .length;
  }

  Widget _sectionList(String sectionId) {
    final cats = categories.where((c) => c.section == sectionId).toList();
    final children = <Widget>[];
    for (final c in cats) {
      final items = _visibleItemsOf(c.id);
      if (items.isEmpty) continue;
      final selCount = items.where((i) => _selected.contains(i.id)).length;
      final allSel = selCount == items.length;
      children.add(CategoryHeader(
        name: c.name,
        icon: c.icon,
        colorHex: c.color,
        count: selCount,
        total: items.length,
        onTap: () => setState(() {
          for (final i in items) {
            allSel ? _selected.remove(i.id) : _selected.add(i.id);
          }
        }),
        trailing: Icon(allSel ? Icons.remove_done : Icons.done_all,
            size: 20, color: colorFromHex(c.color)),
      ));
      for (final i in items) {
        final suggested = _suggestedIds.contains(i.id);
        children.add(CheckboxListTile(
          value: _selected.contains(i.id),
          onChanged: (v) => setState(
              () => v == true ? _selected.add(i.id) : _selected.remove(i.id)),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          title: Row(
            children: [
              Expanded(
                child: Text(i.name,
                    style: TextStyle(
                        color: suggested
                            ? null
                            : Theme.of(context).colorScheme.outline)),
              ),
              if (i.isEssential)
                const Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ),
          secondary: i.quantity == null
              ? null
              : _QtyStepper(
                  label: i.quantityLabel,
                  canDecrement: i.quantity! > 1,
                  onChanged: (d) => _changeQty(i, d),
                ),
        ));
      }
    }
    if (children.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: _query.isNotEmpty
            ? 'Eşleşen kalem yok'
            : 'Bu bölümde önerilen kalem yok',
        subtitle: widget.isAddMode
            ? null
            : 'Sağ üstteki filtre simgesiyle tüm kataloğu görebilirsin.',
      );
    }
    return ListView(
        padding: const EdgeInsets.only(bottom: 24), children: children);
  }

  Future<void> _confirm() async {
    final lists = context.read<ListsProvider>();
    final chosen =
        _candidates.values.where((i) => _selected.contains(i.id)).toList();
    if (widget.isAddMode) {
      final n = await lists.addItems(widget.existing!.id, chosen);
      if (!mounted) return;
      Navigator.pop(context, n);
      return;
    }
    // Oluşturma: 'x_' geçici id'li kalemlere gerçek id ver
    final lists0 = context.read<ListsProvider>();
    final finalItems = <ListItem>[];
    for (final i in chosen) {
      if (i.id.startsWith('x_')) {
        final c = t.items.firstWhereOrNull((x) => x.id == i.catalogId);
        if (c != null) {
          finalItems.add(ListItem(
            id: const Uuid().v4(),
            catalogId: c.id,
            name: c.name,
            categoryId: c.category,
            // Kullanıcı ekranda adedi değiştirdiyse onu kullan
            quantity: i.quantity ?? c.qty?.compute(widget.days),
            unit: c.unit,
            note: c.note,
            isEssential: c.essential,
          ));
        }
      } else {
        finalItems.add(i);
      }
    }
    final created = await lists0.createList(
      template: t,
      name: widget.name,
      fields: widget.fields,
      answers: widget.answers,
      startDate: widget.startDate,
      endDate: widget.endDate,
      items: finalItems,
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ListDetailScreen(listId: created.id)));
  }
}

/// Öneri ekranında satır sonundaki − adet + kontrolü.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper(
      {required this.label,
      required this.canDecrement,
      required this.onChanged});
  final String label;
  final bool canDecrement;
  final void Function(int delta) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.remove, size: 18),
          onPressed: canDecrement ? () => onChanged(-1) : null,
          tooltip: 'Azalt',
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8)),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => onChanged(1),
          tooltip: 'Artır',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_icons.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../widgets/common.dart';

/// Bir şablonun kataloğunu yönetme: kalemleri pasife alma, özel kalem ekleme/silme.
class ManageCatalogScreen extends StatefulWidget {
  const ManageCatalogScreen({super.key, required this.templateId});
  final String templateId;

  @override
  State<ManageCatalogScreen> createState() => _ManageCatalogScreenState();
}

class _ManageCatalogScreenState extends State<ManageCatalogScreen> {
  String _query = '';
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final t = catalog.templateById(widget.templateId);
    if (t == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const EmptyView(
              icon: Icons.error_outline, title: 'Şablon bulunamadı'));
    }
    final q = normalizeTr(_query.trim());
    final color = colorFromHex(t.color);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.name} kataloğu'),
        actions: [
          if (catalog.disabledCount(t.id) > 0)
            IconButton(
              tooltip: 'Pasifleri geri aç',
              icon: const Icon(Icons.restore),
              onPressed: () async {
                if (await confirm(context,
                    title: 'Pasifleri geri aç',
                    message:
                        '${catalog.disabledCount(t.id)} pasif kalem yeniden önerilmeye başlanacak.',
                    okLabel: 'Geri aç',
                    destructive: false)) {
                  await catalog.resetDisabled(t.id);
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Kalem ara…',
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEdit(t),
        icon: const Icon(Icons.add),
        label: const Text('Kalem ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          for (final s in t.sections) ...[
            if (t.hasSections)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(children: [
                  Icon(AppIcons.get(s.icon), size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(upperTr(s.name),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1,
                          fontSize: 12)),
                ]),
              ),
            for (final c in t.categoriesOf(s.id))
              _categoryBlock(t, c, q, catalog),
          ],
        ],
      ),
    );
  }

  Widget _categoryBlock(
      ListTemplate t, TemplateCategory c, String q, CatalogProvider catalog) {
    var items = t.items.where((i) => i.category == c.id).toList();
    if (q.isNotEmpty) {
      items = items.where((i) => normalizeTr(i.name).contains(q)).toList();
    }
    if (items.isEmpty && q.isNotEmpty) return const SizedBox.shrink();
    final open = q.isNotEmpty || _expanded.contains(c.id);
    final active = items.where((i) => !catalog.isDisabled(t.id, i.id)).length;
    return Column(
      children: [
        CategoryHeader(
          name: c.name,
          icon: c.icon,
          colorHex: c.color,
          count: active,
          total: items.length,
          trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(
              () => open ? _expanded.remove(c.id) : _expanded.add(c.id)),
        ),
        if (open)
          for (final i in items)
            SwitchListTile(
              dense: true,
              value: !catalog.isDisabled(t.id, i.id),
              onChanged: (v) => catalog.setItemEnabled(t.id, i.id, v),
              title: Row(children: [
                Expanded(child: Text(i.name)),
                if (i.essential)
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                if (i.isCustom)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _addOrEdit(t, existing: i),
                  ),
              ]),
              subtitle: _subtitle(t, i),
              secondary: i.isCustom
                  ? IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                        if (await confirm(context,
                            title: 'Kalemi sil',
                            message: '"${i.name}" katalogdan silinecek.')) {
                          await catalog.deleteCustomItem(t.id, i.id);
                        }
                      },
                    )
                  : null,
            ),
        if (open && items.isEmpty)
          const Padding(
              padding: EdgeInsets.fromLTRB(56, 4, 16, 12),
              child: Text('Bu kategoride kalem yok',
                  style: TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget? _subtitle(ListTemplate t, CatalogItem i) {
    final parts = <String>[];
    if (!i.when.isAlways) {
      for (final block in i.when.blocks) {
        final bp = <String>[];
        for (final e in block.entries) {
          final f = t.filters.firstWhereOrNull((f) => f.id == e.key);
          if (f == null) continue;
          bp.add(e.value.map((v) => f.option(v)?.label ?? v).join('/'));
        }
        if (bp.isNotEmpty) parts.add(bp.join(' + '));
      }
    }
    if (i.qty != null) {
      parts.add(i.qty!.perDay > 0
          ? 'gün başına ${i.qty!.perDay}'
          : '${i.qty!.base} ${i.unit ?? ''}'.trim());
    }
    if (i.daysBefore != null) parts.add('${i.daysBefore} gün önce');
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '),
        style: const TextStyle(fontSize: 11),
        maxLines: 2,
        overflow: TextOverflow.ellipsis);
  }

  Future<void> _addOrEdit(ListTemplate t, {CatalogItem? existing}) async {
    final catalog = context.read<CatalogProvider>();
    final r = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CatalogItemForm(template: t, existing: existing),
    );
    if (r == null) return;
    if (existing == null) {
      await catalog.addCustomItem(t.id, r);
    } else {
      await catalog.updateCustomItem(t.id, r);
    }
  }
}

/// Özel katalog kalemi formu: ad, kategori, koşullar (filtre seçenekleri), miktar, önem.
class _CatalogItemForm extends StatefulWidget {
  const _CatalogItemForm({required this.template, this.existing});
  final ListTemplate template;
  final CatalogItem? existing;

  @override
  State<_CatalogItemForm> createState() => _CatalogItemFormState();
}

class _CatalogItemFormState extends State<_CatalogItemForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _qty =
      TextEditingController(text: widget.existing?.qty?.base.toString() ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.existing?.unit ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');
  late String _category;
  late bool _essential = widget.existing?.essential ?? false;

  /// filtre id -> seçili seçenekler (boş = hepsi)
  late final Map<String, Set<String>> _when;

  ListTemplate get t => widget.template;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ??
        (t.categories.isNotEmpty ? t.categories.first.id : 'other');
    if (t.categoryById(_category) == null && t.categories.isNotEmpty) {
      _category = t.categories.first.id;
    }
    _when = {for (final f in t.filters) f.id: <String>{}};
    final blocks = widget.existing?.when.blocks ?? const [];
    if (blocks.isNotEmpty) {
      for (final e in blocks.first.entries) {
        _when[e.key]?.addAll(e.value);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                widget.existing == null
                    ? 'Kataloğa kalem ekle'
                    : 'Kalemi düzenle',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Bu kalem bundan sonra oluşturulan ${t.name} listelerinde önerilir.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Ad')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final s in t.sections)
                  for (final c in t.categoriesOf(s.id))
                    DropdownMenuItem(
                        value: c.id,
                        child: Text(
                            t.hasSections ? '${s.name} › ${c.name}' : c.name,
                            overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Miktar', hintText: 'boş = yok'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(labelText: 'Birim'))),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Not / ipucu')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Önemli (yıldızlı)'),
              value: _essential,
              onChanged: (v) => setState(() => _essential = v),
            ),
            if (t.filters.isNotEmpty) ...[
              const Divider(),
              Text('Ne zaman önerilsin?',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('Hiçbir şey seçmezsen her zaman önerilir.',
                  style: Theme.of(context).textTheme.bodySmall),
              for (final f in t.filters) ...[
                const SizedBox(height: 8),
                Text(f.label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final o in f.options)
                      FilterChip(
                        label: Text(o.label),
                        selected: _when[f.id]!.contains(o.id),
                        onSelected: (v) => setState(() => v
                            ? _when[f.id]!.add(o.id)
                            : _when[f.id]!.remove(o.id)),
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Spacer(),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Kaydet')),
            ]),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Ad boş olamaz');
      return;
    }
    final block = <String, List<String>>{
      for (final e in _when.entries)
        if (e.value.isNotEmpty) e.key: e.value.toList(),
    };
    final qty = int.tryParse(_qty.text.trim());
    final unit = _unit.text.trim();
    final note = _note.text.trim();
    Navigator.pop(
      context,
      CatalogItem(
        id: widget.existing?.id ?? 'tmp',
        name: name,
        category: _category,
        when: block.isEmpty ? const Condition.always() : Condition([block]),
        qty: qty == null ? null : QtyRule(base: qty),
        unit: unit.isEmpty ? null : unit,
        essential: _essential,
        note: note.isEmpty ? null : note,
        isCustom: true,
      ),
    );
  }
}

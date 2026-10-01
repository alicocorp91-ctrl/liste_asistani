import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_icons.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../widgets/common.dart';
import 'manage_catalog_screen.dart';

const _palette = [
  '#1E88E5',
  '#00897B',
  '#43A047',
  '#7E57C2',
  '#FB8C00',
  '#D81B60',
  '#3949AB',
  '#6D4C41',
  '#E53935',
  '#00ACC1',
  '#F4511E',
  '#8E24AA',
  '#546E7A',
  '#C0CA33',
  '#5E35B1',
  '#039BE5',
];

/// Kullanıcı tanımlı liste tipi oluşturma / düzenleme.
class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key, this.existing});
  final ListTemplate? existing;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: widget.existing?.description ?? '');
  late String _icon = widget.existing?.icon ?? 'list_alt';
  late String _color = widget.existing?.color ?? _palette.first;
  late DateMode _dateMode = widget.existing?.dateMode ?? DateMode.none;
  late bool _inventory = widget.existing?.isInventory ?? false;
  late final TextEditingController _dateLabel =
      TextEditingController(text: widget.existing?.dateLabel ?? 'Tarih');
  late List<TemplateCategory> _cats =
      List.of(widget.existing?.categories ?? const []);
  int _seq = 0;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_cats.isEmpty) {
      _cats = [
        const TemplateCategory(
            id: 'general',
            name: 'Genel',
            icon: 'checklist',
            color: '#607D8B',
            section: 'main'),
      ];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _dateLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(_color);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Liste tipini düzenle' : 'Yeni liste tipi'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Tipi sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context,
                    title: 'Liste tipini sil',
                    message:
                        '"${widget.existing!.name}" tipi ve katalog kalemleri silinecek. Bu tipten oluşturulmuş listeler etkilenmez.')) {
                  if (!context.mounted) return;
                  await context
                      .read<CatalogProvider>()
                      .deleteCustomTemplate(widget.existing!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              IconBadge(icon: _icon, color: c, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Tip adı',
                      hintText: 'Spor çantası, Düğün, Okul…'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: 'Açıklama (isteğe bağlı)'),
          ),
          const SizedBox(height: 20),
          const _Label('Renk'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _palette)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _color = p),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorFromHex(p),
                      shape: BoxShape.circle,
                      border: _color == p
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _Label('İkon'),
          SizedBox(
            height: 160,
            child: GridView.count(
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final n in AppIcons.pickerNames)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _icon = n),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _icon == n ? c.withValues(alpha: 0.2) : null,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            _icon == n ? Border.all(color: c, width: 2) : null,
                      ),
                      child: Icon(AppIcons.get(n),
                          size: 22, color: _icon == n ? c : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Label('Liste türü'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _inventory,
            onChanged: (v) => setState(() => _inventory = v),
            title: const Text('Stok takibi (malzeme listesi)'),
            subtitle: const Text(
                'Her kalemde gereken + stokta miktarı tutulur; eksikler vurgulanır '
                've markete aktarılabilir. Piknik, kamp, market gibi listeler için.'),
            secondary:
                Icon(_inventory ? Icons.inventory_2_outlined : Icons.checklist),
          ),
          const SizedBox(height: 12),
          const _Label('Tarih'),
          SegmentedButton<DateMode>(
            segments: const [
              ButtonSegment(value: DateMode.none, label: Text('Yok')),
              ButtonSegment(value: DateMode.single, label: Text('Tek tarih')),
              ButtonSegment(value: DateMode.range, label: Text('Aralık')),
            ],
            selected: {_dateMode},
            onSelectionChanged: (s) => setState(() => _dateMode = s.first),
          ),
          if (_dateMode != DateMode.none) ...[
            const SizedBox(height: 10),
            TextField(
                controller: _dateLabel,
                decoration: const InputDecoration(
                    labelText: 'Tarih etiketi', hintText: 'Etkinlik günü')),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: _Label('Kategoriler')),
              TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle')),
            ],
          ),
          for (var i = 0; i < _cats.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: IconBadge(
                    icon: _cats[i].icon,
                    color: colorFromHex(_cats[i].color),
                    size: 34),
                title: Text(_cats[i].name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editCategory(i)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: _cats.length <= 1
                          ? null
                          : () => setState(() => _cats.removeAt(i)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            isEdit
                ? 'Kalemleri "Ayarlar › Kataloglar" bölümünden yönetebilirsin.'
                : 'Kaydettikten sonra kataloğa kalem ekleyebilirsin; her yeni listede bu kalemler önerilir.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: c,
                foregroundColor: Colors.white),
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(isEdit ? 'Kaydet' : 'Oluştur ve kalem ekle'),
          ),
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final r = await _categoryDialog();
    if (r != null) setState(() => _cats.add(r));
  }

  Future<void> _editCategory(int i) async {
    final r = await _categoryDialog(existing: _cats[i]);
    if (r != null) setState(() => _cats[i] = r);
  }

  Future<TemplateCategory?> _categoryDialog(
      {TemplateCategory? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    var icon = existing?.icon ?? 'label';
    var color = existing?.color ?? _palette[(_cats.length) % _palette.length];
    final r = await showDialog<TemplateCategory>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Kategori ekle' : 'Kategori düzenle'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Ad')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in _palette.take(12))
                      InkWell(
                        onTap: () => setS(() => color = p),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colorFromHex(p),
                            shape: BoxShape.circle,
                            border: color == p
                                ? Border.all(
                                    color: Theme.of(ctx).colorScheme.onSurface,
                                    width: 2)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: GridView.count(
                    crossAxisCount: 7,
                    children: [
                      for (final n in AppIcons.pickerNames)
                        InkWell(
                          onTap: () => setS(() => icon = n),
                          child: Icon(AppIcons.get(n),
                              size: 20,
                              color: icon == n ? colorFromHex(color) : null),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  TemplateCategory(
                    id: existing?.id ??
                        'cat_${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
                    name: name.text.trim(),
                    icon: icon,
                    color: color,
                    section: 'main',
                  ),
                );
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
    return r;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      showSnack(context, 'Tip adı en az 2 karakter olmalı');
      return;
    }
    final catalog = context.read<CatalogProvider>();
    final t = ListTemplate(
      id: widget.existing?.id ?? 'tmp',
      name: name,
      description: _desc.text.trim(),
      icon: _icon,
      color: _color,
      kind: _inventory ? ListKind.inventory : ListKind.checklist,
      dateMode: _dateMode,
      dateLabel:
          _dateLabel.text.trim().isEmpty ? 'Tarih' : _dateLabel.text.trim(),
      endDateLabel: _dateMode == DateMode.range ? 'Bitiş' : null,
      sections: const [
        TemplateSection(id: 'main', name: 'Liste', icon: 'checklist')
      ],
      categories: _cats,
      isCustom: true,
    );
    if (isEdit) {
      await catalog.updateCustomTemplate(t);
      if (mounted) Navigator.pop(context);
      return;
    }
    final created = await catalog.addCustomTemplate(t);
    if (!mounted) return;
    // Katalog ekranına geç; oradan dönünce oluşturulan şablonu geri ver
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ManageCatalogScreen(templateId: created.id)));
    if (mounted) Navigator.pop(context, catalog.templateById(created.id));
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

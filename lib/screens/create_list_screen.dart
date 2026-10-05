import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_icons.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'selection_screen.dart';

/// Şablona göre dinamik oluşturma formu: ad, metin alanları, filtreler, tarihler.
class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key, required this.template});
  final ListTemplate template;

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final Map<String, TextEditingController> _fieldCtrls = {};
  late Map<String, String> _answers;
  DateTime? _start;
  DateTime? _end;
  bool _nameTouched = false;

  ListTemplate get t => widget.template;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: t.name);
    for (final f in t.textFields) {
      _fieldCtrls[f.id] = TextEditingController();
    }
    _answers = t.defaultAnswers();
    if (t.dateMode != DateMode.none) {
      final now = DateTime.now();
      _start =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
      if (t.dateMode == DateMode.range) {
        _end = _start!.add(const Duration(days: 3));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Kullanıcı adı elle değiştirmediyse "Antalya Seyahati" gibi otomatik ad üret
  void _autoName() {
    if (_nameTouched) return;
    final to = _fieldCtrls['to']?.text.trim() ?? '';
    final place = _fieldCtrls['place']?.text.trim() ?? '';
    final base = to.isNotEmpty ? to : place;
    if (base.isNotEmpty) {
      _name.text = '$base ${t.name}${t.id == 'seyahat' ? 'i' : ''}';
    } else {
      _name.text = t.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(t.color);
    final scheme = Theme.of(context).colorScheme;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('Yeni ${t.name}')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
            children: [
              // Başlık kartı
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: HeroBackdrop(
                  color: c,
                  templateId: t.id,
                  icon: t.icon,
                  artOpacity: 0.9,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 120, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 6),
                        Text(t.description,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Pill(
                            label: '${t.items.length} kalemlik katalog',
                            icon: Icons.auto_awesome,
                            color: Colors.black26,
                            filled: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _FormCard(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        labelText: 'Liste adı',
                        prefixIcon: Icon(Icons.edit_outlined)),
                    onChanged: (_) => _nameTouched = true,
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'En az 2 karakter'
                        : null,
                  ),
                  for (final f in t.textFields) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldCtrls[f.id],
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                          labelText: f.label,
                          hintText: f.hint,
                          prefixIcon: const Icon(Icons.place_outlined)),
                      onChanged: (_) => setState(_autoName),
                    ),
                  ],
                ],
              ),
              if (t.dateMode != DateMode.none) ...[
                const SizedBox(height: 12),
                _FormCard(
                  title:
                      t.dateMode == DateMode.range ? 'Tarihler' : t.dateLabel,
                  icon: Icons.event_rounded,
                  color: c,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: t.dateLabel,
                            value: _start,
                            color: c,
                            onPick: (d) => setState(() {
                              _start = d;
                              if (_end != null && _end!.isBefore(d)) _end = d;
                            }),
                            onClear: () => setState(() {
                              _start = null;
                              _end = null;
                            }),
                          ),
                        ),
                        if (t.dateMode == DateMode.range) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateButton(
                              label: t.endDateLabel ?? 'Bitiş',
                              value: _end,
                              color: c,
                              firstDate: _start,
                              onPick: (d) => setState(() => _end = d),
                              onClear: () => setState(() => _end = null),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (t.dateMode == DateMode.range &&
                        _start != null &&
                        _end != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 2),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  '${dateOnly(_end!).difference(dateOnly(_start!)).inDays + 1} gün — miktarlar buna göre hesaplanır',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: scheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              for (final f in t.filters) ...[
                const SizedBox(height: 12),
                _FormCard(
                  title: f.question.isNotEmpty ? f.question : f.label,
                  icon: Icons.help_outline_rounded,
                  color: c,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in f.options)
                          _OptionPill(
                            label: o.label,
                            icon: o.icon != null ? AppIcons.get(o.icon) : null,
                            selected: _answers[f.id] == o.id,
                            color: c,
                            onTap: () => setState(() => _answers[f.id] = o.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: GradientButton(
              label: 'Listeyi Öner',
              icon: Icons.auto_awesome,
              color: c,
              onPressed: _submit,
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (t.dateMode == DateMode.range &&
        _start != null &&
        _end != null &&
        _end!.isBefore(_start!)) {
      showSnack(context, 'Bitiş tarihi başlangıçtan önce olamaz.');
      return;
    }
    final catalog = context.read<CatalogProvider>();
    final lists = context.read<ListsProvider>();
    final days = (_start != null && _end != null)
        ? dateOnly(_end!).difference(dateOnly(_start!)).inDays + 1
        : 1;
    final suggested = lists.suggestItems(
      template: t,
      answers: _answers,
      days: days,
      isDisabled: (id) => catalog.isDisabled(t.id, id),
      eventDate: _start,
    );
    final fields = {
      for (final e in _fieldCtrls.entries) e.key: e.value.text.trim()
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionScreen.create(
          template: t,
          name: _name.text.trim(),
          fields: fields,
          answers: _answers,
          startDate: _start,
          endDate: _end,
          days: days,
          suggested: suggested,
        ),
      ),
    );
  }
}

/// Form grubu kartı (başlık + içerik)
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children, this.title, this.icon, this.color});
  final List<Widget> children;
  final String? title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: (color ?? scheme.primary).withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 17, color: color ?? scheme.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title!,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Seçenek hapı (ChoiceChip yerine): seçiliyken şablon rengiyle dolu
class _OptionPill extends StatelessWidget {
  const _OptionPill(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap,
      this.icon});
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? Colors.white : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? color.gradient : null,
            color: selected
                ? null
                : scheme.surfaceContainerHighest.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: .3),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.label,
      required this.value,
      required this.onPick,
      required this.onClear,
      required this.color,
      this.firstDate});
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final Color color;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate ?? now,
          firstDate: firstDate ?? DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('tr', 'TR'),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  Text(value == null ? 'Seç' : fmtDate(value!),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (value != null)
              InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: scheme.onSurfaceVariant))),
          ],
        ),
      ),
    );
  }
}

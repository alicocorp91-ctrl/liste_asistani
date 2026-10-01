import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_icons.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text('Yeni ${t.name}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Row(
              children: [
                IconBadge(icon: t.icon, color: c, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            if (t.dateMode != DateMode.none) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                  t.dateMode == DateMode.range ? 'Tarihler' : t.dateLabel),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: t.dateLabel,
                      value: _start,
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
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                      '${dateOnly(_end!).difference(dateOnly(_start!)).inDays + 1} gün — miktarlar buna göre hesaplanır',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ),
            ],
            for (final f in t.filters) ...[
              const SizedBox(height: 20),
              _SectionLabel(f.question.isNotEmpty ? f.question : f.label),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in f.options)
                    ChoiceChip(
                      avatar: o.icon != null
                          ? Icon(AppIcons.get(o.icon), size: 18)
                          : null,
                      label: Text(o.label),
                      selected: _answers[f.id] == o.id,
                      onSelected: (_) => setState(() => _answers[f.id] = o.id),
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
          child: FilledButton.icon(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _submit,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Listeyi Öner'),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.label,
      required this.value,
      required this.onPick,
      required this.onClear,
      this.firstDate});
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
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
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(value == null ? 'Seç' : fmtDate(value!),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (value != null)
            InkWell(
                onTap: onClear,
                child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16))),
        ],
      ),
    );
  }
}

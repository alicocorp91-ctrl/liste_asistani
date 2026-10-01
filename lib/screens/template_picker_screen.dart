import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../widgets/common.dart';
import 'create_list_screen.dart';
import 'template_editor_screen.dart';

/// Yeni liste için şablon (liste tipi) seçimi.
class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final templates = catalog.templates;
    final builtIn = templates.where((t) => !t.isCustom).toList();
    final custom = templates.where((t) => t.isCustom).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ne listesi hazırlıyoruz?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [for (final t in builtIn) _TemplateTile(template: t)],
          ),
          if (custom.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text('Kendi liste tiplerim',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [for (final t in custom) _TemplateTile(template: t)],
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final created = await Navigator.push<ListTemplate>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TemplateEditorScreen()));
              if (created != null && context.mounted) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CreateListScreen(template: created)));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Yeni liste tipi oluştur'),
          ),
          const SizedBox(height: 8),
          Text(
            'Kendi tipini oluştur: kategori ve kalemlerini sen belirle (örn. "Spor çantası", "Düğün", "Okul").',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template});
  final ListTemplate template;

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(template.color);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => CreateListScreen(template: template))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: template.icon, color: c, size: 44),
                  const Spacer(),
                  if (template.isInventory)
                    Tooltip(
                      message: 'Stok takibi',
                      child: Icon(Icons.inventory_2_outlined,
                          size: 18, color: scheme.outline),
                    ),
                ],
              ),
              const Spacer(),
              Text(template.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                template.isCustom
                    ? '${template.items.length} kalem · ${template.categories.length} kategori'
                    : template.description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

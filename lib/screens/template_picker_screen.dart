import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_icons.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../widgets/ui.dart';
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
    final scheme = Theme.of(context).colorScheme;
    var idx = 0;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Ne listesi hazırlıyoruz?')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              'Bir şablon seç; sorulara göre sana özel öneri listesi hazırlansın.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                for (final t in builtIn)
                  FadeSlideIn(index: idx++, child: _TemplateTile(template: t)),
              ],
            ),
            if (custom.isNotEmpty) ...[
              const SectionTitle('Kendi liste tiplerim',
                  padding: EdgeInsets.fromLTRB(4, 22, 4, 10)),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
                children: [
                  for (final t in custom)
                    FadeSlideIn(
                        index: idx++, child: _TemplateTile(template: t)),
                ],
              ),
            ],
            const SizedBox(height: 18),
            FadeSlideIn(
              index: idx,
              child: SoftCard(
                margin: EdgeInsets.zero,
                onTap: () async {
                  final created = await Navigator.push<ListTemplate>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TemplateEditorScreen()));
                  if (created != null && context.mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CreateListScreen(template: created)));
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      child: Icon(Icons.add_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yeni liste tipi oluştur',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Kategori ve kalemlerini sen belirle: "Spor çantası", "Düğün", "Okul"…',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final art = artAssetFor(template.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: c.gradient,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: c.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateListScreen(template: template))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (art != null)
                  Image.asset(art,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                // Alt gradyan: yazı okunurluğu
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.35, 1],
                        colors: [
                          Colors.transparent,
                          c.darken(.28).withValues(alpha: 0.92)
                        ],
                      ),
                    ),
                  ),
                ),
                if (art == null)
                  Positioned(
                    right: -16,
                    top: -10,
                    child: Icon(AppIcons.get(template.icon),
                        size: 120, color: Colors.white.withValues(alpha: 0.18)),
                  ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Row(
                    children: [
                      if (template.isInventory)
                        const Pill(
                            label: 'Stok',
                            icon: Icons.inventory_2_outlined,
                            color: Colors.black38,
                            filled: true),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 3),
                      Text(
                        template.isCustom
                            ? '${template.items.length} kalem · ${template.categories.length} kategori'
                            : template.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils.dart';
import '../data/storage.dart';
import '../models/template.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';
import 'manage_catalog_screen.dart';
import 'template_editor_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final catalog = context.watch<CatalogProvider>();
    final templates = catalog.templates;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Title('Görünüm'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Sistem')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Açık')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Koyu')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final a in AppAccent.values)
                  Tooltip(
                    message: a.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => settings.setAccent(a),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: a.seed,
                          shape: BoxShape.circle,
                          border: settings.accent == a
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  width: 3)
                              : null,
                        ),
                        child: settings.accent == a
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const _Title('Kataloglar'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
                'Her liste tipinin kalemlerini yönet: istemediklerini pasife al, kendi kalemlerini ekle.',
                style: TextStyle(fontSize: 12)),
          ),
          for (final t in templates)
            ListTile(
              leading: IconBadge(
                  icon: t.icon, color: colorFromHex(t.color), size: 36),
              title: Text(t.name),
              subtitle: Text(
                '${t.items.length} kalem · ${t.categories.length} kategori'
                '${catalog.disabledCount(t.id) > 0 ? ' · ${catalog.disabledCount(t.id)} pasif' : ''}'
                '${t.isCustom ? ' · özel tip' : ''}',
              ),
              trailing: t.isCustom
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Tipi düzenle',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TemplateEditorScreen(existing: t))),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ManageCatalogScreen(templateId: t.id))),
            ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Yeni liste tipi oluştur'),
            onTap: () => Navigator.push<ListTemplate>(
                context,
                MaterialPageRoute(
                    builder: (_) => const TemplateEditorScreen())),
          ),
          const _Title('Yedekleme'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Verileri dışa aktar'),
            subtitle: const Text('Tüm listeler, özel tipler ve ayarlar (JSON)'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Verileri içe aktar'),
            subtitle:
                const Text('Daha önce dışa aktarılmış JSON metnini yapıştır'),
            onTap: () => _import(context),
          ),
          const _Title('Hakkında'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Liste Asistanı'),
            subtitle: Text('Sürüm 2.0.0 · Seyahat Asistanı\'nın devamı'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final storage = await Storage.open();
    final json = const JsonEncoder.withIndent(' ').convert(storage.exportAll());
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Paylaş (dosya olarak gönder)'),
              onTap: () async {
                Navigator.pop(ctx);
                await SharePlus.instance.share(
                    ShareParams(text: json, subject: 'Liste Asistanı yedeği'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Panoya kopyala'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  showSnack(context,
                      'Yedek panoya kopyalandı (${(json.length / 1024).toStringAsFixed(0)} KB)');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İçe aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Mevcut verilerin üzerine yazılır. Yedek JSON metnini yapıştır:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
                controller: ctrl,
                maxLines: 6,
                decoration:
                    const InputDecoration(hintText: '{ "lists.index": ... }')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('İçe aktar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final data = jsonDecode(ctrl.text) as Map<String, dynamic>;
      final storage = await Storage.open();
      await storage.importAll(data);
      if (!context.mounted) return;
      await context.read<CatalogProvider>().reload();
      if (!context.mounted) return;
      await context.read<ListsProvider>().reload();
      if (context.mounted) showSnack(context, 'Veriler içe aktarıldı');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Geçersiz yedek: $e');
    }
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
      );
}

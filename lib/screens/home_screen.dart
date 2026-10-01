import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/user_list.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
import 'list_detail_screen.dart';
import 'settings_screen.dart';
import 'template_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final lists = context.watch<ListsProvider>();
    final catalog = context.watch<CatalogProvider>();
    final active = lists.active;
    final archived = lists.archived;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste Asistanı'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: catalog.isLoading ? null : () => _newList(context),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Liste'),
      ),
      body: lists.isLoading || catalog.isLoading
          ? const Center(child: CircularProgressIndicator())
          : catalog.error != null && catalog.templates.isEmpty
              ? EmptyView(
                  icon: Icons.error_outline,
                  title: catalog.error!,
                  action: FilledButton(
                      onPressed: catalog.reload,
                      child: const Text('Tekrar Dene')),
                )
              : active.isEmpty && archived.isEmpty
                  ? EmptyView(
                      icon: Icons.checklist_rtl,
                      title: 'Henüz liste yok',
                      subtitle:
                          'Seyahat, market, piknik, kamp… Bir şablon seç, sana özel listeni saniyeler içinde oluştur.',
                      action: FilledButton.icon(
                        onPressed: () => _newList(context),
                        icon: const Icon(Icons.add),
                        label: const Text('İlk listeni oluştur'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 96),
                      children: [
                        if (active.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                                'Aktif liste yok. Arşivden geri alabilir veya yeni liste oluşturabilirsin.',
                                textAlign: TextAlign.center),
                          ),
                        for (final l in active) _ListCard(list: l),
                        if (archived.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.archive_outlined),
                            title: Text('Arşiv (${archived.length})'),
                            trailing: Icon(_showArchived
                                ? Icons.expand_less
                                : Icons.expand_more),
                            onTap: () =>
                                setState(() => _showArchived = !_showArchived),
                          ),
                          if (_showArchived)
                            for (final l in archived) _ListCard(list: l),
                        ],
                      ],
                    ),
    );
  }

  Future<void> _newList(BuildContext context) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const TemplatePickerScreen()));
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list});
  final UserList list;

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(list.color);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListDetailScreen(listId: list.id))),
        onLongPress: () => _menu(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(icon: list.icon, color: c, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(list.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (list.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child:
                                Icon(Icons.star, size: 16, color: Colors.amber),
                          ),
                        if (list.isArchived)
                          Icon(Icons.archive, size: 16, color: scheme.outline),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        list.templateName,
                        if (list.subtitle.isNotEmpty) list.subtitle
                      ].join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.outline),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: list.isInventory
                                  ? (list.totalCount == 0
                                      ? 0
                                      : list.inStockCount / list.totalCount)
                                  : list.progress,
                              minHeight: 6,
                              color: (list.isInventory
                                      ? list.missingCount == 0 &&
                                          list.totalCount > 0
                                      : list.isComplete)
                                  ? Colors.green
                                  : c,
                              backgroundColor: c.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            list.isInventory
                                ? '${list.inStockCount}/${list.totalCount}'
                                : '${list.checkedCount}/${list.totalCount}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (list.isInventory && list.missingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('${list.missingCount} eksik',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.error)),
                          ),
                        ],
                      ],
                    ),
                    if (list.startDate != null && !list.isArchived) ...[
                      const SizedBox(height: 8),
                      CountdownChip(
                          start: list.startDate!, end: list.endDate, color: c),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _menu(BuildContext context) {
    final lists = context.read<ListsProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: Text(list.name,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: Icon(list.isFavorite ? Icons.star : Icons.star_border,
                  color: list.isFavorite ? Colors.amber : null),
              title:
                  Text(list.isFavorite ? 'Favoriden çıkar' : 'Favorilere ekle'),
              onTap: () {
                Navigator.pop(ctx);
                lists.setFavorite(list.id, !list.isFavorite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Kopyala'),
              onTap: () async {
                Navigator.pop(ctx);
                await lists.duplicate(list.id);
              },
            ),
            ListTile(
              leading: Icon(list.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined),
              title: Text(list.isArchived ? 'Arşivden çıkar' : 'Arşivle'),
              onTap: () {
                Navigator.pop(ctx);
                lists.setArchived(list.id, !list.isArchived);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Sil',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                if (await confirm(context,
                    title: 'Listeyi sil',
                    message: '"${list.name}" kalıcı olarak silinecek.')) {
                  await lists.delete(list.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

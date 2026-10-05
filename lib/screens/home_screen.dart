import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../models/user_list.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
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
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final id in [
      'seyahat',
      'market',
      'piknik',
      'mangal',
      'kamp',
      'plaj',
      'tasinma'
    ]) {
      precacheImage(AssetImage('assets/art/$id.jpg'), context)
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lists = context.watch<ListsProvider>();
    final catalog = context.watch<CatalogProvider>();
    final active = lists.active;
    final archived = lists.archived;
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (lists.isLoading || catalog.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (catalog.error != null && catalog.templates.isEmpty) {
      body = EmptyView(
        icon: Icons.error_outline,
        title: catalog.error!,
        action: FilledButton(
            onPressed: catalog.reload, child: const Text('Tekrar Dene')),
      );
    } else {
      final favorites = active.where((l) => l.isFavorite).toList();
      final others = active.where((l) => !l.isFavorite).toList();
      var idx = 0;
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HomeHeader(lists: lists)),
          if (active.isEmpty && archived.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyHome(onCreate: () => _newList(context)),
            )
          else ...[
            if (active.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                  child: Text(
                      'Aktif liste yok. Arşivden geri alabilir veya yeni liste oluşturabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ),
            if (favorites.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('Favoriler')),
              SliverList.list(children: [
                for (final l in favorites)
                  FadeSlideIn(index: idx++, child: _ListCard(list: l)),
              ]),
            ],
            if (others.isNotEmpty) ...[
              if (favorites.isNotEmpty)
                const SliverToBoxAdapter(child: SectionTitle('Listelerim')),
              SliverList.list(children: [
                for (final l in others)
                  FadeSlideIn(index: idx++, child: _ListCard(list: l)),
              ]),
            ],
            if (archived.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _showArchived = !_showArchived),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined,
                              size: 20, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Text('Arşiv',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(width: 8),
                          Pill(
                              label: '${archived.length}',
                              color: scheme.onSurfaceVariant),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _showArchived ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.expand_more,
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_showArchived)
                SliverList.list(children: [
                  for (final l in archived)
                    FadeSlideIn(index: idx++, child: _ListCard(list: l)),
                ]),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ],
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Liste Asistanı'),
          actions: [
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: catalog.isLoading ? null : () => _newList(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni Liste'),
        ),
        body: body,
      ),
    );
  }

  Future<void> _newList(BuildContext context) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const TemplatePickerScreen()));
  }
}

/// Selamlama + özet sayılar
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.lists});
  final ListsProvider lists;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final h = now.hour;
    final greet = h < 6
        ? 'İyi geceler'
        : h < 12
            ? 'Günaydın'
            : h < 18
                ? 'İyi günler'
                : 'İyi akşamlar';
    String dateText;
    try {
      dateText = DateFormat('d MMMM EEEE', 'tr_TR').format(now);
    } catch (_) {
      dateText = '${now.day}.${now.month}.${now.year}';
    }
    final active = lists.active;
    final missing = active.fold<int>(0, (a, l) => a + l.missingCount);
    final remaining = active
        .where((l) => !l.isInventory)
        .fold<int>(0, (a, l) => a + (l.totalCount - l.checkedCount));
    final upcoming = active
        .where((l) =>
            l.startDate != null &&
            !l.isPast &&
            l.startDate!.difference(now).inDays <= 14)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greet 👋', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(dateText,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(
                    icon: Icons.format_list_bulleted_rounded,
                    value: '${active.length}',
                    label: 'aktif liste',
                    color: scheme.primary),
                const SizedBox(width: 8),
                _Stat(
                    icon: Icons.shopping_cart_outlined,
                    value: '$missing',
                    label: 'eksik',
                    color: missing > 0 ? scheme.error : Colors.green),
                const SizedBox(width: 8),
                _Stat(
                    icon: upcoming > 0
                        ? Icons.event_rounded
                        : Icons.check_circle_outline_rounded,
                    value: upcoming > 0 ? '$upcoming' : '$remaining',
                    label: upcoming > 0 ? 'yaklaşan' : 'kalan iş',
                    color: scheme.tertiary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.85)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeSlideIn(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset('assets/art/empty.jpg',
                    width: 170,
                    height: 170,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.checklist_rtl,
                        size: 96, color: scheme.outlineVariant)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Henüz liste yok',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Seyahat, market, piknik, kamp… Bir şablon seç, sana özel listeni saniyeler içinde oluştur.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('İlk listeni oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list});
  final UserList list;

  @override
  Widget build(BuildContext context) {
    final c = colorFromHex(list.color);
    final scheme = Theme.of(context).colorScheme;
    final done = list.isInventory
        ? list.missingCount == 0 && list.totalCount > 0
        : list.isComplete;
    final progress = list.isInventory
        ? (list.totalCount == 0 ? 0.0 : list.inStockCount / list.totalCount)
        : list.progress;
    final ringColor = done ? Colors.green : c;

    return SoftCard(
      tint: list.isArchived ? null : c,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ListDetailScreen(listId: list.id))),
      onLongPress: () => _menu(context),
      child: Opacity(
        opacity: list.isArchived ? 0.72 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'art-${list.id}',
              child: TemplateArt(
                  templateId: list.templateId,
                  icon: list.icon,
                  color: c,
                  size: 62,
                  radius: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(list.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (list.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.star_rounded,
                              size: 18, color: Colors.amber),
                        ),
                      if (list.isArchived)
                        Icon(Icons.archive, size: 16, color: scheme.outline),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (list.templateName != list.name) list.templateName,
                      if (list.subtitle.isNotEmpty)
                        list.subtitle
                      else if (list.templateName == list.name)
                        '${list.totalCount} kalem',
                    ].join(' · '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 7,
                              color: ringColor,
                              backgroundColor:
                                  ringColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          list.isInventory
                              ? '${list.inStockCount}/${list.totalCount}'
                              : '${list.checkedCount}/${list.totalCount}',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: ringColor)),
                    ],
                  ),
                  if (!list.isArchived &&
                      (list.startDate != null || list.isInventory || done)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (list.startDate != null)
                          CountdownChip(
                              start: list.startDate!,
                              end: list.endDate,
                              color: c),
                        if (list.isInventory && list.missingCount > 0)
                          Pill(
                              label: '${list.missingCount} eksik',
                              icon: Icons.remove_shopping_cart_outlined,
                              color: scheme.error),
                        if (done)
                          Pill(
                              label: list.isInventory
                                  ? 'Her şey stokta'
                                  : 'Tamamlandı',
                              icon: Icons.check_circle_rounded,
                              color: Colors.green),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _menu(BuildContext context) {
    final lists = context.read<ListsProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: TemplateArt(
                  templateId: list.templateId,
                  icon: list.icon,
                  color: colorFromHex(list.color),
                  size: 40),
              title:
                  Text(list.name, style: Theme.of(ctx).textTheme.titleMedium),
              subtitle: Text(list.templateName),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(
                  list.isFavorite ? Icons.star_rounded : Icons.star_border,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

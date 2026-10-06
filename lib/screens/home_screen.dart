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
      // Yaklaşan saatli görevler: gecikmiş + önümüzdeki 7 gün (tüm listeler)
      final now = DateTime.now();
      final horizon = now.add(const Duration(days: 7));
      final upcoming = <(UserList, ListItem)>[];
      for (final l in active) {
        for (final i in l.items) {
          final d = i.dueAt;
          if (d == null || i.isChecked) continue;
          if (d.isBefore(horizon)) upcoming.add((l, i));
        }
      }
      upcoming.sort((a, b) => a.$2.dueAt!.compareTo(b.$2.dueAt!));

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
            if (upcoming.isNotEmpty)
              SliverToBoxAdapter(
                  child: _UpcomingCard(upcoming: upcoming)),
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                if (Theme.of(context).brightness == Brightness.dark)
                  Color.lerp(scheme.primary, Colors.black, .40)!
                else
                  scheme.primary,
                if (Theme.of(context).brightness == Brightness.dark)
                  Color.lerp(scheme.tertiary, Colors.black, .52)!
                else
                  Color.lerp(scheme.primary, scheme.tertiary, .55)!,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: scheme.primary.withValues(alpha: .38),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: FloatingActionButton.extended(
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            onPressed: catalog.isLoading ? null : () => _newList(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Liste'),
          ),
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

/// Selamlama (gradyanlı) + tarih rozeti + yumuşak özet kartı
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
    String monthShort;
    try {
      dateText = DateFormat('d MMMM EEEE', 'tr_TR').format(now);
      monthShort = DateFormat('MMM', 'tr_TR').format(now);
    } catch (_) {
      dateText = '${now.day}.${now.month}.${now.year}';
      monthShort = '${now.month}';
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

    var total = 0;
    var done = 0;
    for (final l in active) {
      total += l.totalCount;
      done += l.isInventory ? l.inStockCount : l.checkedCount;
    }
    final prog = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => LinearGradient(
                        colors: [
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, .65)!,
                        ],
                      ).createShader(r),
                      child: Text(greet,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -.5,
                                  height: 1.12)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: .22)),
                ),
                child: Column(
                  children: [
                    Text('${now.day}',
                        style: TextStyle(
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary)),
                    const SizedBox(height: 2),
                    Text(monthShort.toLowerCase(),
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                            color: scheme.primary.withValues(alpha: .8))),
                  ],
                ),
              ),
            ],
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 14),
            _HeroSummary(
              progress: prog,
              activeCount: active.length,
              missing: missing,
              rightValue: upcoming > 0 ? '$upcoming' : '$remaining',
              rightLabel: upcoming > 0 ? 'yaklaşan' : 'kalan iş',
            ),
          ],
        ],
      ),
    );
  }
}

/// Ana ekranın özet kartı: gradyan + tamamlanma halkası + cam istatistikler.
class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.progress,
    required this.activeCount,
    required this.missing,
    required this.rightValue,
    required this.rightLabel,
  });
  final double progress;
  final int activeCount;
  final int missing;
  final String rightValue;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var c1 = scheme.primary;
    var c2 = Color.lerp(scheme.primary, scheme.tertiary, .6)!;
    if (isDark) {
      c1 = Color.lerp(c1, Colors.black, .42)!;
      c2 = Color.lerp(c2, Colors.black, .55)!;
    }
    final pct = (progress * 100).round();

    Widget chip(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: .85))),
              ],
            ),
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: c1.withValues(alpha: .35),
              blurRadius: 26,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
                top: -36,
                right: -28,
                child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .08)))),
            Positioned(
                bottom: -48,
                left: -22,
                child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .06)))),
            Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            Colors.white.withValues(alpha: .25),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct%',
                                style: const TextStyle(
                                    fontSize: 19,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            const SizedBox(height: 3),
                            Text('tamam',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white
                                        .withValues(alpha: .85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      chip('$activeCount', 'aktif liste'),
                      const SizedBox(width: 8),
                      chip('$missing', 'eksik'),
                      const SizedBox(width: 8),
                      chip(rightValue, rightLabel),
                    ],
                  ),
                ),
              ],
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

/// Ana ekran "Yaklaşanlar" kartı: gecikmiş + önümüzdeki 7 günün saatli işleri,
/// zaman sırasıyla. İş ve gündelik listeleri kendi renk/adıyla görünür.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.upcoming});
  final List<(UserList, ListItem)> upcoming;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = upcoming.take(6).toList();
    final rest = upcoming.length - shown.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: SoftCard(
        tint: scheme.primary,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      Icon(Icons.schedule, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Text('Yaklaşanlar',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                Pill(label: '${upcoming.length}', color: scheme.primary),
                const Spacer(),
                Text('7 gün',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            for (final (l, i) in shown) _UpcomingRow(list: l, item: i),
            if (rest > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 2),
                child: Text(
                  '+$rest iş daha …',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.list, required this.item});
  final UserList list;
  final ListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = colorFromHex(list.color);
    final dc = dueColor(item.dueAt!, checked: false, scheme: scheme);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ListDetailScreen(listId: list.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dc, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(list.name,
                      style: TextStyle(
                          fontSize: 11,
                          color: c,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(dueLabel(item.dueAt!),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: dc)),
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
      elevated: !list.isArchived,
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: c.withValues(alpha: .32),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: TemplateArt(
                    templateId: list.templateId,
                    icon: list.icon,
                    color: c,
                    size: 64,
                    radius: 20),
              ),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                            builder: (_, v, __) => SizedBox(
                              height: 8,
                              child: Stack(
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                          color: ringColor
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                  FractionallySizedBox(
                                    widthFactor: v,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          ringColor,
                                          Color.lerp(ringColor,
                                              Colors.white, .4)!
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

import 'dart:io' show Platform;

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_icons.dart';
import '../core/utils.dart';
import '../models/template.dart';
import '../models/user_list.dart';
import '../providers/catalog_provider.dart';
import '../providers/lists_provider.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'selection_screen.dart';
import 'shopping_mode_screen.dart';
import '../widgets/voice_sheet.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key, required this.listId});
  final String listId;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  /// Kontrol listesinde: sadece işaretlenmemişler. Stok listesinde: sadece eksikler.
  bool _onlyRemaining = false;

  /// Market listesinde işaretli kalemlerin görünürlüğü (varsayılan: göster).
  bool _hideCheckedMarket = false;

  /// Tamamlanma kutlaması
  bool? _wasDone;
  bool _confetti = false;

  bool _isDone(UserList l) =>
      l.isInventory ? l.missingCount == 0 && l.totalCount > 0 : l.isComplete;

  void _trackCompletion(UserList l) {
    final done = _isDone(l);
    if (_wasDone == false && done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _confetti = true);
        showSnack(
            context,
            l.isInventory
                ? 'Her şey stokta, eksik yok! 🎉'
                : 'Liste tamamlandı, her şey hazır! 🎉');
      });
    }
    _wasDone = done;
  }

  @override
  Widget build(BuildContext context) {
    final lists = context.watch<ListsProvider>();
    final list = lists.byId(widget.listId);
    if (list == null) {
      return Scaffold(
        appBar: AppBar(),
        body:
            const EmptyView(icon: Icons.search_off, title: 'Liste bulunamadı'),
      );
    }
    _trackCompletion(list);
    final color = colorFromHex(list.color);
    final hasTabs = list.hasSections;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffold = AppBackground(
      accent: color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: list.quickAdd
            ? null
            : FloatingActionButton(
                backgroundColor: color,
                foregroundColor: Colors.white,
                onPressed: () => _addItemDialog(list),
                child: const Icon(Icons.add_rounded),
              ),
        bottomNavigationBar: list.quickAdd
            ? _QuickAddBar(
                list: list,
                template: context
                    .read<CatalogProvider>()
                    .templateById(list.templateId),
                onDetailed: () => _addItemDialog(list),
              )
            : null,
        body: Stack(
          children: [
            Column(
              children: [
                // Gradyanlı üst alan: araç çubuğu + özet + sekmeler
                AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                    child: HeroBackdrop(
                      color: color,
                      templateId: list.templateId,
                      icon: list.icon,
                      artOpacity: isDark ? 0.18 : 0.26,
                      child: SafeArea(
                        bottom: false,
                        child: IconTheme(
                          data: const IconThemeData(color: Colors.white),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  const BackButton(color: Colors.white),
                                  Expanded(
                                    child: Text(list.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(color: Colors.white)),
                                  ),
                                  ..._actions(context, list, lists),
                                  const SizedBox(width: 4),
                                ],
                              ),
                              _Header(
                                  list: list,
                                  color: color,
                                  pendingReminders:
                                      lists.pendingReminderCount(list)),
                              if (hasTabs)
                                TabBar(
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  labelColor: Colors.white,
                                  unselectedLabelColor:
                                      Colors.white.withValues(alpha: .65),
                                  indicatorColor: Colors.white,
                                  indicatorWeight: 3,
                                  tabs: [
                                    for (final s in list.sections)
                                      Tab(
                                          text:
                                              '${s.name} ${list.checkedInSection(s.id)}/${list.itemsOfSection(s.id).length}'),
                                  ],
                                )
                              else
                                const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: hasTabs
                      ? TabBarView(children: [
                          for (final s in list.sections)
                            _sectionBody(list, s.id)
                        ])
                      : _sectionBody(list, list.sections.first.id),
                ),
              ],
            ),
            if (_confetti)
              Positioned.fill(
                child: ConfettiBurst(
                  colors: [
                    color,
                    color.lighten(.2),
                    Colors.amber,
                    Colors.pinkAccent,
                    Colors.lightBlueAccent,
                    Colors.greenAccent,
                  ],
                  onDone: () {
                    if (mounted) setState(() => _confetti = false);
                  },
                ),
              ),
          ],
        ),
      ),
    );
    return hasTabs
        ? DefaultTabController(length: list.sections.length, child: scaffold)
        : scaffold;
  }

  List<Widget> _actions(
      BuildContext context, UserList list, ListsProvider lists) {
    return [
      IconButton(
        tooltip: _onlyRemaining
            ? 'Tümünü göster'
            : (list.isInventory ? 'Sadece eksikler' : 'Sadece kalanlar'),
        color: Colors.white,
        icon: Icon(_onlyRemaining
            ? Icons.filter_alt_off_outlined
            : (list.isInventory
                ? Icons.production_quantity_limits
                : Icons.rule)),
        onPressed: () => setState(() => _onlyRemaining = !_onlyRemaining),
      ),
      if (list.templateId == 'market')
        IconButton(
          tooltip: _hideCheckedMarket
              ? 'Tamamlananları göster'
              : 'Tamamlananları gizle',
          color: Colors.white,
          icon: Icon(_hideCheckedMarket
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: () =>
              setState(() => _hideCheckedMarket = !_hideCheckedMarket),
        ),
      IconButton(
        tooltip: list.isFavorite ? 'Favoriden çıkar' : 'Favorilere ekle',
        icon: Icon(
            list.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: list.isFavorite ? Colors.amber : Colors.white),
        onPressed: () => lists.setFavorite(list.id, !list.isFavorite),
      ),
      PopupMenuButton<String>(
        iconColor: Colors.white,
        onSelected: (v) => _menuAction(v, list),
        itemBuilder: (menuCtx) {
          final canShop = list.isInventory
              ? list.missingCount > 0
              : list.totalCount - list.checkedCount > 0;
          return [
          PopupMenuItem(
            value: 'shop',
            enabled: canShop,
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_checkout_rounded),
              title: Text(list.isInventory
                  ? 'Alışveriş modu'
                  : 'Adım adım tamamla'),
              subtitle: Text(canShop
                  ? 'Sesle veya dokunarak işaretle'
                  : 'Yapılacak bir şey kalmadı'),
            ),
          ),
          if (list.isInventory) ...[
            if (list.templateId != 'market')
              PopupMenuItem(
                value: 'transfer',
                enabled: list.missingCount > 0,
                child: ListTile(
                    leading: const Icon(Icons.move_to_inbox_outlined),
                    title: const Text('Eksikleri markete aktar'),
                    subtitle: Text(list.missingCount == 0
                        ? 'Eksik yok'
                        : '${list.missingCount} kalem'))),
            PopupMenuItem(
                value: 'shareMissing',
                enabled: list.missingCount > 0,
                child: const ListTile(
                    leading: Icon(Icons.send_outlined),
                    title: Text('Eksikleri paylaş'))),
            const PopupMenuItem(
                value: 'stockAll',
                child: ListTile(
                    leading: Icon(Icons.inventory_2_outlined),
                    title: Text('Hepsini stokta işaretle'))),
            const PopupMenuItem(
                value: 'stockNone',
                child: ListTile(
                    leading: Icon(Icons.remove_shopping_cart_outlined),
                    title: Text('Stokları sıfırla'))),
            const PopupMenuDivider(),
          ],
          const PopupMenuItem(
              value: 'addCatalog',
              child: ListTile(
                  leading: Icon(Icons.library_add_outlined),
                  title: Text('Katalogdan ekle'))),
          const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Yeniden adlandır'))),
          const PopupMenuItem(
              value: 'dates',
              child: ListTile(
                  leading: Icon(Icons.event_outlined),
                  title: Text('Tarihleri düzenle'))),
          const PopupMenuItem(
              value: 'share',
              child: ListTile(
                  leading: Icon(Icons.share_outlined), title: Text('Paylaş'))),
          const PopupMenuItem(
              value: 'shareRemaining',
              child: ListTile(
                  leading: Icon(Icons.send_outlined),
                  title: Text('Kalanları paylaş'))),
          const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                  leading: Icon(Icons.copy_outlined), title: Text('Kopyala'))),
          const PopupMenuItem(
              value: 'reset',
              child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('İşaretleri sıfırla'))),
          if (list.items.any((i) => i.reminderAt != null))
            PopupMenuItem(
              value: lists.pendingReminderCount(list) > 0 ? 'remOff' : 'remOn',
              child: ListTile(
                leading: Icon(lists.pendingReminderCount(list) > 0
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined),
                title: Text(lists.pendingReminderCount(list) > 0
                    ? 'Hatırlatıcıları kapat'
                    : 'Hatırlatıcıları aç'),
              ),
            ),
          PopupMenuItem(
            value: 'archive',
            child: ListTile(
              leading: Icon(list.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined),
              title: Text(list.isArchived ? 'Arşivden çıkar' : 'Arşivle'),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Sil',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
          ];
        },
      ),
    ];
  }

  Widget _sectionBody(UserList list, String sectionId) {
    final lists = context.read<ListsProvider>();
    final children = <Widget>[];
    var hiddenByVisibility = false;
    for (final c in list.categoriesOf(sectionId)) {
      var items = list.itemsOfCategory(c.id);
      if (items.isEmpty) continue;
      final total = items.length;
      final done = list.isInventory
          ? items.where((i) => i.inStock).length
          : items.where((i) => i.isChecked).length;
      if (_onlyRemaining) {
        items = list.isInventory
            ? items.where((i) => i.isMissing).toList()
            : items.where((i) => !i.isChecked).toList();
      } else if (list.isInventory) {
        // Eksikler üstte, sıra korunarak
        items = [
          ...items.where((i) => i.isMissing),
          ...items.where((i) => i.inStock),
        ];
      }
      // Market'te tamamlananlar varsayılan olarak üstü çizili görünür;
      // göz düğmesi onları isteğe bağlı gizler. Diğer stok listeleri
      // mevcut davranışıyla işaretlileri gizlemeye devam eder.
      if (list.isInventory &&
          (list.templateId != 'market' || _hideCheckedMarket)) {
        if (list.templateId == 'market' &&
            items.any((i) => i.isChecked)) {
          hiddenByVisibility = true;
        }
        items = items.where((i) => !i.isChecked).toList();
      }
      // Saatli görevler (dueAt) tamamlanmamış olarak zamana göre en üste
      if (!list.isInventory &&
          items.any((i) => i.dueAt != null && !i.isChecked)) {
        final due = items
            .where((i) => i.dueAt != null && !i.isChecked)
            .toList()
              ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
        final rest =
            items.where((i) => !(i.dueAt != null && !i.isChecked)).toList();
        items = [...due, ...rest];
      }
      if (items.isEmpty) continue;
      children.add(CategoryHeader(
        name: c.name,
        icon: c.icon,
        colorHex: c.color,
        count: done,
        total: total,
        onTap: () => _categoryMenu(list, c),
      ));
      final tiles = <Widget>[];
      for (final i in items) {
        tiles.add(_ItemTile(
          item: i,
          color: colorFromHex(c.color),
          inventory: list.isInventory,
          onToggle: () async {
            final wasChecked = i.isChecked;
            final marketList = list.templateId == 'market';
            if (list.isInventory && !marketList && !wasChecked) {
              final accepted = await confirm(
                context,
                title: '"${i.name}" tamamlandı mı?',
                message:
                    'Onaylarsan bu kalem tamamlandı olarak işaretlenip bu listeden gizlenecek.',
                okLabel: 'Evet, gizle',
                destructive: false,
              );
              if (!accepted || !mounted) return;
            }
            await lists.toggleItem(list.id, i.id);
            if (!mounted || !list.isInventory || marketList || wasChecked) {
              return;
            }
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(SnackBar(
              content: Text('"${i.name}" listeden gizlendi'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Geri al',
                onPressed: () => lists.toggleItem(list.id, i.id),
              ),
            ));
          },
          onLongPress: () => _itemSheet(list, i),
          onQty: i.quantity == null
              ? null
              : (d) => lists.setQuantity(
                  list.id, i.id, (i.quantity! + d).clamp(1, 999)),
          onStock: (d) => lists.setStock(list.id, i.id, i.stockQty + d),
          onStockToggle: () => _stockSheet(list, i),
        ));
      }
      children.add(GroupCard(children: tiles));
    }
    if (children.isEmpty) {
      return EmptyView(
        icon: hiddenByVisibility
            ? Icons.visibility_off_outlined
            : (_onlyRemaining
                ? Icons.celebration_outlined
                : Icons.playlist_add),
        title: hiddenByVisibility
            ? 'Tamamlanan kalemler gizli'
            : (_onlyRemaining
                ? (list.isInventory
                    ? 'Bu bölümde eksik yok!'
                    : 'Bu bölümde her şey tamam!')
                : 'Bu bölüm boş'),
        subtitle: hiddenByVisibility
            ? 'Göz simgesinden tamamlananları tekrar gösterebilirsin.'
            : (_onlyRemaining
                ? null
                : 'Sağ alttaki + ile kalem ekle veya menüden "Katalogdan ekle".'),
        action: hiddenByVisibility
            ? FilledButton.tonalIcon(
                onPressed: () => setState(() => _hideCheckedMarket = false),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Tamamlananları göster'),
              )
            : null,
      );
    }
    return ListView(
        padding: const EdgeInsets.only(bottom: 96, top: 6), children: children);
  }

  // ── Menü aksiyonları ──────────────────────────────────────────────────────
  Future<void> _menuAction(String v, UserList list) async {
    final lists = context.read<ListsProvider>();
    switch (v) {
      case 'shop':
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ShoppingModeScreen(listId: list.id)));
      case 'addCatalog':
        final template =
            context.read<CatalogProvider>().templateById(list.templateId);
        if (template == null) {
          showSnack(context,
              'Bu listenin şablonu artık yok; + ile elle ekleyebilirsin.');
          return;
        }
        final n = await Navigator.push<int>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SelectionScreen.add(template: template, existing: list)));
        if (n != null && n > 0 && mounted) {
          showSnack(context, '$n kalem eklendi');
        }
      case 'rename':
        final name =
            await promptText(context, title: 'Liste adı', initial: list.name);
        if (name != null) await lists.rename(list.id, name);
      case 'dates':
        await _editDates(list);
      case 'share':
        await SharePlus.instance.share(
            ShareParams(text: lists.shareText(list), subject: list.name));
      case 'shareRemaining':
        await SharePlus.instance.share(ShareParams(
            text: lists.shareText(list, onlyUnchecked: true),
            subject: list.name));
      case 'shareMissing':
        await SharePlus.instance.share(ShareParams(
            text: lists.shareText(list, onlyMissing: true),
            subject: '${list.name} – eksikler'));
      case 'transfer':
        await _transferMissing(list);
      case 'stockAll':
        await lists.setAllStock(list.id, true);
        if (mounted) showSnack(context, 'Tüm kalemler stokta');
      case 'stockNone':
        if (await confirm(context,
            title: 'Stokları sıfırla',
            message: 'Tüm kalemlerin stok miktarı 0 olacak.',
            okLabel: 'Sıfırla',
            destructive: false)) {
          await lists.setAllStock(list.id, false);
        }
      case 'duplicate':
        await lists.duplicate(list.id);
        if (mounted) showSnack(context, 'Kopya oluşturuldu');
      case 'reset':
        if (await confirm(context,
            title: 'İşaretleri sıfırla',
            message: 'Tüm kalemler işaretsiz hale gelecek.',
            okLabel: 'Sıfırla',
            destructive: false)) {
          await lists.resetChecks(list.id);
        }
      case 'remOn':
        await lists.setAllReminders(list.id, true);
        if (mounted) showSnack(context, 'Hatırlatıcılar açıldı');
      case 'remOff':
        await lists.setAllReminders(list.id, false);
        if (mounted) showSnack(context, 'Hatırlatıcılar kapatıldı');
      case 'archive':
        await lists.setArchived(list.id, !list.isArchived);
        if (mounted) Navigator.pop(context);
      case 'delete':
        if (await confirm(context,
            title: 'Listeyi sil',
            message: '"${list.name}" kalıcı olarak silinecek.')) {
          await lists.delete(list.id);
          if (mounted) Navigator.pop(context);
        }
    }
  }

  // ── Eksikleri aktar ───────────────────────────────────────────────────────
  Future<void> _transferMissing(UserList list) async {
    final lists = context.read<ListsProvider>();
    final catalog = context.read<CatalogProvider>();
    final targets = lists.transferTargets(list.id);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('${list.missingCount} eksik kalem nereye aktarılsın?',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Yeni market listesi oluştur'),
              subtitle: Text('"Alışveriş – ${list.name}"'),
              onTap: () => Navigator.pop(ctx, '__new__'),
            ),
            if (targets.isNotEmpty) const Divider(),
            for (final t in targets)
              ListTile(
                leading:
                    Icon(AppIcons.get(t.icon), color: colorFromHex(t.color)),
                title: Text(t.name),
                subtitle: Text(
                    '${t.templateName} · ${t.totalCount} kalem · ${t.missingCount} eksik'),
                onTap: () => Navigator.pop(ctx, t.id),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String targetId = choice;
    if (choice == '__new__') {
      final market = catalog.templateById('market');
      if (market == null) {
        showSnack(context, 'Market şablonu bulunamadı');
        return;
      }
      final created = await lists.createList(
        template: market,
        name: 'Alışveriş – ${list.name}',
        fields: const {},
        answers: market.defaultAnswers(),
        startDate: null,
        endDate: null,
        items: const [],
      );
      targetId = created.id;
    }
    final n = await lists.transferMissing(list.id, targetId);
    if (!mounted) return;
    final target = lists.byId(targetId);
    showSnack(
        context, '$n kalem "${target?.name ?? 'liste'}" listesine aktarıldı');
  }

  Future<void> _editDates(UserList list) async {
    final lists = context.read<ListsProvider>();
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: list.startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Başlangıç tarihi',
      locale: const Locale('tr', 'TR'),
    );
    if (start == null || !mounted) return;
    DateTime? end;
    if (list.endDate != null ||
        list.templateId == 'seyahat' ||
        list.templateId == 'kamp') {
      end = await showDatePicker(
        context: context,
        initialDate: (list.endDate != null && !list.endDate!.isBefore(start))
            ? list.endDate!
            : start,
        firstDate: start,
        lastDate: DateTime(now.year + 5),
        helpText: 'Bitiş tarihi (isteğe bağlı)',
        locale: const Locale('tr', 'TR'),
      );
    }
    await lists.updateMeta(list.id, start: start, end: end);
  }

  void _categoryMenu(UserList list, TemplateCategory c) {
    final lists = context.read<ListsProvider>();
    final items = list.itemsOfCategory(c.id);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Tümünü işaretle'),
              onTap: () async {
                Navigator.pop(ctx);
                for (final i in items.where((i) => !i.isChecked)) {
                  await lists.toggleItem(list.id, i.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_done),
              title: const Text('İşaretleri kaldır'),
              onTap: () async {
                Navigator.pop(ctx);
                for (final i in items.where((i) => i.isChecked)) {
                  await lists.toggleItem(list.id, i.id);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Kategoriyi listeden çıkar',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                if (await confirm(context,
                    title: 'Kategoriyi çıkar',
                    message:
                        '"${c.name}" altındaki ${items.length} kalem listeden çıkarılacak.')) {
                  await lists.removeItems(
                      list.id, items.map((i) => i.id).toSet());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Kalem ekleme ──────────────────────────────────────────────────────────
  Future<void> _addItemDialog(UserList list) async {
    final lists = context.read<ListsProvider>();
    final result = await showModalBottomSheet<_ItemFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ItemForm(list: list),
    );
    if (result == null) return;
    await lists.addCustomItem(list.id,
        name: result.name,
        categoryId: result.categoryId,
        quantity: result.quantity,
        unit: result.unit,
        note: result.note,
        dueAt: result.dueAt,
        stockQty: result.stockQty);
  }

  // ── Kalem detay/düzenleme ─────────────────────────────────────────────────
  // ── Stok düzenleme (hedef + mevcut) ───────────────────────────────────────
  Future<void> _stockSheet(UserList list, ListItem item) async {
    final lists = context.read<ListsProvider>();
    var need = item.needQty;
    var stock = item.stockQty;
    final unit =
        (item.unit == null || item.unit!.isEmpty) ? '' : ' ${item.unit}';
    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final missing = (need - stock).clamp(0, 9999);
          final scheme = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _LevelRow(
                    label: 'Olması gereken',
                    hint: 'Hedef stok (örn. 5)',
                    value: need,
                    unit: unit,
                    min: 1,
                    onChanged: (v) => setSheet(() {
                      need = v;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _LevelRow(
                    label: 'Şu an stokta',
                    hint: 'Elinizdeki miktar',
                    value: stock,
                    unit: unit,
                    min: 0,
                    onChanged: (v) => setSheet(() {
                      stock = v;
                    }),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (missing > 0 ? scheme.error : Colors.green)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      missing > 0
                          ? 'Eksik: $missing$unit → markete bu kadar aktarılır'
                          : 'Stok yeterli',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: missing > 0
                              ? scheme.error
                              : Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setSheet(() => stock = need),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Hepsi var'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setSheet(() => stock = 0),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Hiç yok'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, (need, stock)),
                        child: const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result == null) return;
    await lists.setStockLevels(list.id, item.id,
        need: result.$1, stock: result.$2);
  }

  Future<void> _itemSheet(UserList list, ListItem item) async {
    final result = await showModalBottomSheet<_ItemFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ItemForm(list: list, item: item),
    );
    if (result == null || !mounted) return;
    final lists = context.read<ListsProvider>();
    if (result.delete) {
      await lists.removeItem(list.id, item.id);
      return;
    }
    await lists.updateItem(
      list.id,
      item.copyWith(
        name: result.name,
        categoryId: result.categoryId,
        quantity: result.quantity,
        clearQuantity: result.quantity == null,
        unit: result.unit,
        note: result.note,
        clearNote: result.note == null,
        reminderAt: result.reminderAt,
        clearReminder: result.reminderAt == null,
        reminderEnabled: result.reminderEnabled,
        dueAt: result.dueAt,
        clearDueAt: result.dueAt == null,
        stockQty: result.stockQty,
      ),
    );
  }
}

// ── Hızlı ekleme çubuğu (market) ────────────────────────────────────────────
/// Alt kısımda sabit metin kutusu: yazdıkça katalogdan öneri çıkar, Enter veya
/// öneriye dokununca kalem eklenir. Katalogda yoksa serbest kalem olarak eklenir.
class _QuickAddBar extends StatefulWidget {
  const _QuickAddBar(
      {required this.list, required this.template, required this.onDetailed});
  final UserList list;
  final ListTemplate? template;
  final VoidCallback onDetailed;

  @override
  State<_QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<_QuickAddBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Iterable<CatalogItem> _options(TextEditingValue v) {
    final t = widget.template;
    final q = normalizeTr(v.text.trim());
    if (t == null || q.length < 2) return const Iterable.empty();
    final starts = <CatalogItem>[];
    final contains = <CatalogItem>[];
    for (final c in t.items) {
      final n = normalizeTr(c.name);
      final existing = widget.list.items.firstWhereOrNull(
          (item) => normalizeTr(item.name) == n);
      final canReactivate = existing != null &&
          (existing.isChecked ||
              (widget.list.isInventory && existing.inStock));
      if (existing != null && !canReactivate) continue;
      if (n.startsWith(q)) {
        starts.add(c);
      } else if (n.contains(q)) {
        contains.add(c);
      }
    }
    return [...starts, ...contains].take(6);
  }

  Future<void> _voiceAdd() async {
    final color = colorFromHex(widget.list.color);
    final entries = await showVoiceSheet(context, color: color);
    if (entries == null || entries.isEmpty || !mounted) return;
    final lists = context.read<ListsProvider>();
    final taskMode = widget.template?.dueDates ?? false;
    var added = 0;
    for (final e in entries) {
      final r = await lists.quickAdd(widget.list.id, e.name,
          template: widget.template,
          quantity: taskMode ? null : e.quantity,
          unit: taskMode || e.unit == 'adet' ? null : e.unit);
      if (r != null) added++;
    }
    if (!mounted) return;
    _ctrl.clear();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('$added kalem sesle eklendi'),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _submit(String text, {CatalogItem? pick}) async {
    final name = pick?.name ?? text;
    if (name.trim().isEmpty) return;
    final lists = context.read<ListsProvider>();
    final added = await lists.quickAdd(widget.list.id, name,
        template: widget.template, catalogItem: pick);
    if (!mounted) return;
    _ctrl.clear();
    _focus.requestFocus();
    if (added != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${added.name} eklendi'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        border: Border(
            top:
                BorderSide(color: scheme.outlineVariant.withValues(alpha: .5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              12, 8, 8, 8 + MediaQuery.viewInsetsOf(context).bottom),
          child: Row(
            children: [
              Expanded(
                child: RawAutocomplete<CatalogItem>(
                  textEditingController: _ctrl,
                  focusNode: _focus,
                  optionsViewOpenDirection: OptionsViewOpenDirection.up,
                  displayStringForOption: (c) => c.name,
                  optionsBuilder: _options,
                  onSelected: (c) => _submit(c.name, pick: c),
                  fieldViewBuilder: (context, ctrl, focus, onSubmit) =>
                      TextField(
                    controller: ctrl,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Hızlı ekle: süt, ekmek…',
                      prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? scheme.surfaceContainerHigh
                          : scheme.surfaceContainerLow,
                      border: OutlinedBorderless.r24,
                      enabledBorder: OutlinedBorderless.r24,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: scheme.primary, width: 1.6)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (v) => _submit(v),
                  ),
                  optionsViewBuilder: (context, onSelected, options) {
                    final cats = widget.list.categories;
                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 260, maxWidth: 420),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              for (final c in options)
                                ListTile(
                                  dense: true,
                                  leading: Icon(
                                      AppIcons.get(cats
                                              .firstWhereOrNull(
                                                  (x) => x.id == c.category)
                                              ?.icon ??
                                          'category'),
                                      size: 20),
                                  title: Text(c.name),
                                  subtitle: c.qty == null
                                      ? null
                                      : Text(
                                          '${c.qty!.compute(1)} ${c.unit ?? ''}'
                                              .trim()),
                                  onTap: () => onSelected(c),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (voiceInputSupported)
                IconButton.filledTonal(
                  tooltip: 'Sesle ekle ("iki ekmek")',
                  icon: const Icon(Icons.mic_rounded),
                  onPressed: _voiceAdd,
                ),
              IconButton.filledTonal(
                tooltip: 'Ayrıntılı ekle (kategori, miktar, not)',
                icon: const Icon(Icons.playlist_add_rounded),
                onPressed: widget.onDetailed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Üst bilgi ───────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header(
      {required this.list,
      required this.color,
      required this.pendingReminders});
  final UserList list;
  final Color color;
  final int pendingReminders;

  @override
  Widget build(BuildContext context) {
    final done = list.isInventory
        ? list.missingCount == 0 && list.totalCount > 0
        : list.isComplete;
    final progress = list.isInventory
        ? (list.totalCount == 0 ? 0.0 : list.inStockCount / list.totalCount)
        : list.progress;
    final white = Colors.white.withValues(alpha: .92);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: .25),
                    color: Colors.white,
                  ),
                  Center(
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 30)
                        : Text('${(v * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    list.isInventory
                        ? '${list.inStockCount} / ${list.totalCount} stokta'
                        : '${list.checkedCount} / ${list.totalCount} tamamlandı',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                if (list.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(list.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (list.startDate != null)
                      _GlassPill(
                          icon: Icons.schedule_rounded,
                          label: countdownText(list.startDate!,
                              end: list.endDate)),
                    if (list.isInventory)
                      _GlassPill(
                          icon: list.missingCount > 0
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.check_circle_outline_rounded,
                          label: list.missingCount > 0
                              ? '${list.missingCount} eksik'
                              : 'Eksik yok',
                          strong: list.missingCount > 0),
                    if (pendingReminders > 0)
                      _GlassPill(
                          icon: Icons.notifications_active_rounded,
                          label: '$pendingReminders hatırlatıcı'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradyan üstünde yarı saydam rozet
class _GlassPill extends StatelessWidget {
  const _GlassPill(
      {required this.icon, required this.label, this.strong = false});
  final IconData icon;
  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: strong ? .92 : .2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: strong ? const Color(0xFFC62828) : Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: strong ? const Color(0xFFC62828) : Colors.white)),
          ],
        ),
      );
}

// ── Kalem satırı ────────────────────────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  const _ItemTile(
      {required this.item,
      required this.color,
      required this.onToggle,
      required this.onLongPress,
      this.onQty,
      this.inventory = false,
      this.onStock,
      this.onStockToggle});
  final ListItem item;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final void Function(int delta)? onQty;

  /// Stok listesi: sağda miktar yerine stok kontrolü gösterilir.
  final bool inventory;
  final void Function(int delta)? onStock;
  final VoidCallback? onStockToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checked = item.isChecked;
    final hasReminder = item.reminderAt != null;
    final hasDue = item.dueAt != null;
    final dueC = hasDue
        ? dueColor(item.dueAt!, checked: checked, scheme: scheme)
        : scheme.primary;
    return InkWell(
      onTap: onToggle,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            AnimatedCheck(
                checked: checked, color: color, round: !inventory, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight:
                                checked ? FontWeight.w500 : FontWeight.w600,
                            decoration:
                                checked ? TextDecoration.lineThrough : null,
                            decorationColor: scheme.outline,
                            color: checked ? scheme.outline : scheme.onSurface,
                          ),
                          child: Text(item.name),
                        ),
                      ),
                      if (item.isEssential && !checked) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  if (item.note != null && item.note!.isNotEmpty ||
                      hasReminder ||
                      hasDue)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (hasDue) ...[
                            Icon(Icons.schedule,
                                size: 12, color: dueC),
                            const SizedBox(width: 3),
                            Text(
                                item.isChecked
                                    ? fmtDateTime(item.dueAt!)
                                    : dueLabel(item.dueAt!),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: dueC)),
                            const SizedBox(width: 8),
                          ],
                          if (hasReminder) ...[
                            Icon(
                                item.reminderEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off_outlined,
                                size: 12,
                                color: item.reminderEnabled
                                    ? scheme.tertiary
                                    : scheme.outline),
                            const SizedBox(width: 3),
                            Text(fmtDateTime(item.reminderAt!),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: item.reminderEnabled
                                        ? scheme.tertiary
                                        : scheme.outline)),
                            const SizedBox(width: 8),
                          ],
                          if (item.note != null && item.note!.isNotEmpty)
                            Flexible(
                              child: Text(item.note!,
                                  style: TextStyle(
                                      fontSize: 11, color: scheme.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (inventory)
              _StockControl(
                  item: item,
                  onStock: onStock,
                  onToggle: onStockToggle,
                  dim: checked)
            else if (item.quantity != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(
                      icon: Icons.remove,
                      onTap: onQty == null || item.quantity! <= 1
                          ? null
                          : () => onQty!(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(item.quantityLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: checked ? scheme.outline : null)),
                  ),
                  _QtyBtn(
                      icon: Icons.add,
                      onTap: onQty == null ? null : () => onQty!(1)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Stok listesi satırındaki "stok / gereken" kontrolü.
/// − / + stoğu değiştirir; etikete dokunmak hedef + stok düzenleme sayfasını açar.
class _StockControl extends StatelessWidget {
  const _StockControl(
      {required this.item, this.onStock, this.onToggle, this.dim = false});
  final ListItem item;
  final void Function(int delta)? onStock;
  final VoidCallback? onToggle;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = item.isMissing;
    final c =
        dim ? scheme.outline : (missing ? scheme.error : Colors.green.shade700);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyBtn(
            icon: Icons.remove,
            onTap: onStock == null || item.stockQty <= 0
                ? null
                : () => onStock!(-1)),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.stockLabel,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
                Text(missing ? 'eksik' : 'stokta',
                    style: TextStyle(fontSize: 9.5, color: c)),
              ],
            ),
          ),
        ),
        _QtyBtn(
            icon: Icons.add, onTap: onStock == null ? null : () => onStock!(1)),
      ],
    );
  }
}

/// Stok sayfasındaki tek satır: etiket + − sayı + (sayıya dokununca elle giriş).
class _LevelRow extends StatelessWidget {
  const _LevelRow(
      {required this.label,
      required this.hint,
      required this.value,
      required this.unit,
      required this.min,
      required this.onChanged});
  final String label;
  final String hint;
  final int value;
  final String unit;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(hint, style: TextStyle(fontSize: 12, color: scheme.outline)),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final t = await promptText(context,
                title: label,
                initial: value.toString(),
                keyboard: TextInputType.number);
            final n = int.tryParse((t ?? '').trim());
            if (n != null) onChanged(n < min ? min : n);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('$value$unit',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 16,
              color: onTap == null ? Theme.of(context).disabledColor : null),
        ),
      );
}

// ── Kalem formu (ekle / düzenle) ────────────────────────────────────────────
class _ItemFormResult {
  _ItemFormResult({
    required this.name,
    required this.categoryId,
    this.quantity,
    this.unit,
    this.note,
    this.reminderAt,
    this.reminderEnabled = false,
    this.dueAt,
    this.delete = false,
    this.stockQty = 0,
  });
  final String name;
  final String categoryId;
  final int? quantity;
  final String? unit;
  final String? note;
  final DateTime? reminderAt;
  final bool reminderEnabled;
  final DateTime? dueAt;
  final bool delete;
  final int stockQty;
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({required this.list, this.item});
  final UserList list;
  final ListItem? item;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _qty =
      TextEditingController(text: widget.item?.quantity?.toString() ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.item?.unit ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.item?.note ?? '');
  late final TextEditingController _stock =
      TextEditingController(text: (widget.item?.stockQty ?? 0).toString());
  late String _categoryId;
  DateTime? _reminderAt;
  bool _reminderEnabled = false;
  DateTime? _dueAt;
  bool _dueSupported = false;

  bool get isEdit => widget.item != null;
  bool get _calendarSupported => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.item?.categoryId ??
        (widget.list.categories.isNotEmpty
            ? widget.list.categories.first.id
            : 'other');
    if (widget.list.categoryById(_categoryId) == null &&
        widget.list.categories.isNotEmpty) {
      _categoryId = widget.list.categories.first.id;
    }
    _reminderAt = widget.item?.reminderAt;
    _reminderEnabled = widget.item?.reminderEnabled ?? false;
    _dueAt = widget.item?.dueAt;
    _dueSupported = context
            .read<CatalogProvider>()
            .templateById(widget.list.templateId)
            ?.dueDates ??
        false;
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    _note.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Kalemi düzenle' : 'Yeni kalem',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final s in widget.list.sections)
                  for (final c in widget.list.categoriesOf(s.id))
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                          widget.list.hasSections
                              ? '${s.name} › ${c.name}'
                              : c.name,
                          overflow: TextOverflow.ellipsis),
                    ),
              ],
              onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
            ),
            const SizedBox(height: 12),
            if (!_dueSupported)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: widget.list.isInventory
                            ? 'Olması gereken'
                            : 'Miktar',
                        hintText: widget.list.isInventory ? '1' : 'boş = yok'),
                  ),
                ),
                if (widget.list.isInventory) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Stokta', hintText: '0'),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(
                          labelText: 'Birim', hintText: 'adet, kg…')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Not'),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(_reminderAt == null
                  ? 'Hatırlatıcı yok'
                  : fmtDateTime(_reminderAt!)),
              subtitle: _reminderAt == null
                  ? const Text('Tarih ve saat seçmek için dokun')
                  : null,
              trailing: _reminderAt == null
                  ? null
                  : Switch(
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v)),
              onTap: _pickReminder,
              onLongPress: _reminderAt == null
                  ? null
                  : () => setState(() {
                        _reminderAt = null;
                        _reminderEnabled = false;
                      }),
            ),
            if (_reminderAt != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _reminderAt = null;
                    _reminderEnabled = false;
                  }),
                  icon: const Icon(Icons.alarm_off, size: 18),
                  label: const Text('Hatırlatıcıyı kaldır'),
                ),
              ),
            if (_dueSupported) ...[
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(_dueAt == null
                    ? 'Tarih & saat yok'
                    : fmtDateTime(_dueAt!)),
                subtitle: Text(_dueAt == null
                    ? 'Saatli görev — seçmek için dokun'
                    : 'Zamanı gelince bildirim gönderilir'),
                onTap: _pickDue,
                trailing: _dueAt == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Tarihi kaldır',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _dueAt = null)),
              ),
              if (isEdit && _dueAt != null && _calendarSupported)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _exportToCalendar(_dueAt!),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Telefon takvimine ekle'),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (isEdit)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () => Navigator.pop(
                        context,
                        _ItemFormResult(
                            name: '', categoryId: '', delete: true)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Çıkar'),
                  ),
                const Spacer(),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal')),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: _save, child: Text(isEdit ? 'Kaydet' : 'Ekle')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('tr', 'TR'),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _reminderAt ?? DateTime(now.year, now.month, now.day, 10)),
    );
    if (t == null) return;
    final at = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      _reminderAt = at;
      _reminderEnabled = at.isAfter(DateTime.now());
    });
    if (!at.isAfter(DateTime.now()) && mounted) {
      showSnack(context, 'Geçmiş bir tarih; bildirim gönderilmeyecek.');
    }
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('tr', 'TR'),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _dueAt ?? DateTime(now.year, now.month, now.day, 10)),
    );
    if (t == null) return;
    setState(() => _dueAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _exportToCalendar(DateTime at) async {
    try {
      final name = _name.text.trim();
      await Add2Calendar.addEvent2Cal(Event(
        title: name.isEmpty ? widget.list.name : name,
        description: 'Liste Asistanı · ${widget.list.name}',
        startDate: at,
        endDate: at.add(const Duration(minutes: 30)),
      ));
    } catch (e) {
      if (mounted) showSnack(context, 'Takvim açılamadı: $e');
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Ad boş olamaz');
      return;
    }
    final qty = int.tryParse(_qty.text.trim());
    final stock = (int.tryParse(_stock.text.trim()) ?? 0).clamp(0, 9999);
    final unit = _unit.text.trim();
    final note = _note.text.trim();
    Navigator.pop(
      context,
      _ItemFormResult(
        name: name,
        categoryId: _categoryId,
        quantity: _dueSupported ? null : qty,
        stockQty: stock,
        unit: _dueSupported || unit.isEmpty ? null : unit,
        note: note.isEmpty ? null : note,
        reminderAt: _reminderAt,
        reminderEnabled: _reminderEnabled && _reminderAt != null,
        dueAt: _dueAt,
      ),
    );
  }
}

/// Kenarlıksız, 24 yarıçaplı giriş çerçevesi
class OutlinedBorderless {
  static final r24 = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none);
}

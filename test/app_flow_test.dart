import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liste_asistani/core/utils.dart';
import 'package:liste_asistani/data/storage.dart';
import 'package:liste_asistani/data/template_repository.dart';
import 'package:liste_asistani/main.dart';
import 'package:liste_asistani/models/template.dart';
import 'package:liste_asistani/providers/catalog_provider.dart';
import 'package:liste_asistani/providers/lists_provider.dart';
import 'package:liste_asistani/providers/settings_provider.dart';
import 'package:liste_asistani/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uçtan uca akış: ana ekran -> şablon seç -> form -> öneri -> liste -> işaretle -> kalıcılık.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(CatalogProvider, ListsProvider, Widget)> buildApp() async {
    await initializeDateFormatting('tr_TR');
    final storage = await Storage.open();
    final settings = SettingsProvider(storage);
    final catalog = CatalogProvider(storage, TemplateRepository());
    final lists = ListsProvider(storage, NotificationService.instance);
    await catalog.init();
    await lists.init();
    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: lists),
      ],
      child: const ListeAsistaniApp(),
    );
    return (catalog, lists, app);
  }

  testWidgets('market listesi oluşturma akışı', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final (catalog, lists, app) = await buildApp();
    expect(catalog.templates.length, 9);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text('Henüz liste yok'), findsOneWidget);

    // Yeni liste -> şablon seçici
    await tester.tap(find.text('Yeni Liste'));
    await tester.pumpAndSettle();
    expect(find.text('Ne listesi hazırlıyoruz?'), findsOneWidget);

    // Market'i seç
    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Market'), findsOneWidget);

    // Market'te soru ve tarih yok: doğrudan öner
    expect(find.text('Evet'), findsNothing);
    await tester.tap(find.text('Listeyi Öner'));
    await tester.pumpAndSettle();
    expect(find.text('Listeni gözden geçir'), findsOneWidget);
    // Hiçbir kalem ön seçili değil
    expect(find.textContaining('İstediklerini işaretle'), findsOneWidget);

    // Ara ve iki kalem seç; birinin adedini artır
    await tester.enterText(find.byType(TextField).first, 'süt');
    await tester.pumpAndSettle();
    final sutTile = find
        .ancestor(of: find.text('Süt'), matching: find.byType(InkWell))
        .first;
    expect(sutTile, findsOneWidget);
    await tester.tap(sutTile);
    await tester.pumpAndSettle();
    expect(find.text('1 kalem seçili'), findsOneWidget);
    // adet artır (+ düğmesi, 'Artır' tooltip)
    final plus =
        find.descendant(of: sutTile, matching: find.byTooltip('Artır'));
    await tester.tap(plus);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ekmek');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ekmek').first);
    await tester.pumpAndSettle();
    expect(find.text('2 kalem seçili'), findsOneWidget);

    // Oluştur
    await tester.tap(find.text('Listeyi Oluştur'));
    await tester.pumpAndSettle();

    // Detay ekranı
    expect(lists.all.length, 1);
    final list = lists.all.first;
    expect(list.templateId, 'market');
    expect(list.items.map((i) => i.name).toList(), ['Süt', 'Ekmek']);
    expect(list.quickAdd, isTrue);
    final sut = list.items.firstWhere((i) => i.name == 'Süt');
    expect(sut.quantity, 2, reason: 'öneri ekranında adet 1→2 yapıldı');
    expect(list.startDate, isNull);
    // Market stok listesi: başlık "stokta", eksik rozeti görünür
    expect(find.textContaining('stokta'), findsWidgets);
    expect(find.textContaining('eksik'), findsWidgets);

    // Hızlı ekleme çubuğu: katalogdan eşleşen kalem
    final quick = find.widgetWithText(TextField, 'Hızlı ekle: süt, ekmek…');
    expect(quick, findsOneWidget);
    await tester.enterText(quick, 'Domates');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(lists.all.first.items.length, 3);
    final domates =
        lists.all.first.items.firstWhere((i) => i.name == 'Domates');
    expect(domates.catalogId, 'tomato', reason: 'katalogla eşleşmeli');
    expect(domates.categoryId, 'produce');
    // Serbest metin → Diğer kategorisi
    await tester.enterText(quick, 'Kapı zili pili');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final pil =
        lists.all.first.items.firstWhere((i) => i.name == 'Kapı zili pili');
    expect(pil.categoryId, 'other');
    expect(pil.isCustom, isTrue);
    // Aynı adı tekrar yazınca kopya oluşmaz
    await tester.enterText(quick, 'domates');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(lists.all.first.items.length, 4);

    // İlk kalemi işaretle
    final firstName = list.items.first.name;
    await tester.tap(find.text(firstName).first);
    await tester.pumpAndSettle();
    expect(lists.all.first.checkedCount, 1);

    // Kalıcılık: yeniden yükle
    final lists2 =
        ListsProvider(await Storage.open(), NotificationService.instance);
    await lists2.init();
    expect(lists2.all.length, 1);
    expect(lists2.all.first.checkedCount, 1);
    expect(lists2.all.first.items.length, 4);
  });

  testWidgets('seyahat: tarih aralığı miktarları etkiler, bölümler sekme olur',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final (catalog, lists, app) = await buildApp();
    final t = catalog.templateById('seyahat')!;
    final items = lists.suggestItems(
      template: t,
      answers: {
        ...t.defaultAnswers(),
        'tripType': 'international'
      },
      days: 7,
      isDisabled: (_) => false,
      eventDate: DateTime.now().add(const Duration(days: 30)),
    );
    final socks = items.firstWhere((i) => i.catalogId == 'socks');
    expect(socks.quantity, 7);
    final visa = items.firstWhere((i) => i.catalogId == 'prep_visa');
    expect(visa.reminderAt, isNotNull,
        reason: 'daysBefore olan hazırlıklara tarih önerilir');
    expect(visa.reminderEnabled, isFalse,
        reason: 'kullanıcı açmadan bildirim kurulmaz');

    final created = await lists.createList(
      template: t,
      name: 'Roma Seyahati',
      fields: {'from': 'İstanbul', 'to': 'Roma'},
      answers: {
        ...t.defaultAnswers(),
        'tripType': 'international'
      },
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 36)),
      items: items,
    );
    expect(created.hasSections, isTrue);
    expect(created.subtitle, contains('İstanbul → Roma'));

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text('Roma Seyahati'), findsOneWidget);
    await tester.tap(find.text('Roma Seyahati'));
    await tester.pumpAndSettle();
    // Üç bölüm sekmesi
    expect(find.textContaining('Valiz'), findsWidgets);
    expect(find.textContaining('Ev Kontrolleri'), findsWidgets);
    expect(find.textContaining('Hazırlıklar'), findsWidgets);

    // Hazırlıklar sekmesine geç
    final tab = find.textContaining('Hazırlıklar').first;
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
    expect(find.text('Vize başvurusu / e-vize al'), findsOneWidget);

    // Paylaşım metni
    final txt = lists.shareText(created);
    expect(txt, contains('Roma Seyahati'));
    expect(txt, contains('VALİZ'));
    expect(txt, contains('☐ Pasaport'));

    // Kopyala / arşivle / sil
    final copy = await lists.duplicate(created.id);
    expect(copy!.name, 'Roma Seyahati (kopya)');
    await lists.setArchived(copy.id, true);
    expect(lists.archived.length, 1);
    await lists.delete(copy.id);
    expect(lists.all.length, 1);
  });

  testWidgets('özel liste tipi ve katalog kalemi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (catalog, lists, _) = await buildApp();
    final t = await catalog.addCustomTemplate(const ListTemplate(
      id: 'tmp',
      name: 'Spor Çantası',
      icon: 'fitness_center',
      color: '#E53935',
      sections: [TemplateSection(id: 'main', name: 'Liste', icon: 'checklist')],
      categories: [
        TemplateCategory(
            id: 'gear',
            name: 'Ekipman',
            icon: 'backpack',
            color: '#E53935',
            section: 'main')
      ],
    ));
    expect(t.isCustom, isTrue);
    await catalog.addCustomItem(
        t.id, const CatalogItem(id: 'x', name: 'Raket', category: 'gear'));
    await catalog.addCustomItem(
        t.id, const CatalogItem(id: 'x', name: 'Havlu', category: 'gear'));
    final withItems = catalog.templateById(t.id)!;
    expect(withItems.items.length, 2);
    expect(withItems.items.map((i) => i.id).toSet().length, 2,
        reason: 'benzersiz id üretilmeli');

    // Pasife alma
    await catalog.setItemEnabled(t.id, withItems.items.first.id, false);
    final suggested = lists.suggestItems(
        template: withItems,
        answers: {},
        days: 1,
        isDisabled: (id) => catalog.isDisabled(t.id, id));
    expect(suggested.length, 1);

    // Kalıcılık
    final storage = await Storage.open();
    final catalog2 = CatalogProvider(storage, TemplateRepository());
    await catalog2.init();
    expect(catalog2.templateById(t.id)!.items.length, 2);
    expect(catalog2.disabledCount(t.id), 1);

    await catalog2.deleteCustomTemplate(t.id);
    expect(catalog2.templateById(t.id), isNull);
  });

  testWidgets('stok listesi: eksikler markete aktarılır, kopya oluşmaz',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (catalog, lists, _) = await buildApp();
    final piknik = catalog.templateById('piknik')!;
    expect(piknik.isInventory, isTrue);

    final items = lists.suggestItems(
        template: piknik,
        answers: piknik.defaultAnswers(),
        days: 1,
        isDisabled: (_) => false);
    final p = await lists.createList(
        template: piknik,
        name: 'Hafta sonu pikniği',
        fields: const {},
        answers: piknik.defaultAnswers(),
        items: items);
    expect(p.isInventory, isTrue);
    expect(p.missingCount, p.totalCount, reason: 'başta her şey eksik');

    // Hepsini stokta işaretle, sonra ikisini eksilt
    await lists.setAllStock(p.id, true);
    expect(lists.byId(p.id)!.missingCount, 0);
    final charcoal =
        lists.byId(p.id)!.items.firstWhere((i) => i.catalogId == 'charcoal');
    final water =
        lists.byId(p.id)!.items.firstWhere((i) => i.catalogId == 'water');
    await lists.setStock(p.id, charcoal.id, 0);
    await lists.setStock(p.id, water.id, water.needQty - 1);
    expect(lists.byId(p.id)!.missingCount, 2);

    // Stokta/yok hızlı geçiş
    await lists.toggleStock(p.id, charcoal.id);
    expect(
        lists.byId(p.id)!.items.firstWhere((i) => i.id == charcoal.id).inStock,
        isTrue);
    await lists.toggleStock(p.id, charcoal.id);
    expect(lists.byId(p.id)!.missingCount, 2);

    // Hedef + stok birlikte: 5 olması gereken, 4 var → 1 eksik
    final lighter =
        lists.byId(p.id)!.items.firstWhere((i) => i.catalogId == 'lighter');
    expect(lighter.needQty, 1);
    await lists.setStockLevels(p.id, lighter.id, need: 5, stock: 4);
    final l2 = lists.byId(p.id)!.items.firstWhere((i) => i.id == lighter.id);
    expect(l2.quantity, 5);
    expect(l2.stockQty, 4);
    expect(l2.isMissing, isTrue);
    expect(l2.toBuy, 1);
    expect(lists.byId(p.id)!.missingCount, 3);
    await lists.setStockLevels(p.id, lighter.id, need: 5, stock: 5);
    expect(lists.byId(p.id)!.missingCount, 2);

    // Hedef: boş market listesi
    final market = catalog.templateById('market')!;
    final m = await lists.createList(
        template: market,
        name: 'Market',
        fields: const {},
        answers: market.defaultAnswers(),
        items: const []);
    expect(lists.transferTargets(p.id).map((l) => l.id), contains(m.id));
    expect(lists.transferTargets(p.id).map((l) => l.id), isNot(contains(p.id)));

    final n1 = await lists.transferMissing(p.id, m.id);
    expect(n1, 2);
    var target = lists.byId(m.id)!;
    expect(target.items.length, 2);
    final waterInMarket = target.items
        .firstWhere((i) => normalizeTr(i.name) == normalizeTr(water.name));
    expect(waterInMarket.quantity, 1, reason: 'sadece eksik kadar');
    // Kategori eşlemesi: piknik 'drinks' market'te de var → aynı kategori
    expect(waterInMarket.categoryId, 'drinks');
    // 'bbq' market'te yok → aktarma kategorisi eklenir
    final charcoalInMarket = target.items
        .firstWhere((i) => normalizeTr(i.name) == normalizeTr(charcoal.name));
    expect(charcoalInMarket.categoryId, ListsProvider.transferCategoryId);
    expect(target.categoryById(ListsProvider.transferCategoryId), isNotNull);

    // İkinci aktarma kopya üretmez, miktarı günceller
    await lists.setStock(p.id, water.id, 0);
    final n2 = await lists.transferMissing(p.id, m.id);
    expect(n2, 2);
    target = lists.byId(m.id)!;
    expect(target.items.length, 2, reason: 'kopya oluşmamalı');
    expect(
        target.items
            .firstWhere((i) => normalizeTr(i.name) == normalizeTr(water.name))
            .quantity,
        water.needQty);

    // Paylaşım: sadece eksikler
    final txt = lists.shareText(lists.byId(p.id)!, onlyMissing: true);
    expect(txt, contains('Eksikler (2 kalem)'));
    expect(txt, contains(charcoal.name));

    // Favori sıralaması
    await lists.setFavorite(m.id, true);
    expect(lists.active.first.id, m.id);

    // Kopya stokları korur
    final copy = await lists.duplicate(p.id);
    expect(copy!.missingCount, 2);
    expect(copy.isInventory, isTrue);
  });
}

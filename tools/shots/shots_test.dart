// Tasarım önizlemesi: ekranları PNG olarak üretir.
// Çalıştırma: flutter test tools/shots/shots_test.dart --update-goldens
// Çıktılar: tools/shots/out/*.png
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liste_asistani/data/storage.dart';
import 'package:liste_asistani/data/template_repository.dart';
import 'package:liste_asistani/main.dart';
import 'package:liste_asistani/providers/catalog_provider.dart';
import 'package:liste_asistani/providers/lists_provider.dart';
import 'package:liste_asistani/providers/settings_provider.dart';
import 'package:liste_asistani/screens/list_detail_screen.dart';
import 'package:liste_asistani/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final manrope = FontLoader('Manrope');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    manrope.addFont(rootBundle.load('assets/fonts/Manrope-$w.ttf'));
  }
  await manrope.load();
  // Material ikonları: SDK önbelleğinden
  final root =
      Platform.environment['FLUTTER_ROOT'] ?? '/home/user/.local/fl/flutter';
  final f = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (f.existsSync()) {
    final bytes = f.readAsBytesSync();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await icons.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(CatalogProvider, ListsProvider, SettingsProvider, Widget)> buildApp(
      ThemeMode mode) async {
    await initializeDateFormatting('tr_TR');
    final storage = await Storage.open();
    final settings = SettingsProvider(storage);
    await settings.setThemeMode(mode);
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
    return (catalog, lists, settings, app);
  }

  Future<void> seed(CatalogProvider catalog, ListsProvider lists) async {
    final now = DateTime.now();
    final seyahat = catalog.templateById('seyahat')!;
    final s =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 9));
    final e = s.add(const Duration(days: 4));
    final answers = seyahat.defaultAnswers()..['purpose'] = 'beach';
    final sug = lists.suggestItems(
        template: seyahat,
        answers: answers,
        days: 5,
        isDisabled: (_) => false,
        eventDate: s);
    final l1 = await lists.createList(
        template: seyahat,
        name: 'Antalya Seyahati',
        fields: {'to': 'Antalya'},
        answers: answers,
        startDate: s,
        endDate: e,
        items: sug);
    for (final i in l1.items.take(9)) {
      await lists.toggleItem(l1.id, i.id);
    }
    await lists.setFavorite(l1.id, true);

    final mangal = catalog.templateById('mangal')!;
    final msug = lists.suggestItems(
        template: mangal,
        answers: mangal.defaultAnswers(),
        days: 1,
        isDisabled: (_) => false,
        eventDate: null);
    final l2 = await lists.createList(
        template: mangal,
        name: 'Hafta sonu mangal',
        fields: {},
        answers: {},
        startDate: null,
        endDate: null,
        items: msug);
    var k = 0;
    for (final i in l2.items) {
      if (k++ % 3 != 0) await lists.setStock(l2.id, i.id, 1);
    }

    final market = catalog.templateById('market')!;
    final picks = market.items
        .where(
            (i) => ['milk', 'bread', 'eggs', 'tomato', 'yogurt'].contains(i.id))
        .toList();
    final msel = lists.suggestItems(
        template: market,
        answers: {},
        days: 1,
        isDisabled: (_) => false,
        eventDate: null);
    final chosen =
        msel.where((i) => picks.any((p) => p.id == i.catalogId)).toList();
    final l3 = await lists.createList(
        template: market,
        name: 'Market',
        fields: {},
        answers: {},
        startDate: null,
        endDate: null,
        items: chosen);
    await lists.quickAdd(l3.id, 'Zeytin', template: market);
    await lists.quickAdd(l3.id, 'Kapı zili pili', template: market);
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final tag = mode == ThemeMode.light ? 'light' : 'dark';
    testWidgets('shots $tag', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _loadFonts();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      final (catalog, lists, settings, app) = await buildApp(mode);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await expectLater(
          find.byType(MaterialApp), matchesGoldenFile('out/00_empty_$tag.png'));

      await seed(catalog, lists);
      await tester.pumpAndSettle();
      await expectLater(
          find.byType(MaterialApp), matchesGoldenFile('out/01_home_$tag.png'));

      // Şablon seçici
      await tester.tap(find.text('Yeni Liste'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/02_picker_$tag.png'));

      // Oluşturma formu
      await tester.tap(find.text('Seyahat'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/03_create_$tag.png'));

      // Öneri ekranı
      await tester.tap(find.text('Listeyi Öner'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/04_selection_$tag.png'));

      // Detay: seyahat
      final nav = navigatorKey.currentState!;
      nav.popUntil((r) => r.isFirst);
      await tester.pumpAndSettle();
      final l1 = lists.active.firstWhere((l) => l.templateId == 'seyahat');
      nav.push(
          MaterialPageRoute(builder: (_) => ListDetailScreen(listId: l1.id)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/05_detail_seyahat_$tag.png'));

      // Detay: mangal (stok)
      nav.pop();
      await tester.pumpAndSettle();
      final l2 = lists.active.firstWhere((l) => l.templateId == 'mangal');
      nav.push(
          MaterialPageRoute(builder: (_) => ListDetailScreen(listId: l2.id)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/06_detail_mangal_$tag.png'));

      // Detay: market (hızlı ekle)
      nav.pop();
      await tester.pumpAndSettle();
      final l3 = lists.active.firstWhere((l) => l.templateId == 'market');
      nav.push(
          MaterialPageRoute(builder: (_) => ListDetailScreen(listId: l3.id)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/07_detail_market_$tag.png'));

      // Alışveriş modu (market)
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alışveriş modu'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/09_shopping_$tag.png'));
      nav.pop();
      await tester.pumpAndSettle();

      // Ayarlar
      nav.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('out/08_settings_$tag.png'));
    });
  }
}

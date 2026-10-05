import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liste_asistani/core/app_icons.dart';
import 'package:liste_asistani/core/utils.dart';
import 'package:liste_asistani/data/template_repository.dart';
import 'package:liste_asistani/models/template.dart';

/// Yerleşik katalogların bütünlüğünü doğrular (JSON dosyaları elle bozulursa burada yakalanır).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tüm yerleşik şablonlar yüklenir ve tutarlıdır', () async {
    final templates = await TemplateRepository().loadBuiltIn();
    expect(templates.length, 9);
    expect(
        templates.map((t) => t.id),
        containsAll([
          'seyahat',
          'market',
          'piknik',
          'mangal',
          'kamp',
          'plaj',
          'tasinma',
          'is',
          'gundelik'
        ]));
    expect(templates.map((t) => t.id), isNot(contains('hastane')));
    // Malzeme listeleri stok modunda, diğerleri kontrol listesi
    for (final t in templates) {
      final expectInv =
          const {'market', 'piknik', 'kamp', 'mangal'}.contains(t.id);
      expect(t.isInventory, expectInv, reason: '${t.id} kind');
      // Bebek / evcil hayvan soruları ve kalemleri kaldırıldı
      for (final f in t.filters) {
        expect(f.id, isNot(anyOf('baby', 'pet')), reason: '${t.id} filtre');
      }
      for (final i in t.items) {
        expect(normalizeTr(i.name), isNot(contains('evcil')),
            reason: '${t.id}: ${i.id}');
        expect(normalizeTr(i.name), isNot(contains('bebek')),
            reason: '${t.id}: ${i.id}');
      }
    }
    // Market: pratik — soru yok, tarih yok, öneriler seçimsiz, hızlı ekleme var
    final market = templates.firstWhere((t) => t.id == 'market');
    expect(market.filters, isEmpty);
    expect(market.textFields, isEmpty);
    expect(market.dateMode, DateMode.none);
    expect(market.preselect, isFalse);
    expect(market.quickAdd, isTrue);
    // Mangal: tam olarak kullanıcının listesi
    final mangal = templates.firstWhere((t) => t.id == 'mangal');
    expect(mangal.items.length, 38);
    expect(mangal.categories.length, 7);
    expect(mangal.filters, isEmpty);
    expect(mangal.items.map((i) => i.name), contains('Streç film'));

    var total = 0;
    for (final t in templates) {
      total += t.items.length;
      final secIds = t.sections.map((s) => s.id).toSet();
      final catIds = t.categories.map((c) => c.id).toSet();
      final filters = {
        for (final f in t.filters) f.id: f.options.map((o) => o.id).toSet()
      };
      final ids = <String>{};
      for (final c in t.categories) {
        expect(secIds, contains(c.section),
            reason: '${t.id}: kategori ${c.id} bölümü yok');
      }
      for (final f in t.filters) {
        expect(filters[f.id], contains(f.defaultOption),
            reason: '${t.id}: filtre ${f.id} varsayılanı');
      }
      for (final i in t.items) {
        expect(ids.add(i.id), isTrue, reason: '${t.id}: tekrar id ${i.id}');
        expect(catIds, contains(i.category),
            reason: '${t.id}: ${i.id} kategorisi yok');
        for (final block in i.when.blocks) {
          for (final e in block.entries) {
            expect(filters.keys, contains(e.key),
                reason: '${t.id}: ${i.id} filtre ${e.key}');
            for (final v in e.value) {
              expect(filters[e.key], contains(v),
                  reason: '${t.id}: ${i.id} seçenek $v');
            }
          }
        }
      }
      // varsayılan cevaplarla en az bir öneri çıkmalı
      final answers = t.defaultAnswers();
      final suggested = t.items.where((i) => i.when.matches(answers)).length;
      expect(suggested, greaterThan(t.filters.isEmpty ? 0 : 10),
          reason: '${t.id}: varsayılan cevaplarla çok az öneri');
    }
    expect(total, greaterThan(900));
  });

  test('kullanılan tüm ikon adları AppIcons içinde tanımlı', () async {
    final raw = await rootBundle.loadString('assets/data/templates/index.json');
    final ids = (jsonDecode(raw) as List).cast<String>();
    for (final id in ids) {
      final t = ListTemplate.fromJson(jsonDecode(
          await rootBundle.loadString('assets/data/templates/$id.json')));
      final names = <String>{
        t.icon,
        ...t.sections.map((s) => s.icon),
        ...t.categories.map((c) => c.icon)
      };
      for (final f in t.filters) {
        for (final o in f.options) {
          if (o.icon != null) names.add(o.icon!);
        }
      }
      for (final n in names) {
        expect(AppIcons.has(n), isTrue, reason: '$id: ikon $n tanımsız');
      }
    }
  });

  test('seyahat: filtreler beklendiği gibi çalışır', () async {
    final t = (await TemplateRepository().loadBuiltIn())
        .firstWhere((t) => t.id == 'seyahat');
    Set<String> ids(Map<String, String> a) =>
        t.items.where((i) => i.when.matches(a)).map((i) => i.id).toSet();
    final base =
        t.defaultAnswers(); // erkek, yaz, uçak, yurt içi, tatil, çocuk yok
    final man = ids(base);
    expect(man, contains('tshirt_m'));
    expect(man, isNot(contains('bra')));
    expect(man, isNot(contains('passport')));
    expect(man, isNot(contains('kids_headphones')));
    expect(man, contains('boardingpass'));
    expect(man, isNot(contains('car_registration')));

    final intl = ids({...base, 'tripType': 'international'});
    expect(intl, contains('passport'));
    expect(intl, contains('prep_visa'));

    final car = ids({...base, 'transport': 'car'});
    expect(car, contains('car_registration'));
    expect(car, isNot(contains('boardingpass')));

    final kids = ids({...base, 'kids': 'yes'});
    expect(kids, contains('kids_headphones'));
    expect(kids, contains('kid_id'));

    final ski = ids({...base, 'season': 'winter', 'purpose': 'ski'});
    expect(ski, contains('ski_jacket'));
    expect(ski, contains('thermal_top'));
    expect(ski, isNot(contains('bikini')));

    final beachAutumn = ids({...base, 'season': 'autumn', 'purpose': 'beach'});
    expect(beachAutumn, contains('swimsuit_m'),
        reason: 'deniz tatilinde mevsim ne olursa olsun mayo');

    final couple = ids({...base, 'gender': 'couple'});
    expect(couple, contains('bra'));
    expect(couple, contains('boxer'));
  });
}

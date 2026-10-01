import 'package:flutter_test/flutter_test.dart';
import 'package:liste_asistani/core/utils.dart';
import 'package:liste_asistani/models/template.dart';
import 'package:liste_asistani/models/user_list.dart';

void main() {
  group('Condition', () {
    test('boş koşul her zaman eşleşir', () {
      expect(const Condition.always().matches({'gender': 'male'}), isTrue);
      expect(Condition.fromJson(null).isAlways, isTrue);
    });
    test('tek blok: filtreler VE, seçenekler VEYA', () {
      final c = Condition.fromJson({
        'gender': ['male', 'couple'],
        'season': ['winter']
      });
      expect(c.matches({'gender': 'male', 'season': 'winter'}), isTrue);
      expect(c.matches({'gender': 'couple', 'season': 'winter'}), isTrue);
      expect(c.matches({'gender': 'female', 'season': 'winter'}), isFalse);
      expect(c.matches({'gender': 'male', 'season': 'summer'}), isFalse);
      expect(c.matches({'gender': 'male'}), isFalse,
          reason: 'eksik cevap eşleşmez');
    });
    test('çoklu blok: VEYA', () {
      final c = Condition.fromJson([
        {
          'season': ['summer']
        },
        {
          'purpose': ['beach']
        }
      ]);
      expect(c.matches({'season': 'summer', 'purpose': 'leisure'}), isTrue);
      expect(c.matches({'season': 'winter', 'purpose': 'beach'}), isTrue);
      expect(c.matches({'season': 'winter', 'purpose': 'ski'}), isFalse);
    });
    test('JSON gidiş-dönüş', () {
      final c = Condition.fromJson([
        {
          'a': ['x']
        },
        {
          'b': ['y', 'z']
        }
      ]);
      final again = Condition.fromJson(c.toJson());
      expect(again.blocks, equals(c.blocks));
      final single = Condition.fromJson({
        'a': ['x']
      });
      expect(single.toJson(), isA<Map>());
    });
  });

  group('QtyRule', () {
    test('gün başına hesap ve üst sınır', () {
      const socks = QtyRule(base: 0, perDay: 1, max: 10);
      expect(socks.compute(3), 3);
      expect(socks.compute(30), 10);
      expect(socks.compute(0), 1, reason: 'en az 1');
      const tshirt = QtyRule(base: 0, perDay: 0.7, max: 7);
      expect(tshirt.compute(5), 4); // ceil(3.5)
      const pants = QtyRule(base: 1, perDay: 0.2, max: 4);
      expect(pants.compute(7), 3); // 1 + ceil(1.4)
    });
  });

  group('Template JSON', () {
    test('şablon gidiş-dönüş', () {
      const t = ListTemplate(
        id: 'x',
        name: 'X',
        icon: 'list_alt',
        color: '#112233',
        dateMode: DateMode.range,
        filters: [
          FilterDef(
              id: 'f',
              label: 'F',
              question: 'Q?',
              options: [FilterOption(id: 'a', label: 'A')],
              defaultOption: 'a')
        ],
        sections: [TemplateSection(id: 'main', name: 'Ana', icon: 'checklist')],
        categories: [
          TemplateCategory(
              id: 'c',
              name: 'C',
              icon: 'category',
              color: '#000000',
              section: 'main')
        ],
        items: [
          CatalogItem(
              id: 'i',
              name: 'I',
              category: 'c',
              qty: QtyRule(base: 2),
              unit: 'kg',
              essential: true,
              daysBefore: 3)
        ],
      );
      final back = ListTemplate.fromJson(t.toJson());
      expect(back.id, 'x');
      expect(back.dateMode, DateMode.range);
      expect(back.filters.single.defaultOption, 'a');
      expect(back.items.single.qty!.base, 2);
      expect(back.items.single.unit, 'kg');
      expect(back.items.single.essential, isTrue);
      expect(back.items.single.daysBefore, 3);
      expect(back.defaultAnswers(), {'f': 'a'});
    });
    test('bozuk kayıt listeyi düşürmez', () {
      final t = ListTemplate.fromJson({
        'id': 'x',
        'name': 'X',
        'icon': 'list_alt',
        'color': '#000',
        'sections': [
          {'id': 'main', 'name': 'M', 'icon': 'x'}
        ],
        'categories': [],
        'items': [
          {'id': 'ok', 'name': 'Ok', 'category': 'c'},
          {'name': 'id yok'},
          'string',
        ],
      });
      expect(t.items.length, 1);
    });
  });

  group('UserList', () {
    UserList mk({DateTime? s, DateTime? e, List<ListItem> items = const []}) =>
        UserList(
          id: 'l',
          templateId: 't',
          templateName: 'T',
          icon: 'list_alt',
          color: '#000000',
          name: 'L',
          startDate: s,
          endDate: e,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          sections: const [TemplateSection(id: 'main', name: 'M', icon: 'x')],
          categories: const [
            TemplateCategory(
                id: 'c',
                name: 'C',
                icon: 'x',
                color: '#000000',
                section: 'main')
          ],
          items: items,
        );
    test('gün sayısı', () {
      expect(mk().days, 1);
      expect(mk(s: DateTime(2026, 1, 1), e: DateTime(2026, 1, 3)).days, 3);
      expect(mk(s: DateTime(2026, 1, 5), e: DateTime(2026, 1, 3)).days, 1);
    });
    test('ilerleme ve JSON', () {
      final l = mk(items: const [
        ListItem(
            id: 'a',
            name: 'A',
            categoryId: 'c',
            isChecked: true,
            quantity: 2,
            unit: 'adet'),
        ListItem(id: 'b', name: 'B', categoryId: 'c'),
      ]);
      expect(l.progress, 0.5);
      expect(l.items.first.quantityLabel, '2 adet');
      final back = UserList.fromJson(l.toJson());
      expect(back.items.length, 2);
      expect(back.checkedCount, 1);
      expect(back.itemsOfSection('main').length, 2);
    });
  });

  group('utils', () {
    test('stableHash deterministik ve pozitif', () {
      expect(stableHash('a|b'), stableHash('a|b'));
      expect(stableHash('a|b'), isNot(stableHash('b|a')));
      expect(stableHash('x') >= 0, isTrue);
    });
    test('hex renk', () {
      expect(colorToHex(colorFromHex('#1E88E5')), '#1E88E5');
    });
    test('normalizeTr', () {
      expect(normalizeTr('Şİşe Çorap'), 'sise corap');
    });
  });

  group('stok (inventory)', () {
    test('eksik / stokta / alınacak hesapları', () {
      const i = ListItem(
          id: 'a',
          name: 'Kömür',
          categoryId: 'bbq',
          quantity: 2,
          unit: 'torba');
      expect(i.needQty, 2);
      expect(i.isMissing, isTrue);
      expect(i.toBuy, 2);
      expect(i.stockLabel, '0/2 torba');
      final half = i.copyWith(stockQty: 1);
      expect(half.isMissing, isTrue);
      expect(half.toBuy, 1);
      expect(half.toBuyLabel, '1 torba');
      final full = i.copyWith(stockQty: 2);
      expect(full.inStock, isTrue);
      expect(full.toBuy, 0);
      final extra = i.copyWith(stockQty: 5);
      expect(extra.toBuy, 0, reason: 'fazla stok negatif olmamalı');
      // miktarsız kalem: gereken 1
      const noQty = ListItem(id: 'b', name: 'Maşa', categoryId: 'bbq');
      expect(noQty.needQty, 1);
      expect(noQty.isMissing, isTrue);
      expect(noQty.copyWith(stockQty: 1).inStock, isTrue);
    });

    test('UserList eksik sayacı sadece stok listesinde çalışır', () {
      final now = DateTime.now();
      const items = [
        ListItem(
            id: '1', name: 'Su', categoryId: 'c', quantity: 2, stockQty: 2),
        ListItem(id: '2', name: 'Buz', categoryId: 'c', quantity: 1),
      ];
      final inv = UserList(
          id: 'l',
          templateId: 'piknik',
          templateName: 'Piknik',
          icon: 'outdoor_grill',
          color: '#F57C00',
          name: 'P',
          kind: ListKind.inventory,
          createdAt: now,
          updatedAt: now,
          sections: const [],
          categories: const [],
          items: items);
      expect(inv.missingCount, 1);
      expect(inv.inStockCount, 1);
      final chk = inv.copyWith(kind: ListKind.checklist);
      expect(chk.missingCount, 0);
      expect(chk.isInventory, isFalse);
    });

    test('eski kayıt (kind yok): market/piknik/kamp stok modu varsayılır', () {
      final j = {
        'id': 'x',
        'templateId': 'piknik',
        'name': 'Eski',
        'items': [
          {'id': 'i', 'name': 'Kömür', 'categoryId': 'c', 'quantity': 2}
        ],
      };
      final l = UserList.fromJson(j);
      expect(l.isInventory, isTrue);
      expect(l.items.single.stockQty, 0);
      expect(l.isFavorite, isFalse);
      final l2 = UserList.fromJson({...j, 'templateId': 'seyahat'});
      expect(l2.isInventory, isFalse);
      // round-trip
      final back = UserList.fromJson(l.copyWith(isFavorite: true).toJson());
      expect(back.isFavorite, isTrue);
      expect(back.kind, ListKind.inventory);
    });
  });
}

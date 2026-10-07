import 'package:flutter_test/flutter_test.dart';
import 'package:liste_asistani/core/event_reminders.dart';
import 'package:liste_asistani/models/template.dart';
import 'package:liste_asistani/models/user_list.dart';

void main() {
  group('EventReminders.plan', () {
    final now = DateTime(2026, 10, 7, 12); // öğleden sonra

    UserList liste({
      DateTime? start,
      int adet = 3,
      int isaretli = 0,
      bool arsiv = false,
      bool stok = false,
      int stokta = 0,
      String ad = 'Antalya Seyahati',
    }) {
      final items = List.generate(adet, (i) {
        if (stok) {
          return ListItem(
              id: 'i$i',
              name: 'Kalem $i',
              categoryId: 'c',
              stockQty: i < stokta ? 5 : 0,
              quantity: 5);
        }
        return ListItem(
            id: 'i$i',
            name: 'Kalem $i',
            categoryId: 'c',
            isChecked: i < isaretli);
      });
      return UserList(
        id: 'L1',
        templateId: 'seyahat',
        templateName: 'Seyahat',
        icon: 'luggage',
        color: '#2196F3',
        name: ad,
        kind: stok ? ListKind.inventory : ListKind.checklist,
        isArchived: arsiv,
        startDate: start,
        createdAt: now,
        updatedAt: now,
        sections: [const TemplateSection(id: 'main', name: 'Liste', icon: 'checklist')],
        categories: const [],
        items: items,
      );
    }

    test('tam geri sayım: D-3, D-1, D-0 — saat 09:00', () {
      final plans = EventReminders.plan(
          liste(start: DateTime(2026, 10, 20)),
          now: now);
      expect(plans.length, 3);
      expect(plans.map((p) => p.offsetDays).toList(), [3, 1, 0]);
      expect(plans[0].at, DateTime(2026, 10, 17, 9));
      expect(plans[1].at, DateTime(2026, 10, 19, 9));
      expect(plans[2].at, DateTime(2026, 10, 20, 9));
      expect(plans.every((p) => p.at.hour == 9), isTrue);
      expect(plans[0].body, 'Antalya Seyahati: 3 gün kaldı — 3 eksik kalem');
      expect(plans[1].body, 'Yarın Antalya Seyahati! — 3 eksik kalem');
      expect(plans[2].body, 'Bugün Antalya Seyahati! — 3 eksik kalem');
    });

    test('geçmiş kalan günler elenir', () {
      // Etkinlik 2 gün sonra: D-3 (6 Eki) geçmişte kalmalı
      final plans =
          EventReminders.plan(liste(start: DateTime(2026, 10, 9)), now: now);
      expect(plans.map((p) => p.offsetDays).toList(), [1, 0]);
      expect(plans.first.at, DateTime(2026, 10, 8, 9));
    });

    test('etkinlik günü sabahı geçtiyse plan yok', () {
      expect(
          EventReminders.plan(liste(start: DateTime(2026, 10, 7)), now: now),
          isEmpty);
      // Ama günün 09:00'ı henüz geçmemişse "Bugün" bildirimi kalır
      expect(
          EventReminders.plan(liste(start: DateTime(2026, 10, 7)),
              now: DateTime(2026, 10, 7, 7)),
          hasLength(1));
    });

    test('arşivli / tarihsiz / boş liste plan üretmez', () {
      expect(
          EventReminders.plan(
              liste(start: DateTime(2026, 10, 20), arsiv: true),
              now: now),
          isEmpty);
      expect(EventReminders.plan(liste(start: null), now: now), isEmpty);
      expect(
          EventReminders.plan(
              liste(start: DateTime(2026, 10, 20), adet: 0),
              now: now),
          isEmpty);
    });

    test('eksik sayısı: kontrol ve stok listeleri', () {
      final kontrol = EventReminders.plan(
          liste(start: DateTime(2026, 10, 20), adet: 5, isaretli: 2),
          now: now);
      expect(kontrol.first.body, contains('3 eksik kalem'));
      final stok = EventReminders.plan(
          liste(
              start: DateTime(2026, 10, 20),
              adet: 5,
              stok: true,
              stokta: 2),
          now: now);
      expect(stok.first.body, contains('3 eksik kalem'));
      final hazir = EventReminders.plan(
          liste(start: DateTime(2026, 10, 20), adet: 4, isaretli: 4),
          now: now);
      expect(hazir.first.body, contains('her şey hazır!'));
    });

    test('bildirim kimlikleri kararlı ve benzersizdir', () {
      final a = EventReminders.notificationId('L1', 3);
      final b = EventReminders.notificationId('L1', 1);
      final c = EventReminders.notificationId('L2', 3);
      expect(a, EventReminders.notificationId('L1', 3));
      expect({a, b, c}.length, 3);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liste_asistani/core/utils.dart';
import 'package:liste_asistani/data/template_repository.dart';
import 'package:liste_asistani/models/user_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('Görev şablonları (İş / Gündelik)', () {
    test('yüklenir, saatli görev ve hızlı ekleme açık', () async {
      final templates = await TemplateRepository().loadBuiltIn();
      final isT = templates.firstWhere((t) => t.id == 'is');
      final g = templates.firstWhere((t) => t.id == 'gundelik');
      for (final t in [isT, g]) {
        expect(t.dueDates, isTrue, reason: t.id);
        expect(t.quickAdd, isTrue, reason: t.id);
        expect(t.isInventory, isFalse, reason: t.id);
        expect(t.filters, isEmpty, reason: '${t.id}: görev listesi soru sormaz');
        expect(t.dateMode.name, 'none', reason: t.id);
        expect(t.categories.length, greaterThanOrEqualTo(6));
        expect(t.items.length, greaterThanOrEqualTo(8));
      }
      expect(isT.categories.map((c) => c.name), contains('Toplantılar'));
      expect(g.categories.map((c) => c.name), contains('Fatura & Ödeme'));
    });
  });

  group('ListItem.dueAt', () {
    test('json tur + copyWith + temizleme', () {
      final at = DateTime(2026, 10, 6, 14, 30);
      final i = ListItem(
          id: 'x', name: 'Fatura öde', categoryId: 'bills', dueAt: at);
      final j = ListItem.fromJson(i.toJson());
      expect(j.dueAt, at);
      expect(j.hasDue, isTrue);
      expect(j.isOverdue, isFalse); // gelecek tarih
      final past = i.copyWith(dueAt: DateTime(2020, 1, 1));
      expect(past.isOverdue, isTrue);
      final cleared = past.copyWith(clearDueAt: true);
      expect(cleared.dueAt, isNull);
      expect(cleared.hasDue, isFalse);
    });

    test('eski kayıtlarda dueAt yoksa null', () {
      final i = ListItem.fromJson(
          {'id': 'a', 'name': 'x', 'categoryId': 'other'});
      expect(i.dueAt, isNull);
    });
  });

  group('dueLabel', () {
    test('bugün / yarın / gecikmiş / ileri', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(dueLabel(today), startsWith('Bugün'));
      expect(dueLabel(today.add(const Duration(days: 1))),
          startsWith('Yarın'));
      expect(dueLabel(today.subtract(const Duration(days: 2))),
          startsWith('Gecikti'));
      expect(dueLabel(today.add(const Duration(days: 5))),
          isNot(anyOf(startsWith('Bugün'), startsWith('Yarın'))));
    });
  });
}

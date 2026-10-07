import '../models/user_list.dart';
import 'utils.dart';

/// Etkinlik geri sayım bildirimi: tarihli bir listede (seyahat, mangal…)
/// etkinlikten 3 gün, 1 gün ve günün kendisinde sabah 09:00'da tetiklenir.
/// Gövde metni o anki eksik sayısını taşır; yapısal değişikliklerde
/// (liste güncelleme, arşiv, açılış…) yeniden planlanır.
class EventReminderPlan {
  const EventReminderPlan(
      {required this.offsetDays, required this.at, required this.body});

  /// Etkinlik gününden kaç gün önce (3, 1 veya 0).
  final int offsetDays;

  /// Bildirim anı (her zaman 09:00).
  final DateTime at;

  final String body;
}

class EventReminders {
  EventReminders._();

  /// Sabah bildirim saati.
  static const int hour = 9;

  /// Etkinlik gününden geriye sayım günleri.
  static const List<int> offsets = [3, 1, 0];

  /// Kalıcı bildirim kimliği (kalem bildirimlerinden farklı uzayda).
  static int notificationId(String listId, int offset) =>
      stableHash('event|$listId|$offset');

  /// Listeye göre gelecekte kalan planlar. Saf fonksiyon: `now` verilerek
  /// test edilir; arşivli, tarihsiz, boş veya etkinliği geçmiş listeler
  /// boş döner.
  static List<EventReminderPlan> plan(UserList l, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (l.isArchived || l.totalCount == 0 || l.startDate == null) {
      return const [];
    }
    final start = l.startDate!;
    final missing =
        l.isInventory ? l.missingCount : l.totalCount - l.checkedCount;
    final suffix =
        missing > 0 ? ' — $missing eksik kalem' : ' — her şey hazır!';
    final day = DateTime(start.year, start.month, start.day);
    final out = <EventReminderPlan>[];
    for (final off in offsets) {
      final at =
          DateTime(day.year, day.month, day.day, hour).subtract(Duration(days: off));
      if (!at.isAfter(n)) continue;
      final body = switch (off) {
        3 => '${l.name}: 3 gün kaldı$suffix',
        1 => 'Yarın ${l.name}!$suffix',
        _ => 'Bugün ${l.name}!$suffix',
      };
      out.add(EventReminderPlan(offsetDays: off, at: at, body: body));
    }
    return out;
  }
}

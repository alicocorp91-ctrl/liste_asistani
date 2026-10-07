import 'utils.dart';

/// Sesle işaretleme komutları: "süt aldım", "domates ve ekmek tamam",
/// "hepsini aldım". Verilen aday kalem adları arasından buyruğa uygun
/// olanları (aday sırasıyla) döndürür. Tamamen çevrimdışı, kural tabanlı.
class VoiceCheck {
  VoiceCheck._();

  /// İşaretlemeyi anlatan sözcükler (normalize edilmiş biçimde).
  static const _intent = {
    'aldim',
    'aldik',
    'aldigimi',
    'tamam',
    'tamamdir',
    'bitti',
    'bitirdim',
    'hazir',
    'girdim',
    'isaretledim',
    'yerlestirdim',
  };

  /// "Tümünü" kapsayan sözcükler.
  static const _all = {
    'hepsi',
    'hepsini',
    'hepsine',
    'tumu',
    'tumunu',
    'toplu',
  };

  static List<String> _words(String utterance) => normalizeTr(utterance)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  /// Cümle bir işaretleme buyruğu mu? ("süt aldım", "ekmek tamam")
  static bool isIntent(String utterance) =>
      _words(utterance).any(_intent.contains);

  /// "hepsini aldım" / "hepsi tamam" → kalanların tamamı.
  static bool wantsAll(String utterance) {
    final w = _words(utterance);
    return w.any(_intent.contains) && w.any(_all.contains);
  }

  /// Buyruk varsa adaylardan eşleşenleri **aday sırasıyla** döndürür.
  static List<String> match(String utterance, Iterable<String> candidates) {
    final cand = candidates.toList();
    if (cand.isEmpty || !isIntent(utterance)) return const [];
    final words = _words(utterance);
    final t = normalizeTr(utterance);
    final matched = <String>{};

    // Çok kelimeli adaylar: "kaşar peyniri aldım" → "kaşar peyniri"
    for (final name in cand) {
      if (normalizeTr(name).contains(' ') && _matchesMulti(t, name)) {
        matched.add(name);
      }
    }

    // Tek kelimeli adaylar: her sözcük için EN UZUN eşleşen aday
    // ("sütlaç" → "Sütlaç", "Süt" değil).
    for (final w in words) {
      if (_intent.contains(w) || _all.contains(w)) continue;
      String? best;
      for (final name in cand) {
        final cn = normalizeTr(name);
        if (cn.isEmpty || cn.contains(' ')) continue;
        if (w.startsWith(cn) && (best == null || cn.length > normalizeTr(best).length)) {
          best = name;
        }
      }
      if (best != null) matched.add(best);
    }

    // Birlikte eşleşen kısa/uzun önekleri ayıkla: "Kaşar" + "Kaşar Peyniri"
    // birlikte geldiyse yalnızca uzun olan kalsın.
    matched.removeWhere((m) {
      final cm = normalizeTr(m);
      return matched.any((o) =>
          o != m && normalizeTr(o).startsWith('$cm '));
    });

    return cand.where(matched.contains).toList();
  }

  /// Çok kelimeli aday eşleşmesi: ilk kelimeler ardışık, son kelime sonekli
  /// olabilir ("kaşar peynirini aldım" → "kaşar peyniri").
  static bool _matchesMulti(String t, String name) {
    final parts = normalizeTr(name).trim().split(RegExp(r'\s+'));
    final head = parts.sublist(0, parts.length - 1).join(' ');
    final tail = parts.last;
    final idx = t.indexOf(head);
    if (idx < 0) return false;
    final rest = t
        .substring(idx + head.length)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return rest.isNotEmpty && rest.first.startsWith(tail);
  }
}

import 'utils.dart';

/// Sesle söylenen bir cümleden çıkarılan tek kalem.
class VoiceEntry {
  const VoiceEntry({required this.name, this.quantity, this.unit});
  final String name;
  final int? quantity;
  final String? unit;

  String get label {
    if (quantity == null) return name;
    final u = unit == null || unit!.isEmpty ? '' : ' $unit';
    return '$name ×$quantity$u'.replaceFirst('×$quantity adet', '×$quantity');
  }

  @override
  String toString() => 'VoiceEntry($name, $quantity, $unit)';

  @override
  bool operator ==(Object other) =>
      other is VoiceEntry &&
      other.name == name &&
      other.quantity == quantity &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(name, quantity, unit);
}

/// "zeytin, iki ekmek, bir kilo domates ve yarım litre süt ekle" gibi
/// Türkçe bir cümleyi kalemlere ayırır. Tamamen çevrimdışı, kural tabanlı.
class VoiceParser {
  VoiceParser._();

  static const _numberWords = <String, int>{
    'sıfır': 0,
    'bir': 1,
    'iki': 2,
    'üç': 3,
    'dört': 4,
    'beş': 5,
    'altı': 6,
    'yedi': 7,
    'sekiz': 8,
    'dokuz': 9,
    'on': 10,
    'yirmi': 20,
    'otuz': 30,
    'kırk': 40,
    'elli': 50,
    'altmış': 60,
    'yetmiş': 70,
    'seksen': 80,
    'doksan': 90,
    'yüz': 100,
    'bin': 1000,
  };

  /// Söylenen birim → listede kullanılan birim. Değer null ise "adet" sayılır.
  static const _units = <String, String>{
    'kilo': 'kg',
    'kilogram': 'kg',
    'kg': 'kg',
    'gram': 'g',
    'gr': 'g',
    'g': 'g',
    'litre': 'L',
    'lt': 'L',
    'l': 'L',
    'mililitre': 'ml',
    'ml': 'ml',
    'paket': 'paket',
    'kutu': 'kutu',
    'şişe': 'şişe',
    'demet': 'demet',
    'poşet': 'poşet',
    'kavanoz': 'kavanoz',
    'koli': 'koli',
    'çift': 'çift',
    'dilim': 'dilim',
    'rulo': 'rulo',
    'top': 'top',
    'adet': 'adet',
    'tane': 'adet',
  };

  /// Cümle başı/sonundaki komut ve dolgu sözcükleri.
  static const _fillers = <String>{
    'ekle',
    'ekler',
    'eklesene',
    'eklermisin',
    'ekleyin',
    'listeye',
    'listeme',
    'listemize',
    'markete',
    'market',
    'lütfen',
    'bana',
    'bize',
    'lazım',
    'alınacak',
    'alacağız',
    'al',
    'de',
    'da',
    'şey',
  };

  /// Kalem ayırıcılar (normalize edilmiş metin üzerinde).
  static final _splitter = RegExp(
      r'\s*(?:,|;|\bvirgül\b|\bve\b|\bveya\b|\bbir de\b|\bbirde\b|\bayrıca\b|\bsonra\b|\bbide\b|\bile\b)\s*');

  static List<VoiceEntry> parse(String utterance) {
    var text = lowerTr(utterance).trim();
    if (text.isEmpty) return const [];
    // "1,5" gibi ondalıkları önce noktaya çevir, sonra noktayı cümle
    // sonu sanıp bölmekten koru (geçici işaretleme).
    text = text.replaceAllMapped(
        RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
    text = text.replaceAllMapped(
        RegExp(r'(\d)\.(\d)'), (m) => '${m[1]}#N#${m[2]}');
    text = text.replaceAll(RegExp(r'[.!?]+'), ' ');
    text = text.replaceAll('#N#', '.');
    final out = <VoiceEntry>[];
    for (final seg in text.split(_splitter)) {
      final e = _parseSegment(seg.trim());
      if (e != null && !out.contains(e)) out.add(e);
    }
    return out;
  }

  static VoiceEntry? _parseSegment(String seg) {
    if (seg.isEmpty) return null;
    final tokens = seg.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    double? qty;
    String? unit;
    final nameTokens = <String>[];

    var i = 0;
    while (i < tokens.length) {
      final t = tokens[i];
      // Sayı (rakam, ondalık, "yarım", "buçuk", sözcük)
      final n = _numberAt(tokens, i);
      if (n != null && qty == null) {
        qty = n.$1;
        i = n.$2;
        // "iki buçuk" → 2.5
        if (i < tokens.length && tokens[i] == 'buçuk') {
          qty = qty + 0.5;
          i++;
        }
        continue;
      }
      // Birim: sayıdan sonra ("iki kilo") ya da başta ("paket makarna" = 1 paket)
      if (_units.containsKey(t) && unit == null && (qty != null || i == 0)) {
        unit = _units[t];
        qty ??= 1;
        i++;
        continue;
      }
      if (_fillers.contains(t)) {
        i++;
        continue;
      }
      nameTokens.add(t);
      i++;
    }
    if (nameTokens.isEmpty) return null;
    var name = nameTokens.join(' ');
    name = _capitalize(name);

    if (qty == null) {
      return VoiceEntry(name: name, quantity: null, unit: unit);
    }
    // Ondalıkları alt birime çevir: 1.5 kg → 1500 g, 0.5 L → 500 ml
    int q;
    var u = unit;
    if (qty != qty.roundToDouble()) {
      if (u == 'kg') {
        q = (qty * 1000).round();
        u = 'g';
      } else if (u == 'L') {
        q = (qty * 1000).round();
        u = 'ml';
      } else {
        q = qty.ceil();
      }
    } else {
      q = qty.round();
    }
    if (q < 1) q = 1;
    return VoiceEntry(name: name, quantity: q, unit: u ?? 'adet');
  }

  /// tokens[i] konumundan başlayan sayıyı okur; (değer, sonrakiIndex) döner.
  static (double, int)? _numberAt(List<String> tokens, int i) {
    final t = tokens[i];
    if (t == 'yarım') return (0.5, i + 1);
    if (t == 'çeyrek') return (0.25, i + 1);
    final d = double.tryParse(t);
    if (d != null) return (d, i + 1);
    if (!_numberWords.containsKey(t)) return null;
    // "on iki", "yirmi beş", "iki yüz elli"
    var value = 0;
    var current = 0;
    var j = i;
    while (j < tokens.length && _numberWords.containsKey(tokens[j])) {
      final n = _numberWords[tokens[j]]!;
      if (n == 100 || n == 1000) {
        current = (current == 0 ? 1 : current) * n;
        value += current;
        current = 0;
      } else {
        current += n;
      }
      j++;
    }
    value += current;
    // "bir" tek başına ve ardından isim gelmiyorsa yine sayıdır
    return (value.toDouble(), j);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : upperTr(s.substring(0, 1)) + s.substring(1);
}

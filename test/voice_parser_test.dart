import 'package:flutter_test/flutter_test.dart';
import 'package:liste_asistani/core/voice_parser.dart';

void main() {
  group('VoiceParser', () {
    test('virgül ve "ve" ile ayırır', () {
      final r = VoiceParser.parse('zeytin, ekmek ve süt ekle');
      expect(r.map((e) => e.name), ['Zeytin', 'Ekmek', 'Süt']);
      expect(r.every((e) => e.quantity == null), isTrue);
    });

    test('sayı sözcüklerini adete çevirir', () {
      final r = VoiceParser.parse('iki ekmek, dört yumurta');
      expect(r[0], const VoiceEntry(name: 'Ekmek', quantity: 2, unit: 'adet'));
      expect(r[1].quantity, 4);
    });

    test('birimleri tanır ve dönüştürür', () {
      final r = VoiceParser.parse('bir kilo domates ve yarım litre süt');
      expect(r[0],
          const VoiceEntry(name: 'Domates', quantity: 1, unit: 'kg'));
      // 0.5 L → 500 ml
      expect(r[1],
          const VoiceEntry(name: 'Süt', quantity: 500, unit: 'ml'));
    });

    test('rakam ve baştaki birim', () {
      expect(VoiceParser.parse('1.5 kg peynir').single,
          const VoiceEntry(name: 'Peynir', quantity: 1500, unit: 'g'));
      expect(VoiceParser.parse('paket makarna').single,
          const VoiceEntry(name: 'Makarna', quantity: 1, unit: 'paket'));
    });

    test('komut/kalıp sözcüklerini atar', () {
      final r =
          VoiceParser.parse('listeme iki tane simit ekle lütfen');
      expect(r.single.name, 'Simit');
      expect(r.single.quantity, 2);
    });

    test('çoklu sayı: on iki', () {
      expect(VoiceParser.parse('on iki madde su').single.quantity, 12);
    });

    test('boş ve anlamsız girdi', () {
      expect(VoiceParser.parse(''), isEmpty);
      expect(VoiceParser.parse('ve veya de'), isEmpty);
    });
  });
}

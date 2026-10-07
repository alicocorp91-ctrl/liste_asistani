import 'package:flutter_test/flutter_test.dart';
import 'package:liste_asistani/core/voice_check.dart';

void main() {
  group('VoiceCheck', () {
    const adaylar = ['Süt', 'Ekmek', 'Domates', 'Kaşar Peyniri'];

    test('niyet sözcüğü olmadan eşleşme yok', () {
      expect(VoiceCheck.isIntent('süt ekle'), isFalse);
      expect(VoiceCheck.match('süt ekle', adaylar), isEmpty);
      expect(VoiceCheck.match('markete gittim', adaylar), isEmpty);
      expect(VoiceCheck.match('', adaylar), isEmpty);
    });

    test('aldım / tamam niyeti', () {
      expect(VoiceCheck.isIntent('süt aldım'), isTrue);
      expect(VoiceCheck.isIntent('ekmek tamam'), isTrue);
      expect(VoiceCheck.isIntent('domates bitti'), isTrue);
      expect(VoiceCheck.isIntent('Süt Aldım'), isTrue);
    });

    test('basit eşleşme + aday sırası', () {
      expect(VoiceCheck.match('ekmek ve süt aldım', adaylar),
          ['Süt', 'Ekmek']);
      expect(VoiceCheck.match('süt aldım', adaylar), ['Süt']);
    });

    test('sonekli söylem: "domatesi aldım"', () {
      expect(VoiceCheck.match('domatesi aldım', adaylar), ['Domates']);
      expect(VoiceCheck.match('sütü aldım', adaylar), ['Süt']);
    });

    test('çok kelimeli aday + sonek', () {
      expect(VoiceCheck.match('kaşar peyniri aldım', adaylar),
          ['Kaşar Peyniri']);
      expect(VoiceCheck.match('kaşar peynirini aldım', adaylar),
          ['Kaşar Peyniri']);
    });

    test('uzun aday kısa olandan önce gelir', () {
      const c = ['Kaşar', 'Kaşar Peyniri'];
      expect(VoiceCheck.match('kaşar peyniri aldım', c),
          ['Kaşar Peyniri']);
      expect(VoiceCheck.match('kaşar aldım', c), ['Kaşar']);
    });

    test('önek tuzağı: "markete" → "Et" seçmez', () {
      expect(VoiceCheck.match('market aldım', ['Et', 'Market']),
          ['Market']);
      expect(VoiceCheck.match('et aldım', ['Et', 'Market']), ['Et']);
    });

    test('hepsini aldım', () {
      expect(VoiceCheck.wantsAll('hepsini aldım'), isTrue);
      expect(VoiceCheck.wantsAll('hepsi tamam'), isTrue);
      expect(VoiceCheck.wantsAll('tümü bitti'), isTrue);
      expect(VoiceCheck.wantsAll('süt aldım'), isFalse);
    });

    test('yalnızca niyet: isim yoksa boş döner (sıradaki kullanılır)',
        () {
      expect(VoiceCheck.match('aldım', adaylar), isEmpty);
      expect(VoiceCheck.isIntent('aldım'), isTrue);
    });
  });
}

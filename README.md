# Liste Asistanı

Seyahat, market, piknik, mangal, kamp, plaj, taşınma… ve kendi tanımladığınız her türlü liste için
**şablon tabanlı, akıllı kontrol listesi uygulaması** (Flutter / Android + Windows).

Bu proje, eski **Seyahat Asistanı** uygulamasının sıfırdan yeniden tasarlanmış halidir:
seyahat artık yalnızca liste tiplerinden biridir; aynı motor tüm liste tiplerini çalıştırır.

---

## Tasarım (v2.3)

- **Manrope** yazı tipi (assets/fonts, çevrimdışı), Material 3 renk şeması; açık + koyu tema özenli.
- Her liste tipi için **illüstrasyon** (`assets/art/*.jpg`, şablon seçici kartları, ana sayfa küçük resimleri, detay başlığı filigranı); özel tiplerde gradyanlı ikon.
- Ana sayfa: selamlama + özet sayılar (aktif liste / eksik / yaklaşan), favoriler bölümü, renk tonlu kartlar, animasyonlu ilerleme.
- Detay: şablon renginde gradyan başlık (halka ilerleme, rozetler, sekmeler), kategori kartları, sıçrayan onay animasyonu, **tamamlanınca konfeti**.
- Oluşturma / öneri ekranları: başlık kartı, seçenek hapları, gradyan butonlar, kart gruplu kalemler.
- Tasarım önizlemesi (PNG): `flutter test tools/shots/shots_test.dart --update-goldens` → `tools/shots/out/`.

## Özellikler

- **Sesle ekleme:** hızlı ekleme çubuğundaki mikrofon düğmesiyle "zeytin, iki ekmek, bir kilo domates" deyin; adet ve birimler algılanır.
- **İş & Gündelik görev listeleri:** "İş" ve "Gündelik" şablonlarıyla gündelik ve iş hayatı ayrı tutulur; her göreve **tarih + saat** (saatli görev) eklenebilir.
- **Yaklaşanlar kartı:** ana ekranda gecikmiş + önümüzdeki 7 günün saatli işleri zaman sırasıyla; İş (indigo) ve Gündelik (mor) renk/etiketle ayrılır, dokununca listeye gider.
- **Saatli görev bildirimi:** görevin saati gelince tam zamanlı (exact) bildirim; tamamlayınca otomatik iptal.
- **Telefon takvimine ekle:** tarihli görevden tek dokunuşla takvim etkinliği (izin gerektirmez).

### Liste tipleri
| Tip | Bölümler | Filtreler | Tarih | Kalem |
|---|---|---|---|---|
| ✈️ Seyahat | Valiz · Ev Kontrolleri · Hazırlıklar | kişi tipi, mevsim, ulaşım, seyahat tipi, amaç | aralık (gidiş–dönüş) | 358 |
| 🛒 Market | Alışveriş | – (soru yok) | – (tarih yok) | 279 |
| 🧺 Piknik | Piknik | grup, mangal, çocuk, konum | tek gün | 106 |
| 🔥 Mangal | Mangal | – | – | 38 (sabit liste) |
| ⛺ Kamp | Ekipman · Yiyecek ve Mutfak · Hazırlık | kamp tipi, mevsim, ulaşım, çocuk, su kaynağı | aralık | 158 |
| 🏖️ Plaj | Plaj | kimler, çocuk, süre, aktivite, yemek | tek gün | 70 |
| 📦 Taşınma | Görevler · Malzemeler · Adres ve Abonelikler | mesafe, konut, çocuk, nakliye | tek gün | 150 |
| 📋 İş | İş | – | saatli görev | 9 |
| 🏠 Gündelik | Gündelik | – | saatli görev | 9 |
| ➕ Özel | kullanıcı tanımlı | – | isteğe bağlı | kullanıcı tanımlı |

**Market, Piknik, Mangal ve Kamp** stok listesidir (aşağıya bakın); özel tiplerde stok takibi açılabilir.
Bebek / evcil hayvan soruları ve kalemleri bilinçli olarak yoktur (kişisel kullanım). Çocuk sorusu ve çocuk kalemleri de seyahatten kaldırıldı.

Toplam **1.177 hazır kalem**, her biri ikon/kategori/bölüm bilgisiyle.

### Akıllı liste oluşturma
- **Filtreli öneri**: seçtiğiniz cevaplara göre (ör. "uçak + iş + kış + 5 gün") sadece ilgili kalemler önerilir.
- **Miktar hesabı**: süreye bağlı kalemler (iç çamaşırı, çorap, ilaç, mama…) `base + perDay × gün` formülüyle, üst sınır dikkate alınarak hesaplanır.
- **Zorunlu kalemler** ön seçili gelir; istediğinizi kaldırıp ekleyebilirsiniz. Öneri ekranında **adetleri − / + ile** değiştirebilirsiniz (2 pijama → 1).
- **Market pratiktir**: soru ve tarih sorulmaz, öneriler görünür ama **hiçbiri seçili gelmez**; arayıp birkaçını işaretlersiniz (boş da oluşturabilirsiniz). Liste ekranının altında **hızlı ekleme çubuğu** vardır: "süt" yazınca katalogdan öneri çıkar, Enter ile eklenir; katalogda yoksa "Diğer" kategorisine serbest kalem olarak girer. Aynı adı tekrar yazmak kopya oluşturmaz.
- Katalogda olmayan kalemleri anında yazıp ekleyebilirsiniz.

### Stok takibi (malzeme listeleri)
Piknik, mangal, kamp ve market listeleri tek seferlik değil, **sürekli kullanılan stok listesidir**:
- Her kalemde **gereken** ve **stokta** miktarı tutulur; stok gerekenin altındaysa kalem **eksik** olarak kırmızı vurgulanır ve kategori içinde üste alınır.
- Satırdaki − / + stoğu değiştirir. **"4/5" etiketine dokununca** açılan sayfada **olması gereken (hedef)** ve **şu an stokta** birlikte ayarlanır; eksik anında hesaplanır ("Eksik: 1 → markete bu kadar aktarılır"). Sayıya dokunup elle de girebilirsiniz. Menüden hepsini stokta işaretleme / sıfırlama.
- **Eksikleri markete aktar**: eksik kalemler mevcut bir market listesine ya da yeni açılan "Alışveriş – …" listesine, sadece eksik miktar kadar aktarılır. Aynı adlı kalem hedefte varsa **kopya oluşmaz**, miktarı güncellenir. Kategori eşleşmezse "Aktarılan eksikler" kategorisine düşer.
- "Sadece eksikler" filtresi, eksikleri paylaşma, ana ekranda "N eksik" rozeti.
- Fiyat alanı bilinçli olarak yoktur.

### Liste yönetimi
- Bölüm sekmeleri (ör. Valiz / Ev Kontrolleri / Hazırlıklar), kategori grupları, ilerleme çubuğu.
- İşaretle, miktar değiştir, not ekle, yeniden adlandır, sil.
- Arama ve "sadece kalanlar" görünümü.
- Geri sayım (etkinlik tarihine kalan gün), tarih aralığı düzenleme.
- **Hatırlatıcılar**: kaleme veya listeye tam zamanlı bildirim (`daysBefore` ile önerilen tarih).
- **Favori** listeler ana ekranda en üstte (★).
- Kopyala, arşivle, paylaş (WhatsApp vb. için düz metin), tamamlananları sıfırla.

### Katalog yönetimi
- Her şablon için kalemleri **etkinleştir/devre dışı bırak**.
- Şablona **kendi kalemlerinizi** ekleyin (kategori, ikon, miktar kuralı ile).
- **Özel liste tipi** oluşturun: ad, ikon, renk, tarih modu, kategoriler ve kalemler.

### Ayarlar
- 6 renk teması + açık/koyu/sistem modu.
- Yedek al / geri yükle (JSON), bildirim izinleri, verileri sıfırla.

---

## Proje yapısı

```
liste_asistani/
├── lib/
│   ├── main.dart                     # Uygulama girişi, tema, provider kurulumu
│   ├── core/
│   │   ├── app_icons.dart            # String → IconData eşlemesi (şablon JSON'ları için)
│   │   └── utils.dart                # Tarih formatı, Türkçe büyük/küçük harf, geri sayım
│   ├── models/
│   │   ├── template.dart             # ListTemplate, CatalogItem, Filter, Section, Category
│   │   └── user_list.dart            # UserList, UserListItem (kullanıcının oluşturduğu listeler)
│   ├── data/
│   │   ├── storage.dart              # SharedPreferences sarmalayıcı + yedekleme
│   │   └── template_repository.dart  # assets/data/templates/*.json yükleyici
│   ├── providers/
│   │   ├── settings_provider.dart    # Tema / ayarlar
│   │   ├── catalog_provider.dart     # Şablonlar, özel kalemler, devre dışı kalemler, özel tipler
│   │   └── lists_provider.dart       # Liste CRUD, öneri motoru, miktar hesabı, paylaşım metni
│   ├── services/
│   │   └── notification_service.dart # flutter_local_notifications + timezone
│   ├── widgets/common.dart           # Ortak widget'lar (chip, boş durum, geri sayım…)
│   └── screens/                      # home, template_picker, create_list, selection,
│                                     # list_detail, settings, manage_catalog, template_editor
├── assets/
│   ├── icon.png                      # Uygulama ikonu kaynağı
│   └── data/templates/               # 9 yerleşik şablon (JSON) + index.json
├── tools/catalog/                    # Şablon JSON'larını üreten Python kaynakları
├── test/                             # Birim + widget testleri (22 test)
├── android/                          # Android projesi (minSdk 23, imzalama desteği)
└── .github/workflows/build-apk.yml   # GitHub Actions: analiz + test + release APK
```

---

## Yerelde çalıştırma

> Windows'ta sıfırdan kurulum için adım adım rehber: **[KURULUM_WINDOWS.md](KURULUM_WINDOWS.md)**

Gereksinimler: **Flutter 3.35+** (stable). Android için Android SDK + Java 17;
Windows masaüstü için Visual Studio 2022 "Desktop development with C++"; Linux için
`clang cmake ninja-build pkg-config libgtk-3-dev`.

```bash
git clone <repo-url> liste_asistani
cd liste_asistani
flutter pub get
flutter run -d windows      # PC'de pencere olarak (Linux: -d linux)
flutter run                 # bağlı Android cihaz / emülatör
```

Kontroller:

```bash
flutter analyze             # "No issues found!" beklenir
flutter test                # 22 test geçmeli
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
flutter build windows --release  # build/windows/x64/runner/Release/
```

Uygulama ikonunu değiştirdiyseniz:

```bash
dart run flutter_launcher_icons
```

---

## GitHub Actions ile APK ve Windows .exe

İki workflow vardır:
- `build-apk.yml` → Android APK (artifact: `liste-asistani-release-apk`)
- `build-windows.yml` → Windows uygulaması klasörü (artifact: `liste-asistani-windows`)

`.github/workflows/build-apk.yml` her `main`/`master` push'unda ve elle tetiklemede
(Actions → *Android APK oluştur* → *Run workflow*) çalışır:

1. Flutter stable + Java 17 kurulur
2. `flutter analyze` ve `flutter test`
3. `flutter build apk --release`
4. APK, **Artifacts** bölümünde `liste-asistani-release-apk` adıyla 30 gün saklanır

### İsteğe bağlı release imzalama
Secret tanımlanmazsa APK **debug anahtarıyla** imzalanır (telefona kurulabilir; ama üzerine
güncelleme yüklemek için hep aynı anahtar gerekir). Kalıcı imza için repo *Settings → Secrets*:

| Secret | İçerik |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 release.keystore` çıktısı |
| `KEYSTORE_PASSWORD` | keystore şifresi |
| `KEY_ALIAS` | anahtar takma adı |
| `KEY_PASSWORD` | anahtar şifresi |

Keystore oluşturma:
```bash
keytool -genkey -v -keystore release.keystore -alias liste -keyalg RSA -keysize 2048 -validity 10000
```
Yerelde aynı şey için `android/key.properties` dosyası oluşturun (git'e girmez):
```
storeFile=release.keystore      # android/app/ altına koyun
storePassword=...
keyAlias=liste
keyPassword=...
```

---

## Şablon (katalog) düzenleme

Yerleşik şablonlar `assets/data/templates/*.json` dosyalarındadır ve
`tools/catalog/*.py` kaynaklarından üretilir:

```bash
python3 tools/catalog/gen.py     # JSON'ları yeniden üretir + doğrular
flutter test test/catalog_test.dart
```

Şema özeti (`tools/catalog/common.py` içinde ayrıntılı):

```jsonc
{
  "id": "market", "name": "Market", "icon": "shopping_cart", "color": "#43A047",
  "kind": "inventory",               // checklist (varsayılan) | inventory (stok takibi)
  "preselect": false,                // false: öneri ekranında hiçbir kalem ön seçili gelmez
  "quickAdd": true,                  // true: liste ekranında hızlı ekleme çubuğu
  "dateMode": "single",              // none | single | range
  "filters":  [{ "id": "diet", "label": "Diyet", "options": [{ "id": "vegan", "label": "Vegan" }] }],
  "sections": [{ "id": "main", "name": "Liste" }],
  "categories": [{ "id": "dairy", "name": "Süt Ürünleri", "icon": "egg", "section": "main" }],
  "items": [{
    "id": "milk", "name": "Süt", "category": "dairy",
    "when": { "diet": ["none", "vegetarian"] },   // filtre eşleşmesi (boş = her zaman)
    "qty": { "base": 1, "perDay": 0.3, "max": 6 }, "unit": "L",
    "essential": true, "daysBefore": null
  }]
}
```

- `when`: sözlük → filtreler arası **VE**, seçenekler arası **VEYA**; liste → blokların **VEYA**'sı.
- `qty`: `base + ceil(perDay × gün)`, `max` ile sınırlanır; `null` ise miktar gösterilmez.
- `daysBefore`: etkinlikten kaç gün önce yapılmalı → önerilen hatırlatma tarihi (negatif = sonrası).
- `icon`: `lib/core/app_icons.dart` içindeki isimlerden biri olmalı (test bunu doğrular).

---

## Teknik notlar
- Durum yönetimi: `provider`; kalıcılık: `shared_preferences` (JSON).
- Bildirimler: `flutter_local_notifications` 19 + `timezone`; Android 13+ izin akışı ve
  tam zamanlı alarm izni ayarlardan yönetilir.
- Ana hedef Android (`minSdk 23`); Windows ve Linux masaüstü geliştirme/test için desteklenir.
  Masaüstünde bildirimler uygulama açıkken çalışır; Android'e özel izin ekranları gizlenir.
- Widget testleri için `TemplateRepository` asset'leri `rootBundle.load` + `utf8.decode`
  ile okur (`loadString` 50 KB üstü dosyalarda isolate kullanır ve test ortamında takılır).

## Lisans
Kişisel kullanım için geliştirilmiştir.

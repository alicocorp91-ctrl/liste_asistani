# Windows'ta Flutter Kurulumu ve Liste Asistanı'nı Çalıştırma

Bu rehber sıfırdan başlar: Flutter'ı Windows 10/11'e kurar, uygulamayı **PC'de pencere olarak**
çalıştırır, sonra aynı PC'de **Android APK** derlemeyi ekler. Toplam süre ~1 saat (indirmeler dahil),
disk ~15 GB (Android Studio ile).

> Sıra önemli: önce **Adım 1-5** ile masaüstünde çalıştırın (30 dk). Android (Adım 6) sonra eklenir;
> APK için GitHub Actions zaten var, acelesi yok.

---

## Adım 1 — Git for Windows

1. https://git-scm.com/download/win → indir → kur (tüm seçenekler varsayılan kalabilir).
2. Kontrol: **Başlat → PowerShell** aç:
   ```powershell
   git --version
   ```

## Adım 2 — Visual Studio 2022 (Windows masaüstü için zorunlu)

Flutter Windows uygulamalarını C++ derleyicisiyle üretir; bunun için **Visual Studio** gerekir
(VS Code değil, farklı program!). Ücretsiz Community sürümü yeterli.

1. https://visualstudio.microsoft.com/tr/downloads/ → **Community 2022** → indir, çalıştır.
2. Installer'da **"Desktop development with C++"** (C++ ile masaüstü geliştirme) iş yükünü işaretle.
3. Sağdaki "Installation details" içinde şunlar seçili olsun (varsayılan gelir):
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - Windows 10 SDK veya Windows 11 SDK
   - C++ CMake tools for Windows
4. **Install** → ~7 GB, 15-30 dk. Bitince VS'yi açmanıza gerek yok.

## Adım 3 — Flutter SDK

1. https://docs.flutter.dev/get-started/install/windows/desktop → **"Download and install"** → `flutter_windows_x.x.x-stable.zip` indir.
2. Zip'i **`C:\dev\flutter`** klasörüne çıkar (yol boşluk/Türkçe karakter içermesin; `C:\Program Files` kullanmayın).
3. PATH'e ekle:
   - Başlat'a **"ortam değişkenleri"** yaz → *Hesabınız için ortam değişkenlerini düzenleyin*
   - Üst kutuda **Path** → Düzenle → Yeni → `C:\dev\flutter\bin` → Tamam, Tamam.
4. **Yeni** bir PowerShell aç (eskisi PATH'i görmez):
   ```powershell
   flutter --version
   flutter config --enable-windows-desktop
   flutter doctor
   ```
   `flutter doctor` çıktısında şunlar ✓ olmalı: **Flutter**, **Windows Version**, **Visual Studio**.
   Android satırındaki ✗ şimdilik normal (Adım 6'da çözülecek).

> İlk `flutter` komutu Dart SDK'yı indirir; 1-2 dk sürebilir.

## Adım 4 — Projeyi indir

**A) GitHub'a yüklediyseniz:**
```powershell
cd C:\dev
git clone https://github.com/KULLANICI/liste_asistani.git
cd liste_asistani
```

**B) Dosyaları elle kopyaladıysanız:** `liste_asistani` klasörünü `C:\dev\liste_asistani` olarak koyun, sonra:
```powershell
cd C:\dev\liste_asistani
```

## Adım 5 — Masaüstünde çalıştır 🎉

```powershell
flutter pub get
flutter run -d windows
```

- İlk derleme 2-5 dk sürer (C++ derleniyor); sonrakiler saniyeler.
- Uygulama **480×860** boyutunda telefon oranında bir pencerede açılır; pencereyi büyütürseniz
  içerik ortada 720 px genişlikte kalır.
- Kod değiştirip terminalde **`r`** basınca anında yenilenir (hot reload), **`R`** tam yeniden başlatır, **`q`** kapatır.

Bağımsız `.exe` üretmek için:
```powershell
flutter build windows --release
```
Çıktı: `build\windows\x64\runner\Release\` — bu klasörün **tamamı** uygulamadır (exe + dll'ler + data).
Zip'leyip başka bir PC'ye kopyalayabilirsiniz (Visual Studio gerekmez, sadece
[VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) kurulu olmalı).

### Windows'ta çalışan / çalışmayan özellikler
| Özellik | Windows | Not |
|---|---|---|
| Listeler, şablonlar, filtreler, miktar | ✓ | Aynı |
| Tema, yedek al/geri yükle | ✓ | |
| Paylaş | ✓ | Windows paylaşım paneli açılır |
| Hatırlatıcı bildirimleri | ✓ | Windows bildirim merkezi; **uygulama kapalıyken** gelmez (Android'de gelir) |
| Tam zamanlı alarm izni ekranı | – | Android'e özel, Windows'ta görünmez |

---

## Adım 6 — Aynı PC'de Android APK derlemek

### 6.1 Android Studio
1. https://developer.android.com/studio → indir → kur (varsayılanlar).
2. İlk açılışta **Standard** kurulum → SDK, platform-tools ve emülatör indirilir (~5 GB).
3. **More Actions → SDK Manager → SDK Tools** sekmesi → şunları işaretle → Apply:
   - **Android SDK Command-line Tools (latest)**  ← Flutter için şart
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - (isteğe bağlı) Android Emulator

### 6.2 Lisansları kabul et
```powershell
flutter doctor --android-licenses
```
Her soruya `y`.

### 6.3 Kontrol
```powershell
flutter doctor
```
Artık **Android toolchain** ✓ olmalı. Hâlâ ✗ ise en sık sebep: cmdline-tools kurulmamış (6.1/3).

### 6.4 Telefonda çalıştır
1. Telefonda **Ayarlar → Telefon hakkında → Yapı numarası**'na 7 kez dokun → Geliştirici seçenekleri açılır.
2. **Geliştirici seçenekleri → USB hata ayıklama** aç.
3. USB ile bağla, telefonda "Bu bilgisayara güven" → İzin ver.
4. ```powershell
   flutter devices          # telefon listede görünmeli
   flutter run              # veya: flutter run -d <cihaz-id>
   ```

### 6.5 APK üret
```powershell
flutter build apk --release
```
Çıktı: `build\app\outputs\flutter-apk\app-release.apk` → telefona kopyala, kur.

> Java: Android Studio kendi JDK'sını (17) getirir; ayrıca Java kurmanız gerekmez.
> Eğer `flutter doctor` "Unable to find bundled Java" derse:
> `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"`

---

## Adım 7 — Kod editörü (öneri: VS Code)

1. https://code.visualstudio.com → kur.
2. Extensions (Ctrl+Shift+X) → **Flutter** kur (Dart otomatik gelir).
3. `File → Open Folder → C:\dev\liste_asistani`.
4. Sağ alttan cihaz seç (**Windows (desktop)** veya telefon) → **F5** ile çalıştır.
   Kaydettiğinizde hot reload otomatik olur.

---

## Günlük iş akışı

```
Kod yaz (VS Code)  →  F5 / flutter run -d windows  →  PC'de test et
        ↓
git add . && git commit -m "..." && git push
        ↓
GitHub Actions:  APK (Actions → Android APK oluştur → Artifacts)
                 EXE (Actions → Windows uygulaması oluştur → Artifacts)
```

Şablonlara kalem eklemek için (Python gerekir, https://www.python.org):
```powershell
python tools\catalog\gen.py
flutter test test\catalog_test.dart
```

---

## Sık karşılaşılan hatalar

| Hata | Çözüm |
|---|---|
| `flutter` tanınmıyor | PATH'e `C:\dev\flutter\bin` eklendi mi? **Yeni** terminal açın. |
| `Visual Studio not installed` / `missing C++ workload` | Visual Studio Installer → Modify → "Desktop development with C++" işaretle. |
| `Unable to find suitable Visual Studio toolchain` | Adım 2'de Windows 10/11 SDK seçili değil. Installer'dan ekleyin. |
| `cmdline-tools component is missing` | Android Studio → SDK Manager → SDK Tools → Command-line Tools (latest). |
| `Android license status unknown` | `flutter doctor --android-licenses` → hepsine `y`. |
| Windows Defender derlemeyi çok yavaşlatıyor | Defender → Dışlamalar'a `C:\dev` klasörünü ekleyin. |
| Yol Türkçe karakter içeriyor (`C:\Users\Ömer\...`) | Projeyi `C:\dev\` altına taşıyın. |
| `Building with plugins requires symlink support` | Ayarlar → Geliştiriciler için → **Geliştirici Modu**'nu aç. |
| Telefon `flutter devices`'ta yok | USB hata ayıklama açık mı? Kabloyu değiştir (bazı kablolar sadece şarj). `adb devices` dene. |

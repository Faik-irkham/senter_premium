# Senter Premium

**Aplikasi lelucon.** Menyalakan senter gratis, mematikannya harus "berlangganan".

Proyek ini dibuat **semata-mata untuk belajar UI dan animasi di Flutter**, misalnya render 3D tanpa plugin, animasi, state management, dan arsitektur per fitur, serta sebagai bahan konten hiburan. Ini bukan produk, dan tidak dimaksudkan untuk dipublikasikan atau dipakai menarik uang dari siapa pun.

| Mati | Menyala |
|---|---|
| ![Senter mati](docs/senter-mati.png) | ![Senter menyala](docs/senter-nyala.png) |

## Disclaimer

- Ini **aplikasi lelucon**. Seluruh "langganan", harga, promo, hitung mundur, dan jumlah pengguna di dalamnya **fiktif**. Secara default tidak ada transaksi sungguhan.
- Pembuat **tidak bertanggung jawab** atas pengembangan lanjutan, modifikasi, atau penggunaan proyek ini oleh pihak lain. Itu termasuk memakainya untuk menipu, menjebak pembayaran, atau tindakan melanggar hukum lainnya.
- Proyek ini **tidak mengandung dan tidak mendukung indikasi kejahatan apa pun**. Pola "jebakan" di dalamnya hanyalah satire tentang aplikasi berlangganan, dan dibuat untuk tujuan belajar serta hiburan.
- Dengan memakai atau memodifikasi kode ini, Anda menanggung sendiri seluruh risiko dan tanggung jawabnya.

## Fitur

- **Senter 3D interaktif.** Ketuk untuk menyalakan atau mematikan, geser untuk memutar. Saat dinyalakan, lampunya berkedip seperti bohlam, lalu muncul sorot cahaya, silau di lensa, dan bayangan.
- **Jebakan yang terungkap bertahap.** Sebelum percobaan pertama, tidak ada kata "gratis", badge, maupun gembok. Setiap percobaan mematikan membuat senter bergetar, HP bergetar, dan kalimat reaksinya makin dramatis.
- **Paywall yang terlalu serakah.** Paket "Pemula Gelap", "Penikmat Gelap", dan "Sultan Kegelapan", lengkap dengan harga coret, hitung mundur promo yang selalu mulai lagi dari 04:59, dan social proof.
- **Punchline.** Setelah "berlangganan", muncul layar *"Anda kini resmi termasuk 0,01% manusia yang mampu mematikan senter"*, lalu senter langsung mati.
- **Bisa take ulang.** Tekan lama badge **Premium** di app bar untuk mengembalikan akun ke Gratis.
- **Jalan di simulator.** Kalau perangkat tidak punya flash (misalnya simulator iOS), aplikasi otomatis memakai senter virtual.

## Menjalankan

Butuh Flutter 3.47 atau lebih baru (Dart 3.13).

```bash
flutter pub get
flutter run            # debug
flutter run --release  # untuk merekam di HP asli (lebih mulus)
```

Kalau Anda menambah atau mengganti asset (misalnya model 3D), hentikan aplikasi lalu jalankan `flutter run` lagi. Hot restart tidak cukup.

### Opsi build

Opsi ini diatur dengan `--dart-define` dan dibaca di [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart).

| Opsi | Default | Fungsi |
|---|---|---|
| `FAKE_BILLING` | `true` | Billing palsu. Biarkan `true`, karena proyek ini tidak untuk transaksi sungguhan |
| `VIRTUAL_TORCH_FALLBACK` | `true` | `false` = tampilkan layar "tidak ada senter" di perangkat tanpa flash |

Contoh:

```bash
flutter run --dart-define=VIRTUAL_TORCH_FALLBACK=false
```

## Struktur proyek

Proyek ini disusun per fitur. Setiap fitur dibagi menjadi `domain` (aturan dan kontrak), `data` (implementasi), `application` (state dengan Riverpod), dan `presentation` (UI).

```
lib/
├── main.dart
├── app/                      MaterialApp
├── core/
│   ├── config/               AppConfig (flag build, ID produk)
│   ├── l10n/                 AppStrings — semua teks UI
│   ├── theme/                warna & tema
│   ├── animation/            kurva kedip bohlam
│   ├── widgets/              ShakeOnChange
│   └── three_d/              engine 3D (Vec3, Mesh, MeshBuilder, OBJ, Renderer3D, shading)
└── features/
    ├── flashlight/
    │   ├── domain/           FlashlightRepository
    │   ├── data/             TorchLight (hardware), Fake (virtual), Fallback
    │   ├── application/      FlashlightController, flashlightModelProvider
    │   └── presentation/     FlashlightPage, Flashlight3DView, PowerButton, AmbientGlow
    └── subscription/
        ├── domain/           Entitlement, SubscriptionPlan, PremiumFeature + FeatureGate
        ├── data/             StoreSubscriptionRepository, FakeSubscriptionRepository, PurchaseVerifier
        ├── application/      entitlementProvider, featureGateProvider, PaywallController
        └── presentation/     PaywallSheet, CelebrationDialog, PremiumBadge

tool/generate_flashlight_model.dart   pembuat model 3D
assets/models/flashlight.obj          model 3D senter
```

### Aturan inti

Aturannya ada di `FlashlightController.toggle()`:

- Menyalakan selalu diizinkan.
- Mematikan hanya diizinkan jika `featureGate.canUse(PremiumFeature.turnOffFlashlight)`. Kalau tidak, hasilnya `ToggleResult.premiumRequired` dan UI menampilkan paywall.

## Mengembangkan

### Menambah fitur berbayar

1. Tambahkan nilai baru di enum `PremiumFeature` ([premium_feature.dart](lib/features/subscription/domain/premium_feature.dart)).
2. Tentukan aturannya di `FeatureGate.canUse`.
3. Di tempat fitur itu dipakai, cek dengan `ref.read(featureGateProvider).canUse(PremiumFeature.fiturBaru)`.

### Mengubah teks dan harga

- Kalimat reaksi, teks paywall, dan teks perayaan ada di [app_strings.dart](lib/core/l10n/app_strings.dart). Kalimat reaksi disimpan di `deniedLines` dan tampil berurutan setiap kali pengguna gagal mematikan.
- Nama paket dan harga palsu ada di [fake_subscription_repository.dart](lib/features/subscription/data/fake_subscription_repository.dart).

### Mengganti model 3D

Model senter dibuat oleh skrip:

```bash
dart run tool/generate_flashlight_model.dart
```

Anda juga bisa memakai model dari Blender:

1. Ekspor ke **Wavefront OBJ** dengan opsi *Write Normals* aktif.
2. Beri nama material sesuai daftar berikut. Material lain akan tampil abu-abu.

   | Material | Tampilan |
   |---|---|
   | `body`, `grip`, `head` | logam hitam anodized |
   | `gold` | aksen emas |
   | `reflector` | perak, berpendar emas saat menyala |
   | `lens` | kaca, **menyala** saat senter hidup |
   | `button` | tombol karet merah |

3. Arahkan sumbu senter ke **+X** dengan lensa di ujung +X. Panjangnya kira-kira 2 unit.
4. Timpa `assets/models/flashlight.obj`. Kalau posisi atau ukuran lensanya berbeda, sesuaikan konstanta `_lensX`, `_lensRadius`, dan `_pivot` di [flashlight_scene_painter.dart](lib/features/flashlight/presentation/widgets/flashlight_scene_painter.dart).

Renderernya berjalan di CPU tanpa plugin. Kalau animasinya patah-patah di perangkat lambat, kurangi jumlah segitiga, misalnya dengan menurunkan `segments` di skrip generator.

## Test

```bash
flutter analyze
flutter test
```

Yang dicakup test:

- aturan menyalakan/mematikan untuk akun gratis dan premium
- fallback ke senter virtual
- parser dan penulis OBJ, serta isi model senter
- alur UI lengkap: nyala → paywall → perayaan → mati → reset
- eskalasi kalimat reaksi

## Catatan

- Kode billing sungguhan (`StoreSubscriptionRepository`) disertakan hanya sebagai contoh arsitektur, dan tidak aktif secara default.
- Proyek ini tidak ditujukan untuk dirilis ke Play Store atau App Store.

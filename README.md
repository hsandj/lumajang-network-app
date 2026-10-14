# Lumajang Network - Mobile App (Android APK & iOS)

Aplikasi mobile resmi untuk **ISP Billing & Operational Dashboard** [lumajangnetwork.id](https://lumajangnetwork.id). Dibangun menggunakan **Flutter** untuk menghasilkan aplikasi native berkinerja tinggi bagi Android (.apk) dan iOS (.ipa / App Store).

---

## 🚀 Fitur Utama

- **Integrasi Penuh Web Dashboard**: Terhubung langsung ke sistem billing dan operasional `lumajangnetwork.id`.
- **Manajemen Sesi & Cookie Otomatis**: Mendukung Laravel session cookie (`isp-manajemen-billing-session` & `XSRF-TOKEN`), menjaga user tetap login tanpa perlu login ulang setiap membuka aplikasi.
- **Splash Screen Interaktif**: Dilengkapi logo router ISP modern dan animasi pemuatan yang serasi dengan identitas grafis portal.
- **Deteksi Koneksi Offline**: Tampilan khusus jika perangkat kehilangan koneksi internet lengkap dengan tombol *Coba Lagi* otomatis.
- **Pull-To-Refresh**: Tarik ke bawah di layar mana saja untuk memuat ulang halaman secara mulus.
- **Penanganan Tombol Back Pintar**: Tombol kembali ponsel akan memundurkan riwayat web terlebih dahulu; jika berada di halaman awal, konfirmasi *Tekan sekali lagi untuk keluar* akan mencegah penutupan aplikasi yang tidak disengaja.
- **Integrasi URL Eksternal**:
  - Tautan WhatsApp (`wa.me` / `whatsapp://`) langsung membuka aplikasi WhatsApp CS/Pelanggan.
  - Tautan telepon (`tel:`) dan email (`mailto:`) langsung memicu dialer & aplikasi mail.
  - Integrasi gateway pembayaran eksternal.
- **Dukungan Upload File & Kamera**: Izin lengkap untuk kamera dan galeri guna mengunggah bukti bayar atau foto teknisi jaringan.
- **Cloud CI/CD Otomatis**: Disediakan alur GitHub Actions untuk meng-compile file `.apk` (Android) dan `.ipa` (iOS) langsung di cloud tanpa perlu komputer Mac.

---

## 📁 Struktur Proyek

```
lumajang_network_app/
├── lib/
│   ├── config/
│   │   └── app_config.dart          # Konfigurasi URL web, tema, & identitas
│   ├── screens/
│   │   ├── splash_screen.dart       # Layar pembuka & pengecekan internet
│   │   ├── webview_screen.dart      # Layar utama WebView interaktif
│   │   └── offline_screen.dart      # Layar indikasi terputus koneksi
│   └── main.dart                    # Entry point aplikasi
├── android/
│   ├── app/
│   │   ├── build.gradle             # Konfigurasi target SDK 34 & package name
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Izin Internet, Kamera, File Storage
│   │       └── res/                 # Resource tema dan splash screen
├── ios/
│   ├── Runner/
│   │   └── Info.plist               # Konfigurasi permission iOS & ATS
│   └── Podfile
├── .github/workflows/
│   └── build.yml                    # Otomasi compile APK & iOS di Cloud
└── pubspec.yaml                     # Dependensi Flutter
```

---

## 🛠️ Cara Build Aplikasi

### Opsi 1: Build Otomatis di Cloud (Paling Mudah, Gratis & Tanpa Mac)
Anda dapat memanfaatkan alur GitHub Actions yang telah disiapkan di `.github/workflows/build.yml`:
1. Buat repositori baru di akun GitHub Anda (misal: `lumajang-network-app`).
2. Masuk ke folder proyek ini di terminal:
   ```bash
   git init
   git add .
   git commit -m "Initial commit for Lumajang Network App"
   git branch -M main
   git remote add origin https://github.com/USERNAME_ANDA/lumajang-network-app.git
   git push -u origin main
   ```
3. Buka tab **Actions** di repositori GitHub Anda.
4. Sistem akan secara otomatis mengompilasi:
   - **`LumajangNetwork-Android-APK`** (bisa langsung diunduh dan dipasang di HP Android).
   - **`LumajangNetwork-iOS-IPA`** (arsip aplikasi untuk iOS).

---

### Opsi 2: Build Mandiri di Komputer Lokal

#### Persyaratan:
1. Pastikan **Flutter SDK** sudah terpasang ([flutter.dev](https://flutter.dev/docs/get-started/install)).
2. Untuk Android: Pasang **Android Studio** & Command Line Tools.
3. Untuk iOS: Gunakan macOS dengan **Xcode** terpasang.

#### Langkah Kompilasi Android (APK):
```bash
# 1. Unduh pustaka / dependensi
flutter pub get

# 2. Build file APK siap rilis
flutter build apk --release
```
File APK akan berada di folder:
`build/app/outputs/flutter-apk/app-release.apk`

#### Langkah Kompilasi iOS:
```bash
# Buka workspace iOS di Xcode (khusus macOS)
open ios/Runner.xcworkspace

# Atau compile melalui terminal
flutter build ipa --release
```

---

## ⚙️ Kustomisasi URL & Parameter

Jika di masa mendatang URL dashboard berubah atau ingin menambahkan sub-path tertentu, Anda cukup mengubah file:
`lib/config/app_config.dart`

```dart
static const String webUrl = 'https://lumajangnetwork.id';
```

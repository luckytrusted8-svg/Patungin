# Patungin (Split Bill dengan Scan Struk) 🧾🤝

Aplikasi mobile **Split Bill** (patungan tagihan) modern, offline-first, tanpa backend. Dibangun menggunakan **Flutter + Dart** dengan target utama **Android** (iOS menyusul).

Aplikasi membantu sekelompok orang membagi tagihan restoran/kafe dengan adil:
1. **Foto Struk / Input Manual**: OCR membaca item makanan, harga, pajak, service, diskon, dan total secara otomatis.
2. **Review & Koreksi**: Koreksi nama atau harga item bila diperlukan, dengan tanda khusus untuk item yang diragukan.
3. **Tentukan Siapa Makan Apa**: Pilih peserta per item dengan porsi fleksibel (1x, 2x, dll.).
4. **Alokasi Pajak, Service & Diskon Proporsional**: Menggunakan **Metode Largest Remainder (Hamilton-Hare)** sehingga jumlah pembagian dijamin persis hingga 1 Rupiah tanpa pembulatan mengambang (Zero `double` for currency).
5. **Utang-Piutang (Settlement)**: Menghitung siapa bayar ke siapa secara transparan.
6. **Bagikan Rincian**: Ekspor teks rapi ke WhatsApp atau bagikan gambar ringkasan (PNG).

---

## 🎨 Warna Brand & Identitas
- **Primary**: `#0D9488` (Teal 600)
- **Dark**: `#115E59` (Teal 800)
- **Accent**: `#F59E0B` (Amber 500)
- **Mint**: `#2DD4BF` (Teal 400)
- Mendukung mode **Terang (Light Mode)** dan **Gelap (Dark Mode)** otomatis sesuai tema sistem.

---

## 🏗 Arsitektur & Aturan Kode
- **Zero Double for Money**: Seluruh nominal rupiah disimpan dan dihitung dalam tipe `int`. Dilarang menggunakan `double` untuk komputasi uang demi mencegah floating-point rounding errors.
- **Pure Dart Domain**: Layer `domain/` sepenuhnya pure Dart (tanpa import Flutter ataupun Drift) agar mudah di-unit-test secara terisolasi.
- **Layering Terpisah**:
  - `domain/`: Model entitas, `allocation.dart` (largest remainder), `split_calculator.dart`, `settlement_calculator.dart`, `receipt_parser.dart`, `number_parser.dart`.
  - `data/`: Drift ORM database (`app_database.dart`), tabel dengan Foreign Key `ON DELETE CASCADE`, mapper, dan repository transaksi.
  - `presentation/`: Riverpod State Management (`bill_draft_controller.dart`), Stepper alur bertahap (5 langkah), UI layar Riwayat, Review OCR, dan Hasil.
  - `core/`: Tema warna, router `go_router`, format mata uang Rupiah (`id_ID`), dan string konstanta Bahasa Indonesia.

---

## 📁 Struktur Folder
```
lib/
  main.dart
  app.dart
  core/
    constants/strings.dart
    theme/app_theme.dart
    router/app_router.dart
    utils/
      money_formatter.dart      // format int -> "Rp 172.500"
      date_formatter.dart
      id_generator.dart
  domain/
    models/
      bill.dart
      participant.dart
      bill_item.dart
      item_share.dart
      person_result.dart
      settlement.dart           // "A bayar X ke B"
      complete_bill.dart
    calculator/
      split_calculator.dart     // inti logika hitung
      allocation.dart           // helper largest-remainder
      settlement_calculator.dart
    parser/
      receipt_parser.dart       // OCR text -> List<ParsedItem>
      parsed_receipt.dart
      number_parser.dart        // "40.000" / "Rp 40.000,-" -> 40000
  data/
    db/
      app_database.dart         // Drift database
      tables.dart               // Skema tabel Bills, Participants, Items, Shares
      app_database.g.dart
    repositories/
      bill_repository.dart      // DAO/Repository transaksi & cascade
    mappers/
      bill_mapper.dart          // Entity Drift <-> Model domain
  presentation/
    providers/
      bill_draft_controller.dart // State notifier draft 5 langkah
      database_provider.dart
    features/
      history/                  // Layar riwayat tagihan & hapus
      bill_editor/              // Stepper 5 langkah (Item, Peserta, Assign, Biaya, Hasil)
      scan/                     // Kamera/Galeri, OCR ML Kit, Review hasil
test/
  domain/
    allocation_test.dart
    split_calculator_test.dart
    settlement_calculator_test.dart
    number_parser_test.dart
    receipt_parser_test.dart
  data/
    bill_repository_test.dart
docs/
  ASSUMPTIONS.md
```

---

## 🚀 Cara Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (stable terbaru)
- Android Studio / Android SDK dengan emulator atau perangkat fisik Android (USB debugging aktif).

### 2. Mengambil Dependensi
```bash
flutter pub get
```

### 3. Generate Kode (Drift & Launcher Icons)
```bash
# Generate Drift Database code
dart run build_runner build --delete-conflicting-outputs

# Generate App Icons untuk Android & iOS
dart run flutter_launcher_icons
```

### 4. Menjalankan Unit Test
```bash
flutter test
```
*Seluruh unit test (31 skenario) mencakup contoh data utama "Makan Bertiga" Andi-Budi-Citra, properti invariant 1.000 iterasi acak, database in-memory cascade, dan OCR parser.*

### 5. Memeriksa Linter
```bash
flutter analyze
```

### 6. Menjalankan Aplikasi di Emulator / Perangkat Android
```bash
flutter run
```

---

## ⚠️ Batasan & Catatan Teknis
1. **Fitur Scan OCR ML Kit**: `google_mlkit_text_recognition` dirancang khusus untuk platform **Android** dan **iOS**. Saat dijalankan di desktop Windows atau web, fitur input manual tetap bekerja 100%, sementara scan struk menyarankan penggunaan perangkat mobile.
2. **Kamera & Penyimpanan**: Memerlukan izin `CAMERA` dan media penyimpanan pada Android. Izin telah dikonfigurasi di `android/app/src/main/AndroidManifest.xml`.

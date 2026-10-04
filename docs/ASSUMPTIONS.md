# Dokumentasi Asumsi & Keputusan Desain (Patungin)

Dokumen ini mencatat asumsi teknis dan keputusan arsitektur yang diambil selama pengembangan aplikasi Patungin (Split Bill dengan Scan Struk).

## 1. Mata Uang & Angka (Zero Double Rule)
- **Tipe Data:** Seluruh nilai moneter (subtotal, harga item, diskon, pajak, service, total, dan utang) disimpan dan dihitung dalam tipe `int` (Rupiah).
- **Larangan `double`:** Tidak ada komputasi uang berbasis `double` untuk mencegah floating-point rounding errors.
- **Konversi Persentase:** Input persentase dikonversi ke nominal Rupiah integer di satu fungsi helper khusus (`SplitCalculator.percentToAmount`) menggunakan basis points (`1% = 100 basis points`) dengan pembulatan bulat (`(base * basisPoints + 5000) ~/ 10000`).

## 2. Algoritma Pembagian (Largest Remainder Method)
- Pembagian harga item ke porsi partisipan menggunakan metode **Largest Remainder (Hamilton-Hare method)**:
  1. Bagian floor: `(total_price * portion) ~/ sum_portions`
  2. Sisa rupiah: `total_price - sum(floors)`
  3. Sisa 1 rupiah didistribusikan ke peserta dengan sisa pecahan terbesar (`(total_price * portion) % sum_portions`).
  4. Jika terjadi nilai sisa pecahan sama (tie-break), urutan ditentukan secara deterministik berdasarkan `sort_order` peserta.
- Pajak, service, dan diskon dialokasikan secara proporsional terhadap `itemsTotal` masing-masing peserta menggunakan metode largest remainder yang sama.
- Jika seluruh `itemsTotal` adalah 0 (misal bill kosong atau gratis), biaya tambahan dibagi rata ke seluruh peserta.

## 3. Utang-Piutang (Settlement)
- **Mode Tunggal (MVP):** Jika terdapat satu `paid_by_participant_id`, peserta lain berutang sebesar `totalToPay` mereka kepada pembayar tersebut. Pembayar tidak berutang ke siapa pun.
- **Tanpa Pembayar:** Jika pembayar belum dipilih, daftar settlement kosong dan UI hanya menampilkan rincian total per orang.
- **Tahap 2 (Multi-payer):** Menggunakan algoritma penyelesaian utang minimal (min-cash-flow greedy pairing antara kreditur dan debitur).

## 4. Parser OCR Struk (Receipt Parser)
- Format masukan OCR diabstraksikan menjadi `List<OcrLine>` dengan bounding box (`left, top, right, bottom`) agar pengujian parser bersifat pure Dart tanpa dependensi ML Kit.
- Garis visual dikelompokkan dengan toleransi overlap vertikal > 50% dan diurutkan kiri ke kanan.
- Parser mengecualikan kata kunci ringkasan (SUBTOTAL, TAX, PPN, SERVICE, DISCOUNT, TOTAL, dll.) dari daftar item konsumsi.
- Baris metadata/transaksi (CASH, CHANGE, KASIR, TANGGAL, dll.) diabaikan secara aman.
- Setiap item hasil parse memiliki tingkat keyakinan (`confidence` 0.0 - 1.0). Item dengan confidence rendah ditandai untuk ditinjau oleh pengguna.

## 5. Offline-First & Penyimpanan
- Seluruh data disimpan secara lokal menggunakan database Drift (SQLite).
- Foreign key diaktifkan dengan `PRAGMA foreign_keys = ON;` dan penghapusan relasi cascade (`ON DELETE CASCADE`).
- File gambar struk yang diambil disimpan di local storage aplikasi dan dihapus saat bill terkait dihapus.

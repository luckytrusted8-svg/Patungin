class NumberParser {
  /// Mem-parse representasi angka harga rupiah menjadi [int].
  ///
  /// Mendukung format:
  /// - "40.000" -> 40000
  /// - "40,000" -> 40000
  /// - "Rp40.000" / "Rp 40.000,-" -> 40000
  /// - "40.000,00" / "40,000.00" -> 40000
  /// - "40000" -> 40000
  /// - "1.250.000" -> 1250000
  /// - "abc" -> null
  static int? parse(String? input) {
    if (input == null) return null;
    var text = input.trim();
    if (text.isEmpty) return null;

    // Bersihkan prefix umum (Rp, RP, IDR, dll)
    text = text.replaceAll(RegExp(r'^(?:Rp\.?|IDR|idr)\s*', caseSensitive: false), '');

    // Bersihkan suffix umum seperti ",-", ".-", "-", "/-"
    text = text.replaceAll(RegExp(r'[,.]?-\s*$'), '').trim();

    // Dukungan format "k" atau "K" (mis. 35k -> 35000, 22.5k -> 22500)
    final kMatch = RegExp(r'^(\d+(?:[\.,]\d+)?)\s*[kK]$').firstMatch(text);
    if (kMatch != null) {
      final numStr = kMatch.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr);
      if (val != null) {
        return (val * 1000).round();
      }
    }

    // Normalisasi huruf 'O' / 'o' yang sering salah dibaca OCR sebagai angka 0 di antara digit/titik
    // misal: "35.OOO" -> "35.000", "2O.000" -> "20.000"
    if (RegExp(r'[\d\.,]+[oO]+[\d\.,]*').hasMatch(text)) {
      text = text.replaceAll(RegExp(r'[oO]'), '0');
    }

    // Deteksi desimal sen di akhir (mis. ",00" atau ".00" - dua digit)
    // Catatan: Jika ada 3 digit (mis. ".000"), itu pemisah ribuan, bukan desimal!
    final decimalMatch = RegExp(r'[,.](\d{2})$').firstMatch(text);
    if (decimalMatch != null) {
      // Hilangkan 2 digit desimal
      text = text.substring(0, decimalMatch.start).trim();
    }

    // Hilangkan semua pemisah ribuan (. atau , atau spasi)
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return null;

    // Pastikan string awal memang mengandung representasi angka yang valid
    // (bukan kata biasa yang kebetulan ada 1 angka terselip)
    // Hitung rasio digit terhadap karakter alfanumerik
    final alphaCount = text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (alphaCount > 0) {
      // Jika masih ada huruf setelah membersihkan prefix Rp/IDR, itu bukan angka murni
      return null;
    }

    return int.tryParse(digitsOnly);
  }
}

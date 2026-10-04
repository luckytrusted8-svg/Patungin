import 'number_parser.dart';
import 'parsed_receipt.dart';

class ReceiptParser {
  // Regex kata kunci ringkasan
  static final _subtotalRegex =
      RegExp(r'(?:sub[\s\-_]?total)', caseSensitive: false);
  static final _taxRegex =
      RegExp(r'(?:ppn|tax|pb1|pajak)', caseSensitive: false);
  static final _serviceRegex = RegExp(
      r'(?:service[\s\-_]?(?:charge)?|layanan|sc\b)',
      caseSensitive: false);
  static final _discountRegex = RegExp(
      r'(?:diskon|discount|promo|potongan|voucher)',
      caseSensitive: false);
  static final _totalRegex =
      RegExp(r'(?:grand[\s\-_]?total|total[\s\-_]?tagihan|total\b)',
          caseSensitive: false);

  // Regex kata kunci sampah (abaikan)
  static final _garbageRegex = RegExp(
    r'(?:tunai|cash\b|kembali|kembalian|change\b|debit|qris|kartu|visa|mastercard|kasir|cashier|meja|table\b|no\.?|struk|receipt|terima\s+kasih|thank\s+you|selamat\s+menikmati|telp|phone|jalan|jl\.?|wifi|password|order\s+id|invoice)',
    caseSensitive: false,
  );

  // Regex header nama restoran/toko
  static final _storeHeaderRegex = RegExp(
    r'^(?:warung|resto|restoran|cafe|kedai|pt\.|cv\.|depot|cabang|outlet|store)\b',
    caseSensitive: false,
  );

  static final _dateTimeRegex = RegExp(
    r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})|(\d{1,2}:\d{2}(:\d{2})?)',
  );

  /// Mem-parse daftar baris OCR menjadi [ParsedReceipt].
  /// Tidak akan crash pada input kosong atau tidak beraturan.
  static ParsedReceipt parse(List<OcrLine> ocrLines) {
    if (ocrLines.isEmpty) {
      return const ParsedReceipt(
        items: [],
        rawText: '',
        isEmpty: true,
        rawLines: [],
      );
    }

    final rawCombined = ocrLines.map((l) => l.text).join('\n');

    // 1. Kelompokkan baris visual berdasarkan koordinat Y
    final visualLines = _groupIntoVisualLines(ocrLines);

    final items = <ParsedItem>[];
    int? subtotal;
    int? tax;
    int? service;
    int? discount;
    int? total;

    int i = 0;
    while (i < visualLines.length) {
      final line = visualLines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Cek apakah baris ringkasan
      if (_subtotalRegex.hasMatch(line)) {
        subtotal ??= _extractPriceFromEnd(line);
        i++;
        continue;
      }
      if (_taxRegex.hasMatch(line)) {
        tax ??= _extractPriceFromEnd(line);
        i++;
        continue;
      }
      if (_serviceRegex.hasMatch(line)) {
        service ??= _extractPriceFromEnd(line);
        i++;
        continue;
      }
      if (_discountRegex.hasMatch(line)) {
        discount ??= _extractPriceFromEnd(line);
        i++;
        continue;
      }
      if (_totalRegex.hasMatch(line) && !_subtotalRegex.hasMatch(line)) {
        total ??= _extractPriceFromEnd(line);
        i++;
        continue;
      }

      // Cek apakah baris sampah (kasir, tanggal, qris, alamat, dll)
      if (_garbageRegex.hasMatch(line) || _dateTimeRegex.hasMatch(line)) {
        i++;
        continue;
      }

      // Coba parse item satu baris
      var parsed = _parseSingleLineItem(line);

      // Jika gagal dan baris ini bukan header toko, cek apakah bisa digabung dengan baris berikutnya (Pola Dua Baris).
      // Catatan: Baris berikutnya HANYA boleh digabung jika baris berikutnya BUKAN item mandiri yang lengkap.
      if (parsed == null && !_storeHeaderRegex.hasMatch(line) && i + 1 < visualLines.length) {
        final nextLine = visualLines[i + 1].trim();
        if (!_isSummaryOrGarbage(nextLine) && _parseSingleLineItem(nextLine) == null) {
          final combined = '$line $nextLine';
          parsed = _parseSingleLineItem(combined);
          if (parsed != null) {
            items.add(parsed);
            i += 2;
            continue;
          }
        }
      }

      if (parsed != null) {
        items.add(parsed);
      }

      i++;
    }

    // Fallback: Jika tidak ada item yang terdeteksi dari visualLines,
    // coba scan langsung dari urutan ocrLines teks asli
    if (items.isEmpty && ocrLines.length > 1) {
      int j = 0;
      final rawLineTexts = ocrLines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).toList();
      while (j < rawLineTexts.length) {
        final text = rawLineTexts[j];
        var parsed = _parseSingleLineItem(text);
        if (parsed != null) {
          items.add(parsed);
          j++;
          continue;
        }

        // Coba gabung dua baris berurutan
        if (j + 1 < rawLineTexts.length && !_isSummaryOrGarbage(text)) {
          final next = rawLineTexts[j + 1];
          final combined = '$text $next';
          parsed = _parseSingleLineItem(combined);
          if (parsed != null) {
            items.add(parsed);
            j += 2;
            continue;
          }
        }
        j++;
      }
    }

    return ParsedReceipt(
      items: items,
      subtotal: subtotal,
      tax: tax,
      service: service,
      discount: discount,
      total: total,
      rawText: rawCombined,
      isEmpty: items.isEmpty && subtotal == null && total == null,
      rawLines: ocrLines,
    );
  }

  static bool _isSummaryOrGarbage(String line) {
    return _subtotalRegex.hasMatch(line) ||
        _taxRegex.hasMatch(line) ||
        _serviceRegex.hasMatch(line) ||
        _discountRegex.hasMatch(line) ||
        _totalRegex.hasMatch(line) ||
        _garbageRegex.hasMatch(line) ||
        _dateTimeRegex.hasMatch(line);
  }

  /// Mengelompokkan elemen ke baris visual berdasarkan koordinat Y (overlap vertikal atau center Y)
  static List<String> _groupIntoVisualLines(List<OcrLine> lines) {
    if (lines.isEmpty) return const [];

    final hasCoordinates = lines.any((l) => l.bottom > 0 || l.right > 0);
    if (!hasCoordinates) {
      return lines.map((l) => l.text).toList();
    }

    final sorted = List<OcrLine>.from(lines)
      ..sort((a, b) => a.top.compareTo(b.top));

    final groups = <List<OcrLine>>[];

    for (final line in sorted) {
      bool added = false;
      final lineCenterY = (line.top + line.bottom) / 2.0;

      for (final group in groups) {
        final ref = group.first;
        final refCenterY = (ref.top + ref.bottom) / 2.0;
        final avgHeight = (ref.height + line.height) / 2.0;

        final centerDiff = (lineCenterY - refCenterY).abs();
        final maxCenterDiff = avgHeight * 0.75;

        final overlapTop = line.top > ref.top ? line.top : ref.top;
        final overlapBottom =
            line.bottom < ref.bottom ? line.bottom : ref.bottom;
        final overlap = overlapBottom - overlapTop;

        final minHeight = ref.height < line.height ? ref.height : line.height;
        if (centerDiff <= maxCenterDiff || (minHeight > 0 && (overlap / minHeight) > 0.25)) {
          group.add(line);
          added = true;
          break;
        }
      }

      if (!added) {
        groups.add([line]);
      }
    }

    final result = <String>[];
    for (final group in groups) {
      group.sort((a, b) => a.left.compareTo(b.left));
      result.add(group.map((l) => l.text).join(' '));
    }

    return result;
  }

  /// Ekstrak angka harga dari ujung baris teks
  static int? _extractPriceFromEnd(String text) {
    final tokens = text.trim().split(RegExp(r'\s+'));
    for (int i = tokens.length - 1; i >= 0; i--) {
      final price = NumberParser.parse(tokens[i]);
      if (price != null && price > 0) {
        return price;
      }
    }
    return null;
  }

  /// Mem-parse satu baris teks menjadi [ParsedItem]
  static ParsedItem? _parseSingleLineItem(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    if (_isSummaryOrGarbage(clean)) return null;
    if (_storeHeaderRegex.hasMatch(clean) && _extractPriceFromEnd(clean) == null) {
      return null;
    }

    // Pola 1: "{qty}x {nama} {harga}" atau "{qty} x {nama} {harga}" atau "{qty} {nama} {harga}"
    final pattern1 = RegExp(
      r'^(\d+)\s*(?:x\s*|\s+)(.+?)\s+((?:Rp\.?\s*)?[\d\.,oOkK]+(?:,-)?)$',
      caseSensitive: false,
    );
    final match1 = pattern1.firstMatch(clean);
    if (match1 != null) {
      final qty = int.tryParse(match1.group(1)!) ?? 1;
      final name = match1.group(2)!.trim();
      final totalPrice = NumberParser.parse(match1.group(3)!);

      if (totalPrice != null && totalPrice > 0 && name.length >= 2 && !_isSummaryOrGarbage(name)) {
        final unitPrice = qty > 0 ? (totalPrice ~/ qty) : totalPrice;
        return ParsedItem(
          name: name,
          quantity: qty,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          confidence: _calculateConfidence(name, qty, unitPrice, totalPrice),
          rawText: clean,
        );
      }
    }

    // Pola 2: "{nama} {qty} x {unit} {total}" atau "{nama} {qty}x {unit} {total}"
    final pattern2 = RegExp(
      r'^(.+?)\s+(\d+)\s*(?:x\s*|\s+)\s*((?:Rp\.?\s*)?[\d\.,oOkK]+)\s+((?:Rp\.?\s*)?[\d\.,oOkK]+)$',
      caseSensitive: false,
    );
    final match2 = pattern2.firstMatch(clean);
    if (match2 != null) {
      final name = match2.group(1)!.trim();
      final qty = int.tryParse(match2.group(2)!) ?? 1;
      final unitPrice = NumberParser.parse(match2.group(3)!);
      final totalPrice = NumberParser.parse(match2.group(4)!);

      if (totalPrice != null && totalPrice > 0 && name.length >= 2 && !_isSummaryOrGarbage(name)) {
        final effectiveUnit = unitPrice ?? (totalPrice ~/ qty);
        return ParsedItem(
          name: name,
          quantity: qty,
          unitPrice: effectiveUnit,
          totalPrice: totalPrice,
          confidence: _calculateConfidence(name, qty, effectiveUnit, totalPrice),
          rawText: clean,
        );
      }
    }

    // Pola 3: "{nama} {harga}" (qty = 1)
    final pattern3 = RegExp(
      r'^(.+?)\s+((?:Rp\.?\s*)?[\d\.,oOkK]+(?:,-)?)$',
      caseSensitive: false,
    );
    final match3 = pattern3.firstMatch(clean);
    if (match3 != null) {
      final name = match3.group(1)!.trim();
      final price = NumberParser.parse(match3.group(2)!);

      if (price != null && price > 0 && name.length >= 2) {
        if (_isSummaryOrGarbage(name)) return null;

        return ParsedItem(
          name: name,
          quantity: 1,
          unitPrice: price,
          totalPrice: price,
          confidence: _calculateConfidence(name, 1, price, price),
          rawText: clean,
        );
      }
    }

    return null;
  }

  static double _calculateConfidence(
    String name,
    int qty,
    int unitPrice,
    int totalPrice,
  ) {
    double conf = 1.0;
    if (name.length < 3) conf -= 0.3;
    if (qty <= 0) conf -= 0.3;
    if (unitPrice <= 0 || totalPrice <= 0) conf -= 0.4;
    if (unitPrice * qty != totalPrice) conf -= 0.2;
    if (conf < 0.1) conf = 0.1;
    if (conf > 1.0) conf = 1.0;
    return conf;
  }
}

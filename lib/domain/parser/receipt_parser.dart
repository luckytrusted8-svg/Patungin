import 'number_parser.dart';
import 'parsed_receipt.dart';

class _DetailLineInfo {
  final int quantity;
  final String? unit;
  final int unitPrice;
  final int? totalPrice;

  const _DetailLineInfo({
    required this.quantity,
    this.unit,
    required this.unitPrice,
    this.totalPrice,
  });
}

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

  // Regex kata kunci pembayaran (wajib diabaikan agar tidak salah menjadi item belanja)
  static final _paymentRegex = RegExp(
    r'(?:bayar\b|pembayaran\b|tunai\b|cash\b|kembali\b|kembalian\b|change\b|debit\b|qris\b|kartu\b|visa\b|mastercard\b|dp\b|uang\s*muka)',
    caseSensitive: false,
  );

  // Regex kata kunci sampah (abaikan)
  static final _garbageRegex = RegExp(
    r'(?:kasir|cashier|meja|table\b|no\.?|struk|receipt|terima\s+kasih|thank\s+you|selamat\s+menikmati|telp|phone|jalan|jl\.?|wifi|password|order\s+id|invoice|alamat|customer|pelanggan)',
    caseSensitive: false,
  );

  // Regex header nama restoran/toko
  static final _storeHeaderRegex = RegExp(
    r'^(?:warung|resto|restoran|cafe|kedai|kopi|pt\.|cv\.|depot|cabang|outlet|store|toko|grosir)\b',
    caseSensitive: false,
  );

  static final _dateTimeRegex = RegExp(
    r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})|(\d{1,2}:\d{2}(:\d{2})?)',
  );

  // Detail line regex (Pola kuantitas x harga satuan):
  // Contoh:
  // "4.000 Kg X 12.500 Rp. 50.000.000"
  // "1600 Kg X 27.500 Rp. 44.000.000"
  // "800 Box X 7.500 Rp. 6.000.000"
  // "8.000 Pcs X 3.000 Rp. 24.000.000"
  // "2 Pcs @ 15.000 30.000"
  // "2 x 15.000"
  static final _detailMultiplierRegex = RegExp(
    r'^([\d\.,]+)\s*([a-zA-Z]{1,8})?\s*(?:[xX@*]|\b(?:x|at)\b)\s*((?:Rp\.?\s*)?[\d\.,oOkK]+)(?:\s+((?:Rp\.?\s*)?[\d\.,oOkK]+))?$',
    caseSensitive: false,
  );

  static final _detailPriceOnlyRegex = RegExp(
    r'^(?:Rp\.?\s*)?[\d\.,oOkK]+(?:,-)?$',
    caseSensitive: false,
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

      // Cek apakah baris pembayaran atau sampah
      if (_isSummaryOrGarbage(line)) {
        i++;
        continue;
      }

      // 2. Cek Pola Dua Baris terlebih dahulu:
      // Apakah baris berikutnya (i + 1) adalah baris detail kuantitas & harga?
      // Jika ya, dan baris saat ini (i) adalah nama produk yang valid:
      if (i + 1 < visualLines.length && !_storeHeaderRegex.hasMatch(line)) {
        final nextLine = visualLines[i + 1].trim();
        final detail = _parseDetailLine(nextLine);
        if (detail != null) {
          final name = _cleanItemName(line);
          if (name.length >= 2 && !_isSummaryOrGarbage(name)) {
            final effectiveTotal =
                detail.totalPrice ?? (detail.quantity * detail.unitPrice);
            items.add(
              ParsedItem(
                name: name,
                quantity: detail.quantity,
                unit: detail.unit,
                unitPrice: detail.unitPrice,
                totalPrice: effectiveTotal,
                confidence: _calculateConfidence(
                  name,
                  detail.quantity,
                  detail.unitPrice,
                  effectiveTotal,
                ),
                rawText: '$line $nextLine',
              ),
            );
            i += 2;
            continue;
          }
        }
      }

      // 3. Coba parse item satu baris
      var parsed = _parseSingleLineItem(line);

      // 4. Jika gagal dan baris ini bukan header toko, cek fallback penggabungan baris
      if (parsed == null &&
          !_storeHeaderRegex.hasMatch(line) &&
          i + 1 < visualLines.length) {
        final nextLine = visualLines[i + 1].trim();
        if (!_isSummaryOrGarbage(nextLine) &&
            _parseSingleLineItem(nextLine) == null) {
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
      final rawLineTexts = ocrLines
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      while (j < rawLineTexts.length) {
        final text = rawLineTexts[j];
        if (_isSummaryOrGarbage(text)) {
          j++;
          continue;
        }

        // Cek pola dua baris
        if (j + 1 < rawLineTexts.length && !_storeHeaderRegex.hasMatch(text)) {
          final next = rawLineTexts[j + 1];
          final detail = _parseDetailLine(next);
          if (detail != null) {
            final name = _cleanItemName(text);
            if (name.length >= 2 && !_isSummaryOrGarbage(name)) {
              final effectiveTotal =
                  detail.totalPrice ?? (detail.quantity * detail.unitPrice);
              items.add(
                ParsedItem(
                  name: name,
                  quantity: detail.quantity,
                  unit: detail.unit,
                  unitPrice: detail.unitPrice,
                  totalPrice: effectiveTotal,
                  confidence: _calculateConfidence(
                    name,
                    detail.quantity,
                    detail.unitPrice,
                    effectiveTotal,
                  ),
                  rawText: '$text $next',
                ),
              );
              j += 2;
              continue;
            }
          }
        }

        var parsed = _parseSingleLineItem(text);
        if (parsed != null) {
          items.add(parsed);
          j++;
          continue;
        }

        // Coba gabung dua baris berurutan
        if (j + 1 < rawLineTexts.length) {
          final next = rawLineTexts[j + 1];
          if (!_isSummaryOrGarbage(next) &&
              _parseSingleLineItem(next) == null) {
            final combined = '$text $next';
            parsed = _parseSingleLineItem(combined);
            if (parsed != null) {
              items.add(parsed);
              j += 2;
              continue;
            }
          }
        }
        j++;
      }
    }

    // 5. Validasi silang matematis dengan Subtotal (jika ada):
    _crossValidateItemsWithSubtotal(items, subtotal);

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
        _paymentRegex.hasMatch(line) ||
        _garbageRegex.hasMatch(line) ||
        _dateTimeRegex.hasMatch(line);
  }

  static String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'^[\s\-_:=*#\.\+]+|[\s\-_:=*#\.\+]+$'), '')
        .trim();
  }

  /// Mem-parse baris detail kuantitas & harga
  static _DetailLineInfo? _parseDetailLine(String text) {
    final clean = text.trim();
    if (clean.isEmpty || _isSummaryOrGarbage(clean)) return null;

    final match = _detailMultiplierRegex.firstMatch(clean);
    if (match != null) {
      final qtyRaw = match.group(1)!;
      final unit = match.group(2);
      final unitPriceStr = match.group(3)!;
      final totalPriceStr = match.group(4);

      final unitPrice = NumberParser.parse(unitPriceStr);
      if (unitPrice == null || unitPrice <= 0) return null;

      final parsedTotal =
          totalPriceStr != null ? NumberParser.parse(totalPriceStr) : null;

      // Parsing kuantitas cerdas:
      // Di Indonesia "4.000" bisa berarti 4000 atau 4.
      // Validasi matematis dengan unitPrice & parsedTotal:
      int quantity = 1;
      final candidateThousands = NumberParser.parse(qtyRaw); // 4000
      final candidateSmall =
          int.tryParse(qtyRaw.split(RegExp(r'[\.,]')).first); // 4

      if (parsedTotal != null && parsedTotal > 0) {
        if (candidateThousands != null &&
            candidateThousands * unitPrice == parsedTotal) {
          quantity = candidateThousands;
        } else if (candidateSmall != null &&
            candidateSmall * unitPrice == parsedTotal) {
          quantity = candidateSmall;
        } else if (parsedTotal % unitPrice == 0) {
          quantity = parsedTotal ~/ unitPrice;
        } else {
          quantity = candidateThousands ?? candidateSmall ?? 1;
        }
      } else {
        if (candidateThousands != null &&
            candidateThousands > 100 &&
            unitPrice > 1000) {
          quantity = candidateThousands;
        } else {
          quantity = candidateSmall ?? candidateThousands ?? 1;
        }
      }

      // Validasi & auto-koreksi total price jika ada typo OCR
      // Contoh: 800 x 9.000 = 7.200.000, tapi OCR membaca 7.800.000
      int effectiveTotal = parsedTotal ?? (quantity * unitPrice);
      if (quantity > 0 && unitPrice > 0) {
        final expected = quantity * unitPrice;
        if (parsedTotal != null && parsedTotal != expected) {
          effectiveTotal = expected;
        }
      }

      return _DetailLineInfo(
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: effectiveTotal,
      );
    }

    // Pola harga saja (qty = 1)
    if (_detailPriceOnlyRegex.hasMatch(clean)) {
      final price = NumberParser.parse(clean);
      if (price != null && price >= 500) {
        return _DetailLineInfo(
          quantity: 1,
          unitPrice: price,
          totalPrice: price,
        );
      }
    }

    return null;
  }

  /// Koreksi otomatis typo kecil jika ada selisih dengan subtotal
  static void _crossValidateItemsWithSubtotal(
      List<ParsedItem> items, int? subtotal) {
    if (subtotal == null || items.isEmpty) return;
    final currentSum = items.fold<int>(0, (s, i) => s + i.totalPrice);
    final diff = subtotal - currentSum;
    if (diff == 0) return;

    // Cek apakah ada 1 item yang jika dikoreksi dengan expected (qty * unitPrice) akan pas dengan subtotal
    for (int idx = 0; idx < items.length; idx++) {
      final item = items[idx];
      final expected = item.quantity * item.unitPrice;
      if (expected != item.totalPrice) {
        final newSum = currentSum - item.totalPrice + expected;
        if (newSum == subtotal) {
          items[idx] = item.copyWith(totalPrice: expected);
          return;
        }
      }
    }
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
      final lineCenterY = (line.top + line.bottom) / 2.0;

      List<OcrLine>? bestGroup;
      double minCenterDiff = double.infinity;

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

        if (centerDiff <= maxCenterDiff ||
            (minHeight > 0 && (overlap / minHeight) > 0.25)) {
          if (centerDiff < minCenterDiff) {
            minCenterDiff = centerDiff;
            bestGroup = group;
          }
        }
      }

      if (bestGroup != null) {
        bestGroup.add(line);
      } else {
        groups.add([line]);
      }
    }

    // Urutkan grup berdasarkan rata-rata Y
    groups.sort((a, b) {
      final aY = a.fold<double>(0, (s, l) => s + l.centerY) / a.length;
      final bY = b.fold<double>(0, (s, l) => s + l.centerY) / b.length;
      return aY.compareTo(bY);
    });

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
    if (_storeHeaderRegex.hasMatch(clean) &&
        _extractPriceFromEnd(clean) == null) {
      return null;
    }

    // Jika baris ini merupakan baris detail murni (misal: "4.000 Kg X 12.500 Rp. 50.000.000"),
    // JANGAN parse sebagai single-line item karena nama produknya ada di baris lain!
    if (_detailMultiplierRegex.hasMatch(clean)) {
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
      final name = _cleanItemName(match1.group(2)!);
      final totalPrice = NumberParser.parse(match1.group(3)!);

      if (totalPrice != null &&
          totalPrice >= 500 &&
          name.length >= 2 &&
          !_isSummaryOrGarbage(name)) {
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
      final name = _cleanItemName(match2.group(1)!);
      final qty = int.tryParse(match2.group(2)!) ?? 1;
      final unitPrice = NumberParser.parse(match2.group(3)!);
      final totalPrice = NumberParser.parse(match2.group(4)!);

      if (totalPrice != null &&
          totalPrice >= 500 &&
          name.length >= 2 &&
          !_isSummaryOrGarbage(name)) {
        final effectiveUnit = unitPrice ?? (totalPrice ~/ qty);
        return ParsedItem(
          name: name,
          quantity: qty,
          unitPrice: effectiveUnit,
          totalPrice: totalPrice,
          confidence:
              _calculateConfidence(name, qty, effectiveUnit, totalPrice),
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
      final name = _cleanItemName(match3.group(1)!);
      final priceStr = match3.group(2)!.trim();
      final price = NumberParser.parse(priceStr);

      if (price != null && price > 0 && name.length >= 2) {
        if (_isSummaryOrGarbage(name)) return null;

        // Cegah angka kecil tanpa prefix Rp/k dianggap harga (misal: "Isi 25", "Meja 14", "600 ml")
        final isExplicitPrice = priceStr.toLowerCase().contains('rp') ||
            priceStr.toLowerCase().endsWith('k') ||
            priceStr.contains('.') ||
            priceStr.contains(',');
        if (price < 500 && !isExplicitPrice) {
          return null;
        }

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

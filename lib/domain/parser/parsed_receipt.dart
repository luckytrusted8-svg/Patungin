class OcrLine {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrLine({
    required this.text,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  double get height => (bottom - top).abs();
  double get width => (right - left).abs();
  double get centerY => top + (height / 2);

  @override
  String toString() => 'OcrLine("$text", y: $top-$bottom, x: $left-$right)';
}

class ParsedItem {
  final String name;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final double confidence; // 0.0 to 1.0
  final String rawText;

  const ParsedItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.confidence = 1.0,
    required this.rawText,
  });

  bool get isLowConfidence => confidence < 0.7;

  ParsedItem copyWith({
    String? name,
    int? quantity,
    int? unitPrice,
    int? totalPrice,
    double? confidence,
    String? rawText,
  }) {
    final newQty = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;
    return ParsedItem(
      name: name ?? this.name,
      quantity: newQty,
      unitPrice: newUnitPrice,
      totalPrice: totalPrice ?? (newQty * newUnitPrice),
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() =>
      'ParsedItem(name: "$name", qty: $quantity, unit: $unitPrice, total: $totalPrice, conf: $confidence)';
}

class ParsedReceipt {
  final List<ParsedItem> items;
  final int? subtotal;
  final int? tax;
  final int? service;
  final int? discount;
  final int? total;
  final String rawText;
  final bool isEmpty;
  final List<OcrLine> rawLines;

  const ParsedReceipt({
    required this.items,
    this.subtotal,
    this.tax,
    this.service,
    this.discount,
    this.total,
    this.rawText = '',
    this.isEmpty = false,
    this.rawLines = const [],
  });

  /// Total dari semua item yang ter-parse
  int get itemsSum => items.fold<int>(0, (sum, i) => sum + i.totalPrice);

  /// Cek apakah subtotal konsisten dengan jumlah item
  bool get isSubtotalConsistent => subtotal == null || subtotal == itemsSum;

  /// Selisih antara subtotal dan total semua item
  int get subtotalDifference => (subtotal ?? itemsSum) - itemsSum;
}

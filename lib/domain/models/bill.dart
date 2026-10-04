class Bill {
  final String id;
  final String title;
  final DateTime createdAt;
  final int subtotal;
  final int taxAmount;
  final int serviceAmount;
  final int discountAmount;
  final int total;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? paidByParticipantId;

  const Bill({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.subtotal,
    this.taxAmount = 0,
    this.serviceAmount = 0,
    this.discountAmount = 0,
    required this.total,
    this.receiptImagePath,
    this.rawOcrText,
    this.paidByParticipantId,
  });

  /// Total yang dihitung dari subtotal + tax + service - discount
  int get calculatedTotal => subtotal + taxAmount + serviceAmount - discountAmount;

  /// Selisih antara total struk dengan total terhitung
  int get totalDifference => total - calculatedTotal;

  Bill copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    int? subtotal,
    int? taxAmount,
    int? serviceAmount,
    int? discountAmount,
    int? total,
    String? receiptImagePath,
    String? rawOcrText,
    String? paidByParticipantId,
    bool clearPaidBy = false,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceAmount: serviceAmount ?? this.serviceAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      paidByParticipantId:
          clearPaidBy ? null : (paidByParticipantId ?? this.paidByParticipantId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bill &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt &&
          subtotal == other.subtotal &&
          taxAmount == other.taxAmount &&
          serviceAmount == other.serviceAmount &&
          discountAmount == other.discountAmount &&
          total == other.total &&
          receiptImagePath == other.receiptImagePath &&
          rawOcrText == other.rawOcrText &&
          paidByParticipantId == other.paidByParticipantId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      createdAt.hashCode ^
      subtotal.hashCode ^
      taxAmount.hashCode ^
      serviceAmount.hashCode ^
      discountAmount.hashCode ^
      total.hashCode ^
      receiptImagePath.hashCode ^
      rawOcrText.hashCode ^
      paidByParticipantId.hashCode;

  @override
  String toString() =>
      'Bill(id: $id, title: $title, total: $total, calculatedTotal: $calculatedTotal)';
}

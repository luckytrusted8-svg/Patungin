class BillItem {
  final String id;
  final String billId;
  final String name;
  final int unitPrice;
  final int quantity;
  final int totalPrice;
  final int sortOrder;

  const BillItem({
    required this.id,
    required this.billId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.sortOrder,
  });

  factory BillItem.create({
    required String id,
    required String billId,
    required String name,
    required int unitPrice,
    required int quantity,
    required int sortOrder,
  }) {
    if (quantity < 1) {
      throw ArgumentError('Quantity minimal 1');
    }
    if (unitPrice < 0) {
      throw ArgumentError('Unit price tidak boleh negatif');
    }
    return BillItem(
      id: id,
      billId: billId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      totalPrice: unitPrice * quantity,
      sortOrder: sortOrder,
    );
  }

  BillItem copyWith({
    String? id,
    String? billId,
    String? name,
    int? unitPrice,
    int? quantity,
    int? totalPrice,
    int? sortOrder,
  }) {
    final newUnitPrice = unitPrice ?? this.unitPrice;
    final newQuantity = quantity ?? this.quantity;
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      unitPrice: newUnitPrice,
      quantity: newQuantity,
      totalPrice: totalPrice ?? (newUnitPrice * newQuantity),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          billId == other.billId &&
          name == other.name &&
          unitPrice == other.unitPrice &&
          quantity == other.quantity &&
          totalPrice == other.totalPrice &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      billId.hashCode ^
      name.hashCode ^
      unitPrice.hashCode ^
      quantity.hashCode ^
      totalPrice.hashCode ^
      sortOrder.hashCode;

  @override
  String toString() =>
      'BillItem(id: $id, name: $name, unitPrice: $unitPrice, quantity: $quantity, totalPrice: $totalPrice)';
}

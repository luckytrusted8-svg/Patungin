class Participant {
  final String id;
  final String billId;
  final String name;
  final int sortOrder;

  const Participant({
    required this.id,
    required this.billId,
    required this.name,
    required this.sortOrder,
  });

  Participant copyWith({
    String? id,
    String? billId,
    String? name,
    int? sortOrder,
  }) {
    return Participant(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          billId == other.billId &&
          name == other.name &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^ billId.hashCode ^ name.hashCode ^ sortOrder.hashCode;

  @override
  String toString() =>
      'Participant(id: $id, name: $name, sortOrder: $sortOrder)';
}

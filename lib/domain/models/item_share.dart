class ItemShare {
  final String id;
  final String itemId;
  final String participantId;
  final int portion;

  const ItemShare({
    required this.id,
    required this.itemId,
    required this.participantId,
    this.portion = 1,
  });

  ItemShare copyWith({
    String? id,
    String? itemId,
    String? participantId,
    int? portion,
  }) {
    return ItemShare(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      participantId: participantId ?? this.participantId,
      portion: portion ?? this.portion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemShare &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemId == other.itemId &&
          participantId == other.participantId &&
          portion == other.portion;

  @override
  int get hashCode =>
      id.hashCode ^ itemId.hashCode ^ participantId.hashCode ^ portion.hashCode;

  @override
  String toString() =>
      'ItemShare(itemId: $itemId, participantId: $participantId, portion: $portion)';
}

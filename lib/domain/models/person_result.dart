class PersonItemBreakdown {
  final String itemId;
  final String itemName;
  final int portion;
  final int totalPortions;
  final int allocatedPrice;

  const PersonItemBreakdown({
    required this.itemId,
    required this.itemName,
    required this.portion,
    required this.totalPortions,
    required this.allocatedPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonItemBreakdown &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          itemName == other.itemName &&
          portion == other.portion &&
          totalPortions == other.totalPortions &&
          allocatedPrice == other.allocatedPrice;

  @override
  int get hashCode =>
      itemId.hashCode ^
      itemName.hashCode ^
      portion.hashCode ^
      totalPortions.hashCode ^
      allocatedPrice.hashCode;
}

class PersonResult {
  final String participantId;
  final String name;
  final int itemsTotal;
  final int taxShare;
  final int serviceShare;
  final int discountShare;
  final int totalToPay;
  final List<PersonItemBreakdown> itemDetails;

  const PersonResult({
    required this.participantId,
    required this.name,
    required this.itemsTotal,
    required this.taxShare,
    required this.serviceShare,
    required this.discountShare,
    required this.totalToPay,
    this.itemDetails = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonResult &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId &&
          name == other.name &&
          itemsTotal == other.itemsTotal &&
          taxShare == other.taxShare &&
          serviceShare == other.serviceShare &&
          discountShare == other.discountShare &&
          totalToPay == other.totalToPay;

  @override
  int get hashCode =>
      participantId.hashCode ^
      name.hashCode ^
      itemsTotal.hashCode ^
      taxShare.hashCode ^
      serviceShare.hashCode ^
      discountShare.hashCode ^
      totalToPay.hashCode;

  @override
  String toString() =>
      'PersonResult(name: $name, itemsTotal: $itemsTotal, tax: $taxShare, service: $serviceShare, discount: $discountShare, totalToPay: $totalToPay)';
}

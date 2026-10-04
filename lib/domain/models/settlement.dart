class Settlement {
  final String fromParticipantId;
  final String fromName;
  final String toParticipantId;
  final String toName;
  final int amount;

  const Settlement({
    required this.fromParticipantId,
    required this.fromName,
    required this.toParticipantId,
    required this.toName,
    required this.amount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settlement &&
          runtimeType == other.runtimeType &&
          fromParticipantId == other.fromParticipantId &&
          fromName == other.fromName &&
          toParticipantId == other.toParticipantId &&
          toName == other.toName &&
          amount == other.amount;

  @override
  int get hashCode =>
      fromParticipantId.hashCode ^
      fromName.hashCode ^
      toParticipantId.hashCode ^
      toName.hashCode ^
      amount.hashCode;

  @override
  String toString() => '$fromName bayar $amount ke $toName';
}

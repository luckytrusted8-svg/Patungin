import 'bill.dart';
import 'bill_item.dart';
import 'item_share.dart';
import 'participant.dart';

class CompleteBill {
  final Bill bill;
  final List<Participant> participants;
  final List<BillItem> items;
  final List<ItemShare> shares;

  const CompleteBill({
    required this.bill,
    required this.participants,
    required this.items,
    required this.shares,
  });

  CompleteBill copyWith({
    Bill? bill,
    List<Participant>? participants,
    List<BillItem>? items,
    List<ItemShare>? shares,
  }) {
    return CompleteBill(
      bill: bill ?? this.bill,
      participants: participants ?? this.participants,
      items: items ?? this.items,
      shares: shares ?? this.shares,
    );
  }
}

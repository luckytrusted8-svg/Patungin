import 'package:drift/drift.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../../domain/models/item_share.dart';
import '../../domain/models/participant.dart';
import '../db/app_database.dart';

class BillMapper {
  // --- Bill ---
  static Bill toDomainBill(BillEntry entry) {
    return Bill(
      id: entry.id,
      title: entry.title,
      createdAt: entry.createdAt,
      subtotal: entry.subtotal,
      taxAmount: entry.taxAmount,
      serviceAmount: entry.serviceAmount,
      discountAmount: entry.discountAmount,
      total: entry.total,
      receiptImagePath: entry.receiptImagePath,
      rawOcrText: entry.rawOcrText,
      paidByParticipantId: entry.paidByParticipantId,
    );
  }

  static BillsCompanion toCompanionBill(Bill bill) {
    return BillsCompanion.insert(
      id: bill.id,
      title: bill.title,
      createdAt: bill.createdAt,
      subtotal: bill.subtotal,
      taxAmount: Value(bill.taxAmount),
      serviceAmount: Value(bill.serviceAmount),
      discountAmount: Value(bill.discountAmount),
      total: bill.total,
      receiptImagePath: Value(bill.receiptImagePath),
      rawOcrText: Value(bill.rawOcrText),
      paidByParticipantId: Value(bill.paidByParticipantId),
    );
  }

  // --- Participant ---
  static Participant toDomainParticipant(ParticipantEntry entry) {
    return Participant(
      id: entry.id,
      billId: entry.billId,
      name: entry.name,
      sortOrder: entry.sortOrder,
    );
  }

  static ParticipantsCompanion toCompanionParticipant(Participant p) {
    return ParticipantsCompanion.insert(
      id: p.id,
      billId: p.billId,
      name: p.name,
      sortOrder: Value(p.sortOrder),
    );
  }

  // --- BillItem ---
  static BillItem toDomainBillItem(BillItemEntry entry) {
    return BillItem(
      id: entry.id,
      billId: entry.billId,
      name: entry.name,
      unitPrice: entry.unitPrice,
      quantity: entry.quantity,
      totalPrice: entry.totalPrice,
      sortOrder: entry.sortOrder,
    );
  }

  static BillItemsCompanion toCompanionBillItem(BillItem item) {
    return BillItemsCompanion.insert(
      id: item.id,
      billId: item.billId,
      name: item.name,
      unitPrice: item.unitPrice,
      quantity: Value(item.quantity),
      totalPrice: item.totalPrice,
      sortOrder: Value(item.sortOrder),
    );
  }

  // --- ItemShare ---
  static ItemShare toDomainItemShare(ItemShareEntry entry) {
    return ItemShare(
      id: entry.id,
      itemId: entry.itemId,
      participantId: entry.participantId,
      portion: entry.portion,
    );
  }

  static ItemSharesCompanion toCompanionItemShare(ItemShare s) {
    return ItemSharesCompanion.insert(
      id: s.id,
      itemId: s.itemId,
      participantId: s.participantId,
      portion: Value(s.portion),
    );
  }
}

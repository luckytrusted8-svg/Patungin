import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/data/db/app_database.dart';
import 'package:patungin/data/repositories/bill_repository.dart';
import 'package:patungin/domain/models/bill.dart';
import 'package:patungin/domain/models/bill_item.dart';
import 'package:patungin/domain/models/complete_bill.dart';
import 'package:patungin/domain/models/item_share.dart';
import 'package:patungin/domain/models/participant.dart';

void main() {
  late AppDatabase db;
  late DriftBillRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = DriftBillRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BillRepository', () {
    test('Simpan -> Baca Ulang -> Data identik', () async {
      final bill = Bill(
        id: 'bill-101',
        title: 'Makan Siang Bareng',
        createdAt: DateTime(2026, 10, 4, 13, 0),
        subtotal: 100000,
        taxAmount: 10000,
        serviceAmount: 5000,
        discountAmount: 15000,
        total: 100000,
        paidByParticipantId: 'p-1',
      );

      final participants = [
        const Participant(id: 'p-1', billId: 'bill-101', name: 'Andi', sortOrder: 0),
        const Participant(id: 'p-2', billId: 'bill-101', name: 'Budi', sortOrder: 1),
      ];

      final items = [
        BillItem.create(
          id: 'item-1',
          billId: 'bill-101',
          name: 'Nasi Liwet',
          unitPrice: 50000,
          quantity: 2,
          sortOrder: 0,
        ),
      ];

      final shares = [
        const ItemShare(id: 's-1', itemId: 'item-1', participantId: 'p-1', portion: 1),
        const ItemShare(id: 's-2', itemId: 'item-1', participantId: 'p-2', portion: 1),
      ];

      final completeBill = CompleteBill(
        bill: bill,
        participants: participants,
        items: items,
        shares: shares,
      );

      // Simpan ke database
      await repository.saveBill(completeBill);

      // Baca ulang
      final loaded = await repository.getCompleteBill('bill-101');
      expect(loaded, isNotNull);
      expect(loaded!.bill.id, equals(bill.id));
      expect(loaded.bill.title, equals(bill.title));
      expect(loaded.bill.subtotal, equals(bill.subtotal));
      expect(loaded.bill.taxAmount, equals(bill.taxAmount));
      expect(loaded.bill.serviceAmount, equals(bill.serviceAmount));
      expect(loaded.bill.discountAmount, equals(bill.discountAmount));
      expect(loaded.bill.total, equals(bill.total));
      expect(loaded.bill.paidByParticipantId, equals(bill.paidByParticipantId));

      expect(loaded.participants.length, equals(2));
      expect(loaded.participants[0].name, equals('Andi'));
      expect(loaded.participants[1].name, equals('Budi'));

      expect(loaded.items.length, equals(1));
      expect(loaded.items[0].name, equals('Nasi Liwet'));
      expect(loaded.items[0].totalPrice, equals(100000));

      expect(loaded.shares.length, equals(2));
    });

    test('Hapus bill menghapus anak-anaknya (cascade delete)', () async {
      final bill = Bill(
        id: 'bill-cascade',
        title: 'Bill Hapus',
        createdAt: DateTime.now(),
        subtotal: 50000,
        total: 50000,
      );

      final participants = [
        const Participant(id: 'p-c1', billId: 'bill-cascade', name: 'User C', sortOrder: 0),
      ];

      final items = [
        BillItem.create(
          id: 'item-c1',
          billId: 'bill-cascade',
          name: 'Item C',
          unitPrice: 50000,
          quantity: 1,
          sortOrder: 0,
        ),
      ];

      final shares = [
        const ItemShare(id: 's-c1', itemId: 'item-c1', participantId: 'p-c1', portion: 1),
      ];

      await repository.saveBill(
        CompleteBill(
          bill: bill,
          participants: participants,
          items: items,
          shares: shares,
        ),
      );

      // Pastikan ada sebelum dihapus
      expect(await repository.getCompleteBill('bill-cascade'), isNotNull);

      // Hapus bill
      await repository.deleteBill('bill-cascade');

      // Bill harus null
      expect(await repository.getCompleteBill('bill-cascade'), isNull);

      // Cek langsung ke tabel participants, items, shares harus kosong karena CASCADE
      final remainingParticipants = await (db.select(db.participants)
            ..where((t) => t.billId.equals('bill-cascade')))
          .get();
      expect(remainingParticipants, isEmpty);

      final remainingItems = await (db.select(db.billItems)
            ..where((t) => t.billId.equals('bill-cascade')))
          .get();
      expect(remainingItems, isEmpty);

      final remainingShares = await (db.select(db.itemShares)
            ..where((t) => t.itemId.equals('item-c1')))
          .get();
      expect(remainingShares, isEmpty);
    });

    test('Daftar riwayat diurutkan berdasarkan createdAt descending', () async {
      final bill1 = Bill(
        id: 'bill-old',
        title: 'Bill Lama',
        createdAt: DateTime(2026, 10, 1),
        subtotal: 10000,
        total: 10000,
      );

      final bill2 = Bill(
        id: 'bill-new',
        title: 'Bill Baru',
        createdAt: DateTime(2026, 10, 4),
        subtotal: 20000,
        total: 20000,
      );

      await repository.saveBill(
        CompleteBill(bill: bill1, participants: [], items: [], shares: []),
      );
      await repository.saveBill(
        CompleteBill(bill: bill2, participants: [], items: [], shares: []),
      );

      final all = await repository.getAllBills();
      expect(all.length, equals(2));
      expect(all.first.id, equals('bill-new'));
      expect(all.last.id, equals('bill-old'));
    });
  });
}

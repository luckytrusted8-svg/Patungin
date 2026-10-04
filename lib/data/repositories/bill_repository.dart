import 'package:drift/drift.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/complete_bill.dart';
import '../db/app_database.dart';
import '../mappers/bill_mapper.dart';

abstract class BillRepository {
  Future<void> saveBill(CompleteBill completeBill);
  Future<void> updateBill(CompleteBill completeBill);
  Future<CompleteBill?> getCompleteBill(String billId);
  Future<List<Bill>> getAllBills();
  Stream<List<Bill>> watchAllBills();
  Future<void> deleteBill(String billId);
}

class DriftBillRepository implements BillRepository {
  final AppDatabase db;

  DriftBillRepository(this.db);

  @override
  Future<void> saveBill(CompleteBill completeBill) async {
    await db.transaction(() async {
      // 1. Simpan bill
      await db.into(db.bills).insert(
            BillMapper.toCompanionBill(completeBill.bill),
            mode: InsertMode.insertOrReplace,
          );

      // 2. Simpan participants
      for (final p in completeBill.participants) {
        await db.into(db.participants).insert(
              BillMapper.toCompanionParticipant(p),
              mode: InsertMode.insertOrReplace,
            );
      }

      // 3. Simpan items
      for (final item in completeBill.items) {
        await db.into(db.billItems).insert(
              BillMapper.toCompanionBillItem(item),
              mode: InsertMode.insertOrReplace,
            );
      }

      // 4. Simpan shares
      for (final share in completeBill.shares) {
        await db.into(db.itemShares).insert(
              BillMapper.toCompanionItemShare(share),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  @override
  Future<void> updateBill(CompleteBill completeBill) async {
    await db.transaction(() async {
      final billId = completeBill.bill.id;

      // Update tabel bill
      await (db.update(db.bills)..where((tbl) => tbl.id.equals(billId)))
          .write(BillMapper.toCompanionBill(completeBill.bill));

      final oldItemIds = await (db.selectOnly(db.billItems)
            ..addColumns([db.billItems.id])
            ..where(db.billItems.billId.equals(billId)))
          .map((row) => row.read(db.billItems.id)!)
          .get();

      if (oldItemIds.isNotEmpty) {
        await (db.delete(db.itemShares)
              ..where((tbl) => tbl.itemId.isIn(oldItemIds)))
            .go();
      }
      await (db.delete(db.billItems)..where((tbl) => tbl.billId.equals(billId)))
          .go();
      await (db.delete(db.participants)
            ..where((tbl) => tbl.billId.equals(billId)))
          .go();

      // Masukkan kembali participants terbaru
      for (final p in completeBill.participants) {
        await db.into(db.participants).insert(
              BillMapper.toCompanionParticipant(p),
              mode: InsertMode.insertOrReplace,
            );
      }

      // Masukkan kembali items terbaru
      for (final item in completeBill.items) {
        await db.into(db.billItems).insert(
              BillMapper.toCompanionBillItem(item),
              mode: InsertMode.insertOrReplace,
            );
      }

      // Masukkan kembali shares terbaru
      for (final share in completeBill.shares) {
        await db.into(db.itemShares).insert(
              BillMapper.toCompanionItemShare(share),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  @override
  Future<CompleteBill?> getCompleteBill(String billId) async {
    final billEntry = await (db.select(db.bills)
          ..where((tbl) => tbl.id.equals(billId)))
        .getSingleOrNull();

    if (billEntry == null) return null;

    final participantEntries = await (db.select(db.participants)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]))
        .get();

    final itemEntries = await (db.select(db.billItems)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.sortOrder)]))
        .get();

    final itemIds = itemEntries.map((e) => e.id).toList();

    final shareEntries = itemIds.isEmpty
        ? <ItemShareEntry>[]
        : await (db.select(db.itemShares)
              ..where((tbl) => tbl.itemId.isIn(itemIds)))
            .get();

    return CompleteBill(
      bill: BillMapper.toDomainBill(billEntry),
      participants: participantEntries.map(BillMapper.toDomainParticipant).toList(),
      items: itemEntries.map(BillMapper.toDomainBillItem).toList(),
      shares: shareEntries.map(BillMapper.toDomainItemShare).toList(),
    );
  }

  @override
  Future<List<Bill>> getAllBills() async {
    final entries = await (db.select(db.bills)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .get();

    return entries.map(BillMapper.toDomainBill).toList();
  }

  @override
  Stream<List<Bill>> watchAllBills() {
    return (db.select(db.bills)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .watch()
        .map((entries) => entries.map(BillMapper.toDomainBill).toList());
  }

  @override
  Future<void> deleteBill(String billId) async {
    // Karena foreign key ON DELETE CASCADE aktif, menghapus dari Bills
    // otomatis menghapus participants, bill_items, dan item_shares.
    await (db.delete(db.bills)..where((tbl) => tbl.id.equals(billId))).go();
  }
}

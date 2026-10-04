import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/complete_bill.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftBillRepository(db);
});

final billsStreamProvider = StreamProvider<List<Bill>>((ref) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.watchAllBills();
});

final completeBillProvider =
    FutureProvider.family<CompleteBill?, String>((ref, billId) async {
  final repository = ref.watch(billRepositoryProvider);
  return repository.getCompleteBill(billId);
});

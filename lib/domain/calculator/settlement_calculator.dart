import '../models/person_result.dart';
import '../models/settlement.dart';

class SettlementCalculator {
  /// Menghitung penyelesaian utang-piutang untuk satu pembayar (MVP).
  ///
  /// Jika [paidByParticipantId] null atau kosong, mengembalikan list kosong.
  /// Peserta lain dengan [totalToPay] > 0 akan berutang kepada pembayar tersebut.
  static List<Settlement> calculateSinglePayer({
    required List<PersonResult> results,
    required String? paidByParticipantId,
  }) {
    if (paidByParticipantId == null || paidByParticipantId.isEmpty) {
      return const [];
    }

    final payer = results
        .where((r) => r.participantId == paidByParticipantId)
        .firstOrNull;

    if (payer == null) {
      return const [];
    }

    final settlements = <Settlement>[];
    for (final person in results) {
      if (person.participantId == paidByParticipantId) continue;
      if (person.totalToPay <= 0) continue;

      settlements.add(
        Settlement(
          fromParticipantId: person.participantId,
          fromName: person.name,
          toParticipantId: payer.participantId,
          toName: payer.name,
          amount: person.totalToPay,
        ),
      );
    }

    return settlements;
  }

  /// Menghitung penyelesaian utang-piutang untuk banyak pembayar (Tahap 2)
  /// menggunakan algoritma greedy pembatalan utang (min-cash-flow).
  ///
  /// [paymentsMap]: map dari participantId -> total uang yang dia talangi/bayar.
  static List<Settlement> calculateMultiPayer({
    required List<PersonResult> results,
    required Map<String, int> paymentsMap,
  }) {
    final names = {for (final r in results) r.participantId: r.name};

    // Net balance: positive = lebih bayar (kreditur), negative = kurang bayar (debitur)
    final balances = <String, int>{};
    for (final r in results) {
      final paid = paymentsMap[r.participantId] ?? 0;
      balances[r.participantId] = paid - r.totalToPay;
    }

    final settlements = <Settlement>[];

    while (true) {
      String? maxDebtor;
      int maxDebit = 0; // nilai absolut terbesar dari saldo negatif

      String? maxCreditor;
      int maxCredit = 0; // saldo positif terbesar

      for (final entry in balances.entries) {
        if (entry.value < 0 && -entry.value > maxDebit) {
          maxDebit = -entry.value;
          maxDebtor = entry.key;
        } else if (entry.value > 0 && entry.value > maxCredit) {
          maxCredit = entry.value;
          maxCreditor = entry.key;
        }
      }

      // Jika tidak ada utang lagi atau saldo sudah 0
      if (maxDebtor == null || maxCreditor == null || maxDebit == 0 || maxCredit == 0) {
        break;
      }

      // Nominal transfer adalah nilai minimum antara utang debitur & hak kreditur
      final transfer = maxDebit < maxCredit ? maxDebit : maxCredit;

      balances[maxDebtor] = balances[maxDebtor]! + transfer;
      balances[maxCreditor] = balances[maxCreditor]! - transfer;

      settlements.add(
        Settlement(
          fromParticipantId: maxDebtor,
          fromName: names[maxDebtor] ?? maxDebtor,
          toParticipantId: maxCreditor,
          toName: names[maxCreditor] ?? maxCreditor,
          amount: transfer,
        ),
      );
    }

    return settlements;
  }
}

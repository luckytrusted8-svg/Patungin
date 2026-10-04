import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/item_share.dart';
import '../models/participant.dart';
import '../models/person_result.dart';
import 'allocation.dart';

class SplitValidation {
  final List<String> unassignedItemIds;
  final bool isSubtotalMismatch;
  final int subtotalDifference;
  final bool isTotalMismatch;
  final int totalDifference;

  const SplitValidation({
    required this.unassignedItemIds,
    required this.isSubtotalMismatch,
    required this.subtotalDifference,
    required this.isTotalMismatch,
    required this.totalDifference,
  });

  bool get hasUnassignedItems => unassignedItemIds.isNotEmpty;
  bool get hasWarnings =>
      hasUnassignedItems || isSubtotalMismatch || isTotalMismatch;
}

class SplitCalculator {
  /// Mengkonversi persentase ke nominal Rupiah bulat (pembulatan terdekat).
  /// [percentBasisPoints]: 1% = 100 bp (contoh 10% = 1000 bp, 7.5% = 750 bp).
  static int percentToAmount(int base, int percentBasisPoints) {
    if (base <= 0 || percentBasisPoints <= 0) return 0;
    return (base * percentBasisPoints + 5000) ~/ 10000;
  }

  /// Validasi non-blocking untuk UI (peringatan bagi pengguna).
  static SplitValidation validate({
    required Bill bill,
    required List<BillItem> items,
    required List<ItemShare> shares,
  }) {
    final assignedItemIds = shares.map((s) => s.itemId).toSet();
    final unassigned = items
        .where((item) => !assignedItemIds.contains(item.id))
        .map((item) => item.id)
        .toList();

    final itemsSum = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final subtotalDiff = bill.subtotal - itemsSum;

    final calculatedTotal =
        bill.subtotal + bill.taxAmount + bill.serviceAmount - bill.discountAmount;
    final totalDiff = bill.total - calculatedTotal;

    return SplitValidation(
      unassignedItemIds: unassigned,
      isSubtotalMismatch: subtotalDiff != 0,
      subtotalDifference: subtotalDiff,
      isTotalMismatch: totalDiff != 0,
      totalDifference: totalDiff,
    );
  }

  /// Menghitung pembagian tagihan per orang secara deterministik dan pure.
  ///
  /// Menjamin invarian: sum(totalToPay) == subtotalTerhitung + tax + service - discount.
  static List<PersonResult> calculate({
    required Bill bill,
    required List<Participant> participants,
    required List<BillItem> items,
    required List<ItemShare> shares,
  }) {
    if (participants.isEmpty) return const [];

    // Urutkan peserta berdasarkan sortOrder untuk tie-break deterministik
    final sortedParticipants = List<Participant>.from(participants)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final participantMap = {for (final p in sortedParticipants) p.id: p};
    final participantIndexMap = {
      for (int i = 0; i < sortedParticipants.length; i++)
        sortedParticipants[i].id: i
    };

    final itemsTotalPerPerson =
        List<int>.filled(sortedParticipants.length, 0);
    final breakdownPerPerson =
        List<List<PersonItemBreakdown>>.generate(
      sortedParticipants.length,
      (_) => <PersonItemBreakdown>[],
    );

    // 1. Alokasi tiap item ke pemegang share dengan Largest Remainder
    for (final item in items) {
      final itemShares =
          shares.where((s) => s.itemId == item.id && participantMap.containsKey(s.participantId)).toList();

      if (itemShares.isEmpty) {
        continue;
      }

      // Siapkan bobot porsi untuk item ini
      final weights = itemShares.map((s) {
        final p = participantMap[s.participantId]!;
        return AllocationWeight(
          weight: s.portion,
          sortOrder: p.sortOrder,
        );
      }).toList();

      final allocatedAmounts = Allocation.allocate(
        totalAmount: item.totalPrice,
        weights: weights,
      );

      final totalItemPortions =
          itemShares.fold<int>(0, (sum, s) => sum + s.portion);

      for (int i = 0; i < itemShares.length; i++) {
        final share = itemShares[i];
        final pIndex = participantIndexMap[share.participantId]!;
        final allocatedPrice = allocatedAmounts[i];

        itemsTotalPerPerson[pIndex] += allocatedPrice;
        breakdownPerPerson[pIndex].add(
          PersonItemBreakdown(
            itemId: item.id,
            itemName: item.name,
            portion: share.portion,
            totalPortions: totalItemPortions,
            allocatedPrice: allocatedPrice,
          ),
        );
      }
    }

    final totalAllocatedItems =
        itemsTotalPerPerson.fold<int>(0, (sum, val) => sum + val);

    // 2 & 3. Alokasi Pajak, Service, dan Diskon secara proporsional thd itemsTotal
    final participantWeights = List<AllocationWeight>.generate(
      sortedParticipants.length,
      (i) => AllocationWeight(
        weight: itemsTotalPerPerson[i],
        sortOrder: sortedParticipants[i].sortOrder,
      ),
    );

    final taxShares = Allocation.allocate(
      totalAmount: bill.taxAmount,
      weights: participantWeights,
    );

    final serviceShares = Allocation.allocate(
      totalAmount: bill.serviceAmount,
      weights: participantWeights,
    );

    final discountShares = Allocation.allocate(
      totalAmount: bill.discountAmount,
      weights: participantWeights,
    );

    // 4. Hitung totalToPay per orang
    final results = <PersonResult>[];
    int sumTotalToPay = 0;

    for (int i = 0; i < sortedParticipants.length; i++) {
      final p = sortedParticipants[i];
      final itemTotal = itemsTotalPerPerson[i];
      final tax = taxShares[i];
      final service = serviceShares[i];
      final discount = discountShares[i];

      final toPay = itemTotal + tax + service - discount;
      sumTotalToPay += toPay;

      results.add(
        PersonResult(
          participantId: p.id,
          name: p.name,
          itemsTotal: itemTotal,
          taxShare: tax,
          serviceShare: service,
          discountShare: discount,
          totalToPay: toPay,
          itemDetails: List.unmodifiable(breakdownPerPerson[i]),
        ),
      );
    }

    // 5. Invarian wajib: sum(totalToPay) == totalAllocatedItems + tax + service - discount
    final expectedTotal = totalAllocatedItems +
        bill.taxAmount +
        bill.serviceAmount -
        bill.discountAmount;

    if (sumTotalToPay != expectedTotal) {
      throw StateError(
        'Invarian gagal: sum(totalToPay) = $sumTotalToPay tidak sama dengan yang diharapkan = $expectedTotal (Alokasi: $totalAllocatedItems, Pajak: ${bill.taxAmount}, Service: ${bill.serviceAmount}, Diskon: ${bill.discountAmount})',
      );
    }

    return results;
  }
}

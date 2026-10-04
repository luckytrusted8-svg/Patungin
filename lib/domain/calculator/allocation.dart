class AllocationWeight {
  final int weight;
  final int sortOrder;

  const AllocationWeight({
    required this.weight,
    required this.sortOrder,
  });
}

class Allocation {
  /// Membagi [totalAmount] secara proporsional berdasarkan [weights]
  /// menggunakan metode Largest Remainder (Hamilton-Hare).
  ///
  /// Menjamin bahwa: sum(hasil) == totalAmount.
  /// Bila terjadi sisa pecahan sama (tie-break), urutan diprioritaskan
  /// pada peserta dengan [sortOrder] lebih kecil (yang lebih awal).
  static List<int> allocate({
    required int totalAmount,
    required List<AllocationWeight> weights,
  }) {
    if (weights.isEmpty) return const [];
    if (totalAmount == 0) return List<int>.filled(weights.length, 0);

    final totalWeight = weights.fold<int>(0, (sum, w) => sum + w.weight);

    // Kasus khusus: jika total bobot 0, bagi rata ke seluruh partisipan
    if (totalWeight <= 0) {
      final base = totalAmount ~/ weights.length;
      final remainder = totalAmount - (base * weights.length);

      // Urutkan index berdasarkan sortOrder untuk pembagian remainder rata
      final indices = List<int>.generate(weights.length, (i) => i);
      indices.sort((a, b) => weights[a].sortOrder.compareTo(weights[b].sortOrder));

      final result = List<int>.filled(weights.length, base);
      for (int i = 0; i < remainder; i++) {
        result[indices[i]] += 1;
      }
      return result;
    }

    final floors = List<int>.filled(weights.length, 0);
    final remainders = List<int>.filled(weights.length, 0);
    int sumFloors = 0;

    for (int i = 0; i < weights.length; i++) {
      final w = weights[i].weight;
      floors[i] = (totalAmount * w) ~/ totalWeight;
      remainders[i] = (totalAmount * w) % totalWeight;
      sumFloors += floors[i];
    }

    final int leftover = totalAmount - sumFloors;

    // Buat daftar indeks dan urutkan:
    // 1. Pecahan terbesar (remainders menurun)
    // 2. Jika sama, sortOrder menaik (lebih kecil lebih awal)
    final indices = List<int>.generate(weights.length, (i) => i);
    indices.sort((a, b) {
      final remCmp = remainders[b].compareTo(remainders[a]);
      if (remCmp != 0) return remCmp;
      return weights[a].sortOrder.compareTo(weights[b].sortOrder);
    });

    final result = List<int>.from(floors);
    for (int i = 0; i < leftover; i++) {
      result[indices[i]] += 1;
    }

    assert(
      result.fold<int>(0, (sum, val) => sum + val) == totalAmount,
      'Invariant violated: sum of allocation must equal totalAmount',
    );

    return result;
  }
}

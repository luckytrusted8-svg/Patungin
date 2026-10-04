import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/domain/calculator/allocation.dart';

void main() {
  group('Allocation (Largest Remainder Method)', () {
    test('100.000 dibagi 3 bobot sama -> [33334, 33333, 33333]', () {
      final weights = [
        const AllocationWeight(weight: 1, sortOrder: 0),
        const AllocationWeight(weight: 1, sortOrder: 1),
        const AllocationWeight(weight: 1, sortOrder: 2),
      ];

      final result = Allocation.allocate(
        totalAmount: 100000,
        weights: weights,
      );

      expect(result, equals([33334, 33333, 33333]));
      expect(result.reduce((a, b) => a + b), equals(100000));
    });

    test('Bobot 2:1 pada 100.000 -> [66667, 33333]', () {
      final weights = [
        const AllocationWeight(weight: 2, sortOrder: 0),
        const AllocationWeight(weight: 1, sortOrder: 1),
      ];

      final result = Allocation.allocate(
        totalAmount: 100000,
        weights: weights,
      );

      expect(result, equals([66667, 33333]));
      expect(result.reduce((a, b) => a + b), equals(100000));
    });

    test('Total amount 0 menghasilkan semua 0', () {
      final weights = [
        const AllocationWeight(weight: 5, sortOrder: 0),
        const AllocationWeight(weight: 10, sortOrder: 1),
      ];

      final result = Allocation.allocate(
        totalAmount: 0,
        weights: weights,
      );

      expect(result, equals([0, 0]));
    });

    test('Total bobot 0 membagi rata ke seluruh peserta', () {
      final weights = [
        const AllocationWeight(weight: 0, sortOrder: 0),
        const AllocationWeight(weight: 0, sortOrder: 1),
        const AllocationWeight(weight: 0, sortOrder: 2),
      ];

      final result = Allocation.allocate(
        totalAmount: 100,
        weights: weights,
      );

      expect(result, equals([34, 33, 33]));
      expect(result.reduce((a, b) => a + b), equals(100));
    });

    test('Daftar bobot kosong menghasilkan list kosong', () {
      final result = Allocation.allocate(
        totalAmount: 50000,
        weights: [],
      );

      expect(result, isEmpty);
    });

    test('Properti: 1.000 kombinasi acak selalu sum == total', () {
      final random = Random(42);

      for (int i = 0; i < 1000; i++) {
        final totalAmount = random.nextInt(10000000); // 0 sd 10.000.000
        final participantCount = random.nextInt(10) + 1; // 1 sd 10 orang

        final weights = List.generate(
          participantCount,
          (idx) => AllocationWeight(
            weight: random.nextInt(100), // bisa 0 juga
            sortOrder: idx,
          ),
        );

        final result = Allocation.allocate(
          totalAmount: totalAmount,
          weights: weights,
        );

        final sum = result.fold<int>(0, (a, b) => a + b);
        expect(
          sum,
          equals(totalAmount),
          reason: 'Iterasi $i gagal: sum=$sum != total=$totalAmount untuk weights=${weights.map((w) => w.weight).toList()}',
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/domain/calculator/settlement_calculator.dart';
import 'package:patungin/domain/models/person_result.dart';

void main() {
  group('SettlementCalculator', () {
    test('Single payer: peserta lain berutang ke pembayar', () {
      final results = [
        const PersonResult(
          participantId: 'p-1',
          name: 'Andi',
          itemsTotal: 30000,
          taxShare: 3000,
          serviceShare: 1500,
          discountShare: 0,
          totalToPay: 34500,
        ),
        const PersonResult(
          participantId: 'p-2',
          name: 'Budi',
          itemsTotal: 50000,
          taxShare: 5000,
          serviceShare: 2500,
          discountShare: 0,
          totalToPay: 57500,
        ),
        const PersonResult(
          participantId: 'p-3',
          name: 'Citra',
          itemsTotal: 70000,
          taxShare: 7000,
          serviceShare: 3500,
          discountShare: 0,
          totalToPay: 80500,
        ),
      ];

      final settlements = SettlementCalculator.calculateSinglePayer(
        results: results,
        paidByParticipantId: 'p-1',
      );

      expect(settlements.length, equals(2));

      expect(settlements[0].fromParticipantId, equals('p-2'));
      expect(settlements[0].fromName, equals('Budi'));
      expect(settlements[0].toParticipantId, equals('p-1'));
      expect(settlements[0].toName, equals('Andi'));
      expect(settlements[0].amount, equals(57500));

      expect(settlements[1].fromParticipantId, equals('p-3'));
      expect(settlements[1].fromName, equals('Citra'));
      expect(settlements[1].toParticipantId, equals('p-1'));
      expect(settlements[1].toName, equals('Andi'));
      expect(settlements[1].amount, equals(80500));
    });

    test('Tanpa pembayar: settlements kosong', () {
      final results = [
        const PersonResult(
          participantId: 'p-1',
          name: 'Andi',
          itemsTotal: 30000,
          taxShare: 0,
          serviceShare: 0,
          discountShare: 0,
          totalToPay: 30000,
        ),
      ];

      final settlements = SettlementCalculator.calculateSinglePayer(
        results: results,
        paidByParticipantId: null,
      );

      expect(settlements, isEmpty);
    });

    test('Multi-payer greedy: penyelesaian minimum transfer', () {
      final results = [
        const PersonResult(
          participantId: 'p-1',
          name: 'A',
          itemsTotal: 40000,
          taxShare: 0,
          serviceShare: 0,
          discountShare: 0,
          totalToPay: 40000,
        ),
        const PersonResult(
          participantId: 'p-2',
          name: 'B',
          itemsTotal: 25000,
          taxShare: 0,
          serviceShare: 0,
          discountShare: 0,
          totalToPay: 25000,
        ),
        const PersonResult(
          participantId: 'p-3',
          name: 'C',
          itemsTotal: 35000,
          taxShare: 0,
          serviceShare: 0,
          discountShare: 0,
          totalToPay: 35000,
        ),
      ];

      // A bayar 100.000, B bayar 0, C bayar 0
      final settlements = SettlementCalculator.calculateMultiPayer(
        results: results,
        paymentsMap: {'p-1': 100000, 'p-2': 0, 'p-3': 0},
      );

      // Total yang dibayarkan ke A harus 60.000
      final totalToA = settlements
          .where((s) => s.toParticipantId == 'p-1')
          .fold<int>(0, (sum, s) => sum + s.amount);
      expect(totalToA, equals(60000));
    });
  });
}

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/domain/calculator/split_calculator.dart';
import 'package:patungin/domain/calculator/settlement_calculator.dart';
import 'package:patungin/domain/models/bill.dart';
import 'package:patungin/domain/models/bill_item.dart';
import 'package:patungin/domain/models/item_share.dart';
import 'package:patungin/domain/models/participant.dart';

void main() {
  group('SplitCalculator', () {
    test('Kasus Utama: Makan Bertiga (Andi, Budi, Citra)', () {
      final bill = Bill(
        id: 'bill-1',
        title: 'Makan Bertiga',
        createdAt: DateTime(2026, 10, 4),
        subtotal: 150000,
        taxAmount: 15000,
        serviceAmount: 7500,
        discountAmount: 0,
        total: 172500,
        paidByParticipantId: 'p-andi',
      );

      final participants = [
        const Participant(id: 'p-andi', billId: 'bill-1', name: 'Andi', sortOrder: 0),
        const Participant(id: 'p-budi', billId: 'bill-1', name: 'Budi', sortOrder: 1),
        const Participant(id: 'p-citra', billId: 'bill-1', name: 'Citra', sortOrder: 2),
      ];

      final items = [
        BillItem.create(
          id: 'item-nasgor',
          billId: 'bill-1',
          name: 'Nasi Goreng',
          unitPrice: 30000,
          quantity: 2,
          sortOrder: 0,
        ),
        BillItem.create(
          id: 'item-sate',
          billId: 'bill-1',
          name: 'Sate Ayam',
          unitPrice: 50000,
          quantity: 1,
          sortOrder: 1,
        ),
        BillItem.create(
          id: 'item-esteh',
          billId: 'bill-1',
          name: 'Es Teh',
          unitPrice: 20000,
          quantity: 2,
          sortOrder: 2,
        ),
      ];

      final shares = [
        const ItemShare(id: 's-1', itemId: 'item-nasgor', participantId: 'p-andi', portion: 1),
        const ItemShare(id: 's-2', itemId: 'item-nasgor', participantId: 'p-budi', portion: 1),
        const ItemShare(id: 's-3', itemId: 'item-sate', participantId: 'p-citra', portion: 1),
        const ItemShare(id: 's-4', itemId: 'item-esteh', participantId: 'p-budi', portion: 1),
        const ItemShare(id: 's-5', itemId: 'item-esteh', participantId: 'p-citra', portion: 1),
      ];

      final results = SplitCalculator.calculate(
        bill: bill,
        participants: participants,
        items: items,
        shares: shares,
      );

      expect(results.length, equals(3));

      // Andi: itemsTotal: 30.000, tax: 3.000, service: 1.500, total: 34.500
      final andi = results.firstWhere((r) => r.participantId == 'p-andi');
      expect(andi.itemsTotal, equals(30000));
      expect(andi.taxShare, equals(3000));
      expect(andi.serviceShare, equals(1500));
      expect(andi.discountShare, equals(0));
      expect(andi.totalToPay, equals(34500));

      // Budi: itemsTotal: 50.000, tax: 5.000, service: 2.500, total: 57.500
      final budi = results.firstWhere((r) => r.participantId == 'p-budi');
      expect(budi.itemsTotal, equals(50000));
      expect(budi.taxShare, equals(5000));
      expect(budi.serviceShare, equals(2500));
      expect(budi.discountShare, equals(0));
      expect(budi.totalToPay, equals(57500));

      // Citra: itemsTotal: 70.000, tax: 7.000, service: 3.500, total: 80.500
      final citra = results.firstWhere((r) => r.participantId == 'p-citra');
      expect(citra.itemsTotal, equals(70000));
      expect(citra.taxShare, equals(7000));
      expect(citra.serviceShare, equals(3500));
      expect(citra.discountShare, equals(0));
      expect(citra.totalToPay, equals(80500));

      // Total keseluruhan = 172.500
      final totalPaidSum = results.fold<int>(0, (sum, r) => sum + r.totalToPay);
      expect(totalPaidSum, equals(172500));

      // Settlement: Budi -> Andi 57.500; Citra -> Andi 80.500
      final settlements = SettlementCalculator.calculateSinglePayer(
        results: results,
        paidByParticipantId: bill.paidByParticipantId,
      );

      expect(settlements.length, equals(2));
      final budiSettlement = settlements.firstWhere((s) => s.fromParticipantId == 'p-budi');
      expect(budiSettlement.toParticipantId, equals('p-andi'));
      expect(budiSettlement.amount, equals(57500));

      final citraSettlement = settlements.firstWhere((s) => s.fromParticipantId == 'p-citra');
      expect(citraSettlement.toParticipantId, equals('p-andi'));
      expect(citraSettlement.amount, equals(80500));
    });

    test('Diskon proporsional mengurangi total tiap orang dengan benar', () {
      final bill = Bill(
        id: 'bill-disc',
        title: 'Makan Diskon',
        createdAt: DateTime(2026, 10, 4),
        subtotal: 100000,
        taxAmount: 10000,
        serviceAmount: 0,
        discountAmount: 20000, // Diskon 20.000
        total: 90000,
      );

      final participants = [
        const Participant(id: 'p-1', billId: 'bill-disc', name: 'User 1', sortOrder: 0),
        const Participant(id: 'p-2', billId: 'bill-disc', name: 'User 2', sortOrder: 1),
      ];

      final items = [
        BillItem.create(
          id: 'item-1',
          billId: 'bill-disc',
          name: 'Steak',
          unitPrice: 80000,
          quantity: 1,
          sortOrder: 0,
        ),
        BillItem.create(
          id: 'item-2',
          billId: 'bill-disc',
          name: 'Jus',
          unitPrice: 20000,
          quantity: 1,
          sortOrder: 1,
        ),
      ];

      final shares = [
        const ItemShare(id: 's-1', itemId: 'item-1', participantId: 'p-1', portion: 1),
        const ItemShare(id: 's-2', itemId: 'item-2', participantId: 'p-2', portion: 1),
      ];

      final results = SplitCalculator.calculate(
        bill: bill,
        participants: participants,
        items: items,
        shares: shares,
      );

      final p1 = results.firstWhere((r) => r.participantId == 'p-1');
      final p2 = results.firstWhere((r) => r.participantId == 'p-2');

      // P1: items 80.000 -> tax 8.000, discount 16.000 -> total 72.000
      expect(p1.itemsTotal, equals(80000));
      expect(p1.taxShare, equals(8000));
      expect(p1.discountShare, equals(16000));
      expect(p1.totalToPay, equals(72000));

      // P2: items 20.000 -> tax 2.000, discount 4.000 -> total 18.000
      expect(p2.itemsTotal, equals(20000));
      expect(p2.taxShare, equals(2000));
      expect(p2.discountShare, equals(4000));
      expect(p2.totalToPay, equals(18000));

      expect(p1.totalToPay + p2.totalToPay, equals(90000));
    });

    test('Satu orang memegang semua item -> semua pajak & service ke dia', () {
      final bill = Bill(
        id: 'bill-solo',
        title: 'Traktir',
        createdAt: DateTime(2026, 10, 4),
        subtotal: 100000,
        taxAmount: 11000,
        serviceAmount: 5000,
        discountAmount: 0,
        total: 116000,
      );

      final participants = [
        const Participant(id: 'p-solo', billId: 'bill-solo', name: 'Solo', sortOrder: 0),
        const Participant(id: 'p-silent', billId: 'bill-solo', name: 'Numpang', sortOrder: 1),
      ];

      final items = [
        BillItem.create(
          id: 'item-1',
          billId: 'bill-solo',
          name: 'Pesta',
          unitPrice: 100000,
          quantity: 1,
          sortOrder: 0,
        ),
      ];

      final shares = [
        const ItemShare(id: 's-1', itemId: 'item-1', participantId: 'p-solo', portion: 1),
      ];

      final results = SplitCalculator.calculate(
        bill: bill,
        participants: participants,
        items: items,
        shares: shares,
      );

      final solo = results.firstWhere((r) => r.participantId == 'p-solo');
      final silent = results.firstWhere((r) => r.participantId == 'p-silent');

      expect(solo.itemsTotal, equals(100000));
      expect(solo.taxShare, equals(11000));
      expect(solo.serviceShare, equals(5000));
      expect(solo.totalToPay, equals(116000));

      expect(silent.itemsTotal, equals(0));
      expect(silent.taxShare, equals(0));
      expect(silent.serviceShare, equals(0));
      expect(silent.totalToPay, equals(0));
    });

    test('Semua itemsTotal = 0 -> pajak dibagi rata', () {
      final bill = Bill(
        id: 'bill-zero',
        title: 'Nol Item',
        createdAt: DateTime(2026, 10, 4),
        subtotal: 0,
        taxAmount: 10000,
        serviceAmount: 0,
        discountAmount: 0,
        total: 10000,
      );

      final participants = [
        const Participant(id: 'p-1', billId: 'bill-zero', name: 'A', sortOrder: 0),
        const Participant(id: 'p-2', billId: 'bill-zero', name: 'B', sortOrder: 1),
        const Participant(id: 'p-3', billId: 'bill-zero', name: 'C', sortOrder: 2),
      ];

      final results = SplitCalculator.calculate(
        bill: bill,
        participants: participants,
        items: [],
        shares: [],
      );

      expect(results.length, equals(3));
      // 10.000 dibagi 3 rata: [3334, 3333, 3333]
      expect(results[0].totalToPay, equals(3334));
      expect(results[1].totalToPay, equals(3333));
      expect(results[2].totalToPay, equals(3333));
      expect(results.fold<int>(0, (s, r) => s + r.totalToPay), equals(10000));
    });

    test('Helper percentToAmount membulatkan ke rupiah terdekat', () {
      // 10% dari 150.000 = 15.000
      expect(SplitCalculator.percentToAmount(150000, 1000), equals(15000));
      // 11% dari 100.000 = 11.000
      expect(SplitCalculator.percentToAmount(100000, 1100), equals(11000));
      // 7.5% dari 100.000 = 7.500
      expect(SplitCalculator.percentToAmount(100000, 750), equals(7500));
      // 10% dari 333 = 33.3 -> 33
      expect(SplitCalculator.percentToAmount(333, 1000), equals(33));
      // 10% dari 335 = 33.5 -> 34 (pembulatan ke atas)
      expect(SplitCalculator.percentToAmount(335, 1000), equals(34));
    });

    test('Invarian terjaga pada data acak', () {
      final random = Random(12345);

      for (int i = 0; i < 200; i++) {
        final pCount = random.nextInt(6) + 2; // 2-7 participants
        final participants = List.generate(
          pCount,
          (idx) => Participant(
            id: 'p-$idx',
            billId: 'b-rand',
            name: 'P-$idx',
            sortOrder: idx,
          ),
        );

        final itemCount = random.nextInt(5) + 1; // 1-5 items
        final items = <BillItem>[];
        final shares = <ItemShare>[];

        for (int j = 0; j < itemCount; j++) {
          final unitPrice = random.nextInt(100000) + 1000;
          final qty = random.nextInt(3) + 1;
          final item = BillItem.create(
            id: 'item-$j',
            billId: 'b-rand',
            name: 'Item $j',
            unitPrice: unitPrice,
            quantity: qty,
            sortOrder: j,
          );
          items.add(item);

          // assign to at least 1 participant
          final assignedCount = random.nextInt(pCount) + 1;
          for (int k = 0; k < assignedCount; k++) {
            shares.add(
              ItemShare(
                id: 's-$j-$k',
                itemId: item.id,
                participantId: participants[k].id,
                portion: random.nextInt(3) + 1,
              ),
            );
          }
        }

        final subtotal = items.fold<int>(0, (s, it) => s + it.totalPrice);
        final tax = random.nextInt(20000);
        final service = random.nextInt(10000);
        final discount = random.nextInt(min(subtotal, 15000));
        final total = subtotal + tax + service - discount;

        final bill = Bill(
          id: 'b-rand',
          title: 'Random Bill',
          createdAt: DateTime.now(),
          subtotal: subtotal,
          taxAmount: tax,
          serviceAmount: service,
          discountAmount: discount,
          total: total,
        );

        final results = SplitCalculator.calculate(
          bill: bill,
          participants: participants,
          items: items,
          shares: shares,
        );

        final sumToPay = results.fold<int>(0, (s, r) => s + r.totalToPay);
        expect(sumToPay, equals(total));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/domain/parser/parsed_receipt.dart';
import 'package:patungin/domain/parser/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    test('Contoh 1: Satu baris per item dengan format "{nama} {harga}"', () {
      final lines = [
        const OcrLine(text: 'WARUNG MAKAN SEDAP'),
        const OcrLine(text: 'JL. MERDEKA NO. 10'),
        const OcrLine(text: 'KASIR: ADI  04/10/2026 12:30'),
        const OcrLine(text: '----------------------------'),
        const OcrLine(text: 'Ayam Goreng 25.000'),
        const OcrLine(text: 'Nasi Putih 5.000'),
        const OcrLine(text: 'Es Jeruk 8.000'),
        const OcrLine(text: '----------------------------'),
        const OcrLine(text: 'SUBTOTAL 38.000'),
        const OcrLine(text: 'PPN 10% 3.800'),
        const OcrLine(text: 'TOTAL 41.800'),
        const OcrLine(text: 'TUNAI 50.000'),
        const OcrLine(text: 'KEMBALI 8.200'),
        const OcrLine(text: 'TERIMA KASIH'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(3));
      expect(receipt.items[0].name, equals('Ayam Goreng'));
      expect(receipt.items[0].totalPrice, equals(25000));
      expect(receipt.items[1].name, equals('Nasi Putih'));
      expect(receipt.items[1].totalPrice, equals(5000));
      expect(receipt.items[2].name, equals('Es Jeruk'));
      expect(receipt.items[2].totalPrice, equals(8000));

      expect(receipt.subtotal, equals(38000));
      expect(receipt.tax, equals(3800));
      expect(receipt.total, equals(41800));
      expect(receipt.isSubtotalConsistent, isTrue);
    });

    test('Contoh 2: Format "{qty}x {nama} {harga}"', () {
      final lines = [
        const OcrLine(text: 'CAFE KOPI SENJA'),
        const OcrLine(text: '2x Kopi Susu 40.000'),
        const OcrLine(text: '1x Roti Bakar 18.000'),
        const OcrLine(text: 'SUB TOTAL 58.000'),
        const OcrLine(text: 'SERVICE CHARGE 2.900'),
        const OcrLine(text: 'GRAND TOTAL 60.900'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(2));
      expect(receipt.items[0].name, equals('Kopi Susu'));
      expect(receipt.items[0].quantity, equals(2));
      expect(receipt.items[0].unitPrice, equals(20000));
      expect(receipt.items[0].totalPrice, equals(40000));

      expect(receipt.items[1].name, equals('Roti Bakar'));
      expect(receipt.items[1].quantity, equals(1));
      expect(receipt.items[1].totalPrice, equals(18000));

      expect(receipt.subtotal, equals(58000));
      expect(receipt.service, equals(2900));
      expect(receipt.total, equals(60900));
    });

    test('Contoh 3: Format "{nama} {qty} x {unit} {total}"', () {
      final lines = [
        const OcrLine(text: 'RESTO NUSANTARA'),
        const OcrLine(text: 'Nasi Goreng Spesial 2 x 30.000 60.000'),
        const OcrLine(text: 'Sate Ayam Madura 1 x 45.000 45.000'),
        const OcrLine(text: 'SUBTOTAL 105.000'),
        const OcrLine(text: 'DISKON PROMO 15.000'),
        const OcrLine(text: 'PB1 10% 9.000'),
        const OcrLine(text: 'TOTAL 99.000'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(2));
      expect(receipt.items[0].name, equals('Nasi Goreng Spesial'));
      expect(receipt.items[0].quantity, equals(2));
      expect(receipt.items[0].unitPrice, equals(30000));
      expect(receipt.items[0].totalPrice, equals(60000));

      expect(receipt.items[1].name, equals('Sate Ayam Madura'));
      expect(receipt.items[1].totalPrice, equals(45000));

      expect(receipt.subtotal, equals(105000));
      expect(receipt.discount, equals(15000));
      expect(receipt.tax, equals(9000));
      expect(receipt.total, equals(99000));
    });

    test('Contoh 4: Pola dua baris (nama di baris 1, harga di baris 2)', () {
      final lines = [
        const OcrLine(text: 'Steak Tenderloin Impor'),
        const OcrLine(text: '120.000'),
        const OcrLine(text: 'Mocktail Blue Ocean'),
        const OcrLine(text: '35.000'),
        const OcrLine(text: 'SUBTOTAL 155.000'),
        const OcrLine(text: 'TOTAL 155.000'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(2));
      expect(receipt.items[0].name, equals('Steak Tenderloin Impor'));
      expect(receipt.items[0].totalPrice, equals(120000));
      expect(receipt.items[1].name, equals('Mocktail Blue Ocean'));
      expect(receipt.items[1].totalPrice, equals(35000));
      expect(receipt.subtotal, equals(155000));
      expect(receipt.total, equals(155000));
    });

    test('Contoh 5: Struk acak dengan baris sampah kasir/meja/qris', () {
      final lines = [
        const OcrLine(text: 'KEDAI KOPI KITA'),
        const OcrLine(text: 'MEJA 14'),
        const OcrLine(text: 'NO. STRUK: 981248'),
        const OcrLine(text: 'Espresso Single 18.000'),
        const OcrLine(text: 'Croissant Coklat 22.000'),
        const OcrLine(text: 'SUBTOTAL 40.000'),
        const OcrLine(text: 'TOTAL 40.000'),
        const OcrLine(text: 'QRIS BCA BERHASIL'),
        const OcrLine(text: 'SELAMAT MENIKMATI'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(2));
      expect(receipt.items[0].name, equals('Espresso Single'));
      expect(receipt.items[0].totalPrice, equals(18000));
      expect(receipt.items[1].name, equals('Croissant Coklat'));
      expect(receipt.items[1].totalPrice, equals(22000));
      expect(receipt.total, equals(40000));
    });

    test('Contoh 6: Format cafe modern dengan notasi k dan OcrLine rawLines tersimpan', () {
      final lines = [
        const OcrLine(text: 'KOPI KENANGAN'),
        const OcrLine(text: 'Latte 35k'),
        const OcrLine(text: 'Toast Coklat 25K'),
        const OcrLine(text: 'TOTAL 60.000'),
      ];

      final receipt = ReceiptParser.parse(lines);

      expect(receipt.items.length, equals(2));
      expect(receipt.items[0].name, equals('Latte'));
      expect(receipt.items[0].totalPrice, equals(35000));
      expect(receipt.items[1].name, equals('Toast Coklat'));
      expect(receipt.items[1].totalPrice, equals(25000));
      expect(receipt.rawLines.length, equals(4));
    });

    test('Input kosong tidak melempar error', () {
      final emptyReceipt = ReceiptParser.parse([]);
      expect(emptyReceipt.isEmpty, isTrue);
      expect(emptyReceipt.items, isEmpty);
      expect(emptyReceipt.rawLines, isEmpty);
    });
  });
}

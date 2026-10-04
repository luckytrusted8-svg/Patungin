import 'package:flutter_test/flutter_test.dart';
import 'package:patungin/domain/parser/number_parser.dart';

void main() {
  group('NumberParser', () {
    test('Format standar ribuan titik', () {
      expect(NumberParser.parse('40.000'), equals(40000));
      expect(NumberParser.parse('1.250.000'), equals(1250000));
    });

    test('Format ribuan koma', () {
      expect(NumberParser.parse('40,000'), equals(40000));
      expect(NumberParser.parse('1,250,000'), equals(1250000));
    });

    test('Format dengan prefix Rp', () {
      expect(NumberParser.parse('Rp40.000'), equals(40000));
      expect(NumberParser.parse('Rp 40.000'), equals(40000));
      expect(NumberParser.parse('Rp. 40.000'), equals(40000));
      expect(NumberParser.parse('IDR 40.000'), equals(40000));
    });

    test('Format dengan akhiran ,- atau .-', () {
      expect(NumberParser.parse('Rp 40.000,-'), equals(40000));
      expect(NumberParser.parse('40.000.-'), equals(40000));
      expect(NumberParser.parse('40.000-'), equals(40000));
    });

    test('Format polos tanpa pemisah ribuan', () {
      expect(NumberParser.parse('40000'), equals(40000));
    });

    test('Format dengan desimal 00 sen', () {
      expect(NumberParser.parse('40.000,00'), equals(40000));
      expect(NumberParser.parse('40,000.00'), equals(40000));
    });

    test('Format dengan notasi k / K', () {
      expect(NumberParser.parse('35k'), equals(35000));
      expect(NumberParser.parse('35K'), equals(35000));
      expect(NumberParser.parse('Rp 22.5k'), equals(22500));
    });

    test('Normalisasi huruf O misread OCR ke angka 0', () {
      expect(NumberParser.parse('35.OOO'), equals(35000));
      expect(NumberParser.parse('Rp 1O.000'), equals(10000));
    });

    test('Input tidak valid menghasilkan null', () {
      expect(NumberParser.parse('abc'), isNull);
      expect(NumberParser.parse(''), isNull);
      expect(NumberParser.parse(null), isNull);
      expect(NumberParser.parse('   '), isNull);
      expect(NumberParser.parse('Nasi Goreng'), isNull);
    });
  });
}

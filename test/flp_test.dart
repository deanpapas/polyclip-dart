import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/precision.dart';
import 'package:polyclip_dart/compare.dart';

void main() {
  group('Decimal compare with epsilon', () {
    const double testEpsilonDouble = 1e-20;
    final Decimal testEpsilon = Decimal.parse(testEpsilonDouble.toString());

    late CompareDecimals compare;

    setUp(() {
      setPrecision(1e-20); // This updates the global precision instance
      compare = precision.compare; // Fetch the latest comparator
    });

    test('exactly equal', () {
      final a = Decimal.fromInt(1);
      final b = Decimal.fromInt(1);
      expect(compare(a, b), equals(0));
    });

    test('equal within epsilon (should be 0)', () {
      final a = Decimal.fromInt(1);
      final b = a + testEpsilon;
      expect(compare(a, b), equals(0));
    });

    test('just outside epsilon (should be -1)', () {
      final a = Decimal.fromInt(1);
      final b = a + (testEpsilon * Decimal.fromInt(2));
      expect(compare(a, b), equals(-1));
    });

    test('a < b', () {
      final a = Decimal.fromInt(1);
      final b = Decimal.fromInt(2);
      expect(compare(a, b), equals(-1));
    });

    test('a > b', () {
      final a = Decimal.fromInt(2);
      final b = Decimal.fromInt(1);
      expect(compare(a, b), equals(1));
    });

    test('both near zero (should be equal)', () {
      final a = Decimal.zero;
      final b = testEpsilon - (testEpsilon * testEpsilon);
      expect(compare(a, b), equals(0));
    });

    test('really close to zero but not equal (should be 0)', () {
      final a = testEpsilon;
      final b = a + (testEpsilon * testEpsilon * Decimal.fromInt(2));
      expect(compare(a, b), equals(0));
    });

    tearDown(() {
      setPrecision(); // Reset global precision
    });
  });
}

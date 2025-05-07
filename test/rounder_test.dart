import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

void main() {
  group('precision.snap()', () {
    test('no overlap', () {
      setPrecision();
      final pt1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final pt2 = Point(x: Decimal.fromInt(4), y: Decimal.fromInt(5));
      final pt3 = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5));

      expect(precision.snap(pt1), equals(pt1));
      expect(precision.snap(pt2), equals(pt2));
      expect(precision.snap(pt3), equals(pt3));
    });

    test('exact overlap', () {
      setPrecision();
      final pt1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final pt2 = Point(x: Decimal.fromInt(4), y: Decimal.fromInt(5));
      final pt3 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));

      expect(precision.snap(pt1), equals(pt1));
      expect(precision.snap(pt2), equals(pt2));
      expect(precision.snap(pt3), equals(pt1)); // snapped to same as pt1
    });

    test('rounding one coordinate', () {
      setPrecision(1e-16);
      final pt1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final pt2 = Point(
        x: Decimal.fromInt(3) + Decimal.parse((1e-16).toString()),
        y: Decimal.fromInt(4),
      );
      final pt3 = Point(
        x: Decimal.fromInt(3),
        y: Decimal.fromInt(4) + Decimal.parse((1e-16).toString()),
      );

      final snapped = precision.snap(pt1);
      expect(precision.snap(pt1), equals(snapped));
      expect(precision.snap(pt2), equals(snapped));
      expect(precision.snap(pt3), equals(snapped));
    });

    test('rounding both coordinates', () {
      setPrecision(1e-16);
      final pt1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final pt2 = Point(
        x: Decimal.fromInt(3) + Decimal.parse((1e-16).toString()),
        y: Decimal.fromInt(4) + Decimal.parse((1e-16).toString()),
      );

      final snapped = precision.snap(pt1);
      expect(precision.snap(pt1), equals(snapped));
      expect(precision.snap(pt2), equals(snapped));
    });

    test('preseed with 0', () {
      setPrecision(1e-16);
      final pt1 = Point(
        x: Decimal.parse((1e-16 / 2).toString()),
        y: Decimal.parse((-1e-16 / 2).toString()),
      );
      final expected = Point(x: Decimal.zero, y: Decimal.zero);

      expect(pt1.x == Decimal.zero, isFalse);
      expect(pt1.y == Decimal.zero, isFalse);
      expect(precision.snap(pt1), equals(expected));
    });
  });
}

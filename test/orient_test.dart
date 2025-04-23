import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

void main() {
  group('compare vector angles', () {
    test('collinear', () {
      final pt1 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(1));
      final pt2 = Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2));
      final pt3 = Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(3));
      
      expect(precision.orient(pt1, pt2, pt3), equals(0));
      expect(precision.orient(pt2, pt1, pt3), equals(0));
      expect(precision.orient(pt2, pt3, pt1), equals(0));
      expect(precision.orient(pt3, pt2, pt1), equals(0));
    });
    
    test('offset', () {
      final pt1 = Vector(x: Decimal.zero, y: Decimal.zero);
      final pt2 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(1));
      final pt3 = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
      
      expect(precision.orient(pt1, pt2, pt3), equals(1));
      expect(precision.orient(pt2, pt1, pt3), equals(-1));
      expect(precision.orient(pt2, pt3, pt1), equals(1));
      expect(precision.orient(pt3, pt2, pt1), equals(-1));
    });
  });
}
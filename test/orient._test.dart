// precision_test.dart
import 'package:test/test.dart';
import 'package:polyclip_dart/polyclip.dart';
import 'package:decimal/decimal.dart';


void main() {
  group('compare vector angles', () {
    test('colinear', () {
      final pt1 = Vector(1, 1);
      final pt2 = Vector(2, 2);
      final pt3 = Vector(3, 3);

      expect(Precision.orient(pt1, pt2, pt3), equals(0));
      expect(Precision.orient(pt2, pt1, pt3), equals(0));
      expect(Precision.orient(pt2, pt3, pt1), equals(0));
      expect(Precision.orient(pt3, pt2, pt1), equals(0));
    });

    test('offset', () {
      final pt1 = Vector(0, 0);
      final pt2 = Vector(1, 1);
      final pt3 = Vector(1, 0);

      expect(Precision.orient(pt1, pt2, pt3), equals(1));
      expect(Precision.orient(pt2, pt1, pt3), equals(-1));
      expect(Precision.orient(pt2, pt3, pt1), equals(1));
      expect(Precision.orient(pt3, pt2, pt1), equals(-1));
    });
  });
}

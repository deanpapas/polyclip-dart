import 'dart:collection';
import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

RingIn dummyRingIn() {
  final ring = [
    [0.0, 0.0],
    [1.0, 0.0],
    [1.0, 1.0],
    [0.0, 1.0],
    [0.0, 0.0],
  ];
  final poly = Poly([ring]);
  final multiPoly = MultiPoly([poly]);
  final multiPolyIn = MultiPolyIn(multiPoly, true);
  final polyIn = PolyIn(poly, multiPolyIn);
  return RingIn(ring, polyIn, true);
}

Segment makeSegment(int x1, int y1, int x2, int y2) {
  return Segment.fromRing(
    Point(x: Decimal.fromInt(x1), y: Decimal.fromInt(y1)),
    Point(x: Decimal.fromInt(x2), y: Decimal.fromInt(y2)),
    dummyRingIn(),
  );
}

void main() {
  group("sweep line", () {
    test("test filling up the tree then emptying it out", () {
      final k1 = makeSegment(0, 0, 1, 1);
      final k2 = makeSegment(2, 2, 3, 3);
      final k3 = makeSegment(4, 4, 5, 5);
      final k4 = makeSegment(6, 6, 7, 7);

      final sweepLine = SweepLine(
        SplayTreeSet<SweepEvent>(),
        Segment.compare,
      );

      final tree = sweepLine.tree;

      tree.add(k1);
      tree.add(k2);
      tree.add(k3);
      tree.add(k4);

      expect(tree.contains(k1), isTrue);
      expect(tree.contains(k2), isTrue);
      expect(tree.contains(k3), isTrue);
      expect(tree.contains(k4), isTrue);

      expect(sweepLine.findLastBefore(tree, k1), isNull);
      expect(sweepLine.findFirstAfter(tree, k1), equals(k2));

      expect(sweepLine.findLastBefore(tree, k2), equals(k1));
      expect(sweepLine.findFirstAfter(tree, k2), equals(k3));

      expect(sweepLine.findLastBefore(tree, k3), equals(k2));
      expect(sweepLine.findFirstAfter(tree, k3), equals(k4));

      expect(sweepLine.findLastBefore(tree, k4), equals(k3));
      expect(sweepLine.findFirstAfter(tree, k4), isNull);

      tree.remove(k2);
      expect(tree.contains(k2), isFalse);

      expect(sweepLine.findLastBefore(tree, k1), isNull);
      expect(sweepLine.findFirstAfter(tree, k1), equals(k3));

      expect(sweepLine.findLastBefore(tree, k3), equals(k1));
      expect(sweepLine.findFirstAfter(tree, k3), equals(k4));

      expect(sweepLine.findLastBefore(tree, k4), equals(k3));
      expect(sweepLine.findFirstAfter(tree, k4), isNull);

      tree.remove(k4);
      expect(tree.contains(k4), isFalse);

      expect(sweepLine.findLastBefore(tree, k1), isNull);
      expect(sweepLine.findFirstAfter(tree, k1), equals(k3));

      expect(sweepLine.findLastBefore(tree, k3), equals(k1));
      expect(sweepLine.findFirstAfter(tree, k3), isNull);

      tree.remove(k1);
      expect(tree.contains(k1), isFalse);

      expect(sweepLine.findLastBefore(tree, k3), isNull);
      expect(sweepLine.findFirstAfter(tree, k3), isNull);

      tree.remove(k3);
      expect(tree.contains(k3), isFalse);
    });
  });
}

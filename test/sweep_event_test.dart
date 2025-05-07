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

void main() {
  group("sweep event compare", () {
    test("favor earlier x in point", () {
      final s1 = SweepEvent(
          Point(x: Decimal.fromInt(-5), y: Decimal.fromInt(4)), true);
      final s2 =
          SweepEvent(Point(x: Decimal.fromInt(5), y: Decimal.fromInt(1)), true);
      expect(SweepEvent.compare(s1, s2), equals(-1));
      expect(SweepEvent.compare(s2, s1), equals(1));
    });

    test("then favor earlier y in point", () {
      final s1 = SweepEvent(
          Point(x: Decimal.fromInt(5), y: Decimal.fromInt(-4)), true);
      final s2 =
          SweepEvent(Point(x: Decimal.fromInt(5), y: Decimal.fromInt(4)), true);
      expect(SweepEvent.compare(s1, s2), equals(-1));
      expect(SweepEvent.compare(s2, s1), equals(1));
    });

    test("then favor right events over left", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
        Point(x: Decimal.fromInt(6), y: Decimal.fromInt(5)),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.rightSE, seg2.leftSE), equals(-1));
      expect(SweepEvent.compare(seg2.leftSE, seg1.rightSE), equals(1));
    });

    test("then favor non-vertical segments for left events", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2)),
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), equals(-1));
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), equals(1));
    });

    test("then favor vertical segments for right events", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        Point(x: Decimal.fromInt(1), y: Decimal.fromInt(2)),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), equals(-1));
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), equals(1));
    });

    test("then favor lower segment", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0)),
        Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0)),
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), equals(-1));
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), equals(1));
    });

    test("and favor barely lower segment", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.parse('-75.725'), y: Decimal.parse('45.357')),
        Point(
            x: Decimal.parse('-75.72484615384616'),
            y: Decimal.parse('45.35723076923077')),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.parse('-75.725'), y: Decimal.parse('45.357')),
        Point(x: Decimal.parse('-75.723'), y: Decimal.parse('45.36')),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.leftSE), equals(1));
      expect(SweepEvent.compare(seg2.leftSE, seg1.leftSE), equals(-1));
    });

    test("then favor lower ring id", () {
      final ring1 = dummyRingIn();
      final ring2 = dummyRingIn();
      final seg1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
        ring1,
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
        ring2,
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.leftSE), equals(-1));
      expect(SweepEvent.compare(seg2.leftSE, seg1.leftSE), equals(1));
    });

    test("identical equal", () {
      final seg = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
        dummyRingIn(),
      );
      final s1 = seg.leftSE;
      expect(SweepEvent.compare(s1, s1), equals(0));
    });

    test("totally equal but not identical events are consistent", () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
        dummyRingIn(),
      );
      final s1 = seg1.leftSE;
      final s2 = seg2.leftSE;
      final result = SweepEvent.compare(s1, s2);
      expect(SweepEvent.compare(s1, s2), equals(result));
      expect(SweepEvent.compare(s2, s1), equals(-result));
    });

    test("events are linked as side effect", () {
      setPrecision(null); // disable snap unification

      final pt1 = Point(x: Decimal.zero, y: Decimal.zero);
      final pt2 = Point(x: Decimal.zero, y: Decimal.zero);

      final seg1 = Segment.fromRing(
        pt1,
        Point(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        pt2,
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        dummyRingIn(),
      );

      final s1 = seg1.leftSE;
      final s2 = seg2.leftSE;

      expect(identical(s1.point, s2.point), isFalse);
      SweepEvent.compare(s1, s2);
      expect(identical(s1.point, s2.point), isTrue);
    });

    test("consistency edge case", () {
      final seg1 = Segment.fromRing(
        Point(
            x: Decimal.parse('-71.0390933353125'),
            y: Decimal.parse('41.504475')),
        Point(x: Decimal.parse('-71.0389879'), y: Decimal.parse('41.5037842')),
        dummyRingIn(),
      );
      final seg2 = Segment.fromRing(
        Point(
            x: Decimal.parse('-71.0390933353125'),
            y: Decimal.parse('41.504475')),
        Point(
            x: Decimal.parse('-71.03906280974431'),
            y: Decimal.parse('41.504275')),
        dummyRingIn(),
      );
      expect(SweepEvent.compare(seg1.leftSE, seg2.leftSE), equals(-1));
      expect(SweepEvent.compare(seg2.leftSE, seg1.leftSE), equals(1));
    });
  });
}

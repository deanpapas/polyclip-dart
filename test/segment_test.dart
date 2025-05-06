import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

RingIn makeRingIn(Point a, Point b) {
  final ring = [
    [a.x.toDouble(), a.y.toDouble()],
    [b.x.toDouble(), b.y.toDouble()],
    [a.x.toDouble(), a.y.toDouble()],
  ];
  final poly = Poly([ring]);
  final multi = MultiPolyIn(poly, true);
  return multi.polys.first.exteriorRing;
}

void main() {
  group('Segment', () {
    test('throws for degenerate segment', () {
      final pt = Point(x: Decimal.zero, y: Decimal.zero);
      final ringIn = makeRingIn(pt, pt); // Valid poly for constructor

      expect(
        () => Segment.fromRing(pt, pt, ringIn),
        throwsA(isA<Exception>()),
      );
    });

    test('assigns sweep events correctly', () {
      final pt1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
      final pt2 = Point(x: Decimal.fromInt(10), y: Decimal.fromInt(10));
      final ringIn = makeRingIn(pt1, pt2);
      final seg = Segment.fromRing(pt1, pt2, ringIn);

      expect(seg.leftSE.segment, same(seg));
      expect(seg.rightSE.segment, same(seg));
      expect(seg.leftSE.otherSE, same(seg.rightSE));
      expect(seg.rightSE.otherSE, same(seg.leftSE));
    });

    test('assigns correct winding when pt1 < pt2', () {
      final pt1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
      final pt2 = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(0));
      final ringIn = makeRingIn(pt1, pt2);
      final seg = Segment.fromRing(pt1, pt2, ringIn);

      expect(seg.windings!.first, equals(1));
    });

    test('general', () {
      final pt1 = Point(x: Decimal.fromInt(1), y: Decimal.fromInt(2));
      final pt2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final ringIn = makeRingIn(pt1, pt2);
      final seg = Segment.fromRing(pt1, pt2, ringIn);

      final bbox = seg.bbox();
      expect(bbox.ll.x.toDouble(), equals(1));
      expect(bbox.ll.y.toDouble(), equals(2));
      expect(bbox.ur.x.toDouble(), equals(3));
      expect(bbox.ur.y.toDouble(), equals(4));

      final vec = seg.vector();
      expect(vec.x.toDouble(), equals(2));
      expect(vec.y.toDouble(), equals(2));
    });

    test('horizontal', () {
      final pt1 = Point(x: Decimal.fromInt(1), y: Decimal.fromInt(4));
      final pt2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final ringIn = makeRingIn(pt1, pt2);
      final seg = Segment.fromRing(pt1, pt2, ringIn);

      final bbox = seg.bbox();
      expect(bbox.ll.x.toDouble(), equals(1));
      expect(bbox.ll.y.toDouble(), equals(4));
      expect(bbox.ur.x.toDouble(), equals(3));
      expect(bbox.ur.y.toDouble(), equals(4));

      final vec = seg.vector();
      expect(vec.x.toDouble(), equals(2));
      expect(vec.y.toDouble(), equals(0));
    });

    test('vertical', () {
      final pt1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2));
      final pt2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      final ringIn = makeRingIn(pt1, pt2);
      final seg = Segment.fromRing(pt1, pt2, ringIn);

      final bbox = seg.bbox();
      expect(bbox.ll.x.toDouble(), equals(3));
      expect(bbox.ll.y.toDouble(), equals(2));
      expect(bbox.ur.x.toDouble(), equals(3));
      expect(bbox.ur.y.toDouble(), equals(4));

      final vec = seg.vector();
      expect(vec.x.toDouble(), equals(0));
      expect(vec.y.toDouble(), equals(2));
    });

    test('throws for degenerate segment', () {
      final pt = Point(x: Decimal.zero, y: Decimal.zero);
      final ringIn = makeRingIn(pt, pt);

      expect(
        () => Segment.fromRing(pt, pt, ringIn),
        throwsA(isA<Exception>()),
      );
    });

    test('assigns sweep events correctly', () {
      final pt1 = Point(x: Decimal.parse('0'), y: Decimal.parse('0'));
      final pt2 = Point(x: Decimal.parse('10'), y: Decimal.parse('10'));
      final ringIn = makeRingIn(pt1, pt2);
      final segment = Segment.fromRing(pt1, pt2, ringIn);

      expect(segment.leftSE.segment, same(segment));
      expect(segment.rightSE.segment, same(segment));
      expect(segment.leftSE.otherSE, same(segment.rightSE));
      expect(segment.rightSE.otherSE, same(segment.leftSE));
    });

    test('creates with correct winding direction', () {
      final pt1 = Point(x: Decimal.parse('0'), y: Decimal.parse('0'));
      final pt2 = Point(x: Decimal.parse('5'), y: Decimal.parse('0'));
      final ringIn = makeRingIn(pt1, pt2);
      final segment = Segment.fromRing(pt1, pt2, ringIn);

      expect(segment.windings!.first, equals(1));
    });
  });

  test('reverse winding if points reversed', () {
    final pt1 = Point(x: Decimal.parse('5'), y: Decimal.parse('0'));
    final pt2 = Point(x: Decimal.parse('0'), y: Decimal.parse('0'));
    final ringIn = makeRingIn(pt1, pt2);
    final segment = Segment.fromRing(pt1, pt2, ringIn);

    expect(segment.windings!.first, equals(-1));
  });

  test('bbox is correct', () {
    final pt1 = Point(x: Decimal.parse('2'), y: Decimal.parse('3'));
    final pt2 = Point(x: Decimal.parse('8'), y: Decimal.parse('1'));
    final ringIn = makeRingIn(pt1, pt2);
    final segment = Segment.fromRing(pt1, pt2, ringIn);
    final bbox = segment.bbox();

    expect(bbox.ll.x.toDouble(), equals(2));
    expect(bbox.ur.x.toDouble(), equals(8));
    expect(bbox.ll.y.toDouble(), equals(1));
    expect(bbox.ur.y.toDouble(), equals(3));
  });

  test('vector is correct', () {
    final pt1 = Point(x: Decimal.parse('2'), y: Decimal.parse('3'));
    final pt2 = Point(x: Decimal.parse('5'), y: Decimal.parse('9'));
    final ringIn = makeRingIn(pt1, pt2);
    final segment = Segment.fromRing(pt1, pt2, ringIn);
    final v = segment.vector();

    expect(v.x.toDouble(), closeTo(3.0, 1e-9));
    expect(v.y.toDouble(), closeTo(6.0, 1e-9));
  });

  test('horizontal and vertical T-intersection', () {
    final ptA1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final ptA2 = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(0));
    final segA = Segment.fromRing(ptA1, ptA2, makeRingIn(ptA1, ptA2));

    final ptB1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(0));
    final ptB2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(5));
    final segB = Segment.fromRing(ptB1, ptB2, makeRingIn(ptB1, ptB2));

    final inter = Point(x: Decimal.fromInt(3), y: Decimal.zero);
    expect(
        segA.getIntersection(segB)?.x.toDouble(), equals(inter.x.toDouble()));
    expect(
        segA.getIntersection(segB)?.y.toDouble(), equals(inter.y.toDouble()));
    expect(
        segB.getIntersection(segA)?.x.toDouble(), equals(inter.x.toDouble()));
    expect(
        segB.getIntersection(segA)?.y.toDouble(), equals(inter.y.toDouble()));
  });

  test('horizontal and vertical general intersection', () {
    final ptA1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final ptA2 = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(0));
    final segA = Segment.fromRing(ptA1, ptA2, makeRingIn(ptA1, ptA2));

    final ptB1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(-5));
    final ptB2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(5));
    final segB = Segment.fromRing(ptB1, ptB2, makeRingIn(ptB1, ptB2));

    final inter = Point(x: Decimal.fromInt(3), y: Decimal.zero);
    expect(
        segA.getIntersection(segB)?.x.toDouble(), equals(inter.x.toDouble()));
    expect(
        segA.getIntersection(segB)?.y.toDouble(), equals(inter.y.toDouble()));
    expect(
        segB.getIntersection(segA)?.x.toDouble(), equals(inter.x.toDouble()));
    expect(
        segB.getIntersection(segA)?.y.toDouble(), equals(inter.y.toDouble()));
  });

  test('no intersection not even close', () {
    final ptA1 = Point(x: Decimal.fromInt(1000), y: Decimal.fromInt(10002));
    final ptA2 = Point(x: Decimal.fromInt(2000), y: Decimal.fromInt(20002));
    final segA = Segment.fromRing(ptA1, ptA2, makeRingIn(ptA1, ptA2));

    final ptB1 = Point(x: Decimal.fromInt(-234), y: Decimal.fromInt(-123));
    final ptB2 = Point(x: Decimal.fromInt(-12), y: Decimal.fromInt(-23));
    final segB = Segment.fromRing(ptB1, ptB2, makeRingIn(ptB1, ptB2));

    expect(segA.getIntersection(segB), isNull);
    expect(segB.getIntersection(segA), isNull);
  });

  test('no intersection kinda close', () {
    final a1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final a2 = Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4));
    final b1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(10));
    final b2 = Point(x: Decimal.fromInt(10), y: Decimal.fromInt(0));
    final seg1 = Segment.fromRing(a1, a2, makeRingIn(a1, a2));
    final seg2 = Segment.fromRing(b1, b2, makeRingIn(b1, b2));

    expect(seg1.getIntersection(seg2), isNull);
    expect(seg2.getIntersection(seg1), isNull);
  });

  test('no intersection with vertical touching bbox', () {
    final a1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final a2 = Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4));
    final b1 = Point(x: Decimal.fromInt(2), y: Decimal.fromInt(-5));
    final b2 = Point(x: Decimal.fromInt(2), y: Decimal.fromInt(0));
    final seg1 = Segment.fromRing(a1, a2, makeRingIn(a1, a2));
    final seg2 = Segment.fromRing(b1, b2, makeRingIn(b1, b2));

    expect(seg1.getIntersection(seg2), isNull);
    expect(seg2.getIntersection(seg1), isNull);
  });

  test('intersect with vertical', () {
    final a1 = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final a2 = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5));
    final b1 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(0));
    final b2 = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(44));
    final seg1 = Segment.fromRing(a1, a2, makeRingIn(a1, a2));
    final seg2 = Segment.fromRing(b1, b2, makeRingIn(b1, b2));

    final inter = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3));
    final i1 = seg1.getIntersection(seg2)!;
    final i2 = seg2.getIntersection(seg1)!;

    expect(i1.x.toDouble(), closeTo(inter.x.toDouble(), 1e-9));
    expect(i1.y.toDouble(), closeTo(inter.y.toDouble(), 1e-9));
    expect(i2.x.toDouble(), closeTo(inter.x.toDouble(), 1e-9));
    expect(i2.y.toDouble(), closeTo(inter.y.toDouble(), 1e-9));
  });

  test('intersect with horizontal', () {
    final s1 = Segment.fromRing(
        Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0)),
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
        makeRingIn(Point(x: Decimal.zero, y: Decimal.zero),
            Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5))));
    final s2 = Segment.fromRing(
        Point(x: Decimal.fromInt(0), y: Decimal.fromInt(3)),
        Point(x: Decimal.fromInt(23), y: Decimal.fromInt(3)),
        makeRingIn(Point(x: Decimal.fromInt(0), y: Decimal.fromInt(3)),
            Point(x: Decimal.fromInt(23), y: Decimal.fromInt(3))));
    final inter = Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3));
    expect(s1.getIntersection(s2)!.x.toDouble(),
        closeTo(inter.x.toDouble(), 1e-9));
    expect(s1.getIntersection(s2)!.y.toDouble(),
        closeTo(inter.y.toDouble(), 1e-9));
  });

  test('split on interior point', () {
    final a = Point(x: Decimal.fromInt(0), y: Decimal.fromInt(0));
    final b = Point(x: Decimal.fromInt(10), y: Decimal.fromInt(10));
    final seg = Segment.fromRing(a, b, makeRingIn(a, b));
    final pt = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5));
    final evts = seg.split(pt);

    expect(evts[0].point.x, pt.x);
    expect(evts[0].isLeft, false);
    expect(evts[1].point.x, pt.x);
    expect(evts[1].isLeft, true);
    expect(evts[1].segment.rightSE.segment, same(evts[1].segment));
  });

  test('endpoint intersections should be consistent - issue 60', () {
    setPrecision(1e-20); // mimicking Number.EPSILON
    final x = Decimal.parse('-91.41360941065206');
    final y = Decimal.parse('29.53135');

    final segA1 = Segment.fromRing(
        Point(x: x, y: y),
        Point(x: Decimal.parse('-91.4134943'), y: Decimal.parse('29.5310677')),
        makeRingIn(
            Point(x: x, y: y),
            Point(
                x: Decimal.parse('-91.4134943'),
                y: Decimal.parse('29.5310677'))));
    final segA2 = Segment.fromRing(
        Point(x: x, y: y),
        Point(x: Decimal.parse('-91.413'), y: Decimal.parse('29.5315')),
        makeRingIn(Point(x: x, y: y),
            Point(x: Decimal.parse('-91.413'), y: Decimal.parse('29.5315'))));
    final segB = Segment.fromRing(
        Point(x: Decimal.parse('-91.4137213'), y: Decimal.parse('29.5316244')),
        Point(
            x: Decimal.parse('-91.41352785864918'),
            y: Decimal.parse('29.53115')),
        makeRingIn(
            Point(
                x: Decimal.parse('-91.4137213'),
                y: Decimal.parse('29.5316244')),
            Point(
                x: Decimal.parse('-91.41352785864918'),
                y: Decimal.parse('29.53115'))));

    final expected = Point(x: x, y: y);
    expect(segA1.getIntersection(segB)?.x.toDouble(),
        closeTo(expected.x.toDouble(), 1e-10));
    expect(segA2.getIntersection(segB)?.x.toDouble(),
        closeTo(expected.x.toDouble(), 1e-10));
  });

  test('ensure transitive - part of issue 60', () {
    final seg2 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000018'), y: Decimal.parse('-9.17')),
        Point(
            x: Decimal.parse('-10.000000000000004'), y: Decimal.parse('-8.79')),
        makeRingIn(
            Point(
                x: Decimal.parse('-10.000000000000018'),
                y: Decimal.parse('-9.17')),
            Point(
                x: Decimal.parse('-10.000000000000004'),
                y: Decimal.parse('-8.79'))));
    final seg6 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000016'), y: Decimal.parse('1.44')),
        Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5')),
        makeRingIn(
            Point(
                x: Decimal.parse('-10.000000000000016'),
                y: Decimal.parse('1.44')),
            Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5'))));
    final seg4 = Segment.fromRing(
        Point(x: Decimal.parse('-10.00000000000001'), y: Decimal.parse('1.75')),
        Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5')),
        makeRingIn(
            Point(
                x: Decimal.parse('-10.00000000000001'),
                y: Decimal.parse('1.75')),
            Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5'))));

    expect(Segment.compare(seg2, seg6), lessThan(0));
    expect(Segment.compare(seg6, seg4), lessThan(0));
    expect(Segment.compare(seg2, seg4), lessThan(0));
  });
}

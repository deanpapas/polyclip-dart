import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

void main() {
  RingIn dummyRing() {
    final ringGeomIn = [
      [0.0, 0.0],
      [1.0, 0.0],
      [0.0, 0.0]
    ];
    final poly = Poly([ringGeomIn]);
    final multi = MultiPolyIn(poly, true);
    return multi.polys.first.exteriorRing;
  }

  group('Segment constructor', () {
    test('general', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.one, y: Decimal.one);
      final left = SweepEvent(p1, false);
      final right = SweepEvent(p2, false);
      final seg = Segment(left, right, [], []);

      expect(seg.rings, isEmpty);
      expect(seg.windings, isEmpty);
      expect(seg.leftSE, same(left));
      expect(seg.rightSE, same(right));
      expect(seg.leftSE.otherSE, same(right));
      expect(seg.rightSE.otherSE, same(left));
      expect(seg.ringOut, null);
      expect(seg.prev, null);
      expect(seg.consumedBy, null);
    });

    test('segment id increments', () {
      final pt = Point(x: Decimal.zero, y: Decimal.zero);
      final left = SweepEvent(pt, false);
      final right = SweepEvent(pt, false);
      final seg1 = Segment(left, right, [], []);
      final seg2 = Segment(left, right, [], []);
      expect(seg2.id - seg1.id, equals(1));
    });
  });

  group('Segment.fromRing', () {
    test('correct left/right: vertical ascending', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.zero, y: Decimal.one);
      final seg = Segment.fromRing(p1, p2, dummyRing());
      expect(seg.leftSE.point, equals(p1));
      expect(seg.rightSE.point, equals(p2));
    });

    test('correct left/right: horizontal descending', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.parse('-1'), y: Decimal.zero);
      final seg = Segment.fromRing(p1, p2, dummyRing());
      expect(seg.leftSE.point, equals(p2));
      expect(seg.rightSE.point, equals(p1));
    });

    test('throws on identical points', () {
      final pt = Point(x: Decimal.zero, y: Decimal.zero);
      expect(() => Segment.fromRing(pt, pt, dummyRing()), throwsException);
    });
  });

  group('Segment.split', () {
    test('interior point split', () {
      final seg = Segment.fromRing(Point(x: Decimal.zero, y: Decimal.zero),
          Point(x: Decimal.fromInt(10), y: Decimal.fromInt(10)), dummyRing());
      final pt = Point(x: Decimal.fromInt(5), y: Decimal.fromInt(5));
      final evts = seg.split(pt);

      expect(evts[0].segment, same(seg));
      expect(evts[0].point, equals(pt));
      expect(evts[0].isLeft, false);
      expect(evts[0].otherSE.otherSE, same(evts[0]));

      expect(evts[1].segment.leftSE.segment, same(evts[1].segment));
      expect(evts[1].segment, isNot(same(seg)));
      expect(evts[1].point, equals(pt));
      expect(evts[1].isLeft, isTrue);
      expect(evts[1].otherSE.otherSE, same(evts[1]));
    });

    test('split on near-interior point (precision test)', () {
      final seg = Segment.fromRing(
          Point(x: Decimal.zero, y: Decimal.fromInt(10)),
          Point(x: Decimal.fromInt(10), y: Decimal.zero),
          dummyRing());
      final pt = Point(
        x: Decimal.parse('5.0000000000000001'),
        y: Decimal.fromInt(5),
      );
      final evts = seg.split(pt);
      expect(evts.length, equals(2));
      expect(evts[0].point, equals(pt));
      expect(evts[1].point, equals(pt));
    });
  });

  group('Segment bbox and vector', () {
    test('general', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.fromInt(2)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        dummyRing(),
      );
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
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.fromInt(4)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        dummyRing(),
      );
      final vec = seg.vector();
      expect(vec.x.toDouble(), equals(2));
      expect(vec.y.toDouble(), equals(0));
    });

    test('vertical', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(2)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
        dummyRing(),
      );
      final vec = seg.vector();
      expect(vec.x.toDouble(), equals(0));
      expect(vec.y.toDouble(), equals(2));
    });
  });

  group('Segment.consume', () {
    test('not automatically consumed', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.one, y: Decimal.zero);
      final seg1 = Segment.fromRing(p1, p2, dummyRing());
      final seg2 = Segment.fromRing(p1, p2, dummyRing());

      expect(seg1.consumedBy, null);
      expect(seg2.consumedBy, null);
    });

    test('basic consumption', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.one, y: Decimal.zero);
      final seg1 = Segment.fromRing(p1, p2, dummyRing());
      final seg2 = Segment.fromRing(p1, p2, dummyRing());

      seg1.consume(seg2);
      expect(seg2.consumedBy, same(seg1));
      expect(seg1.consumedBy, null);
    });

    test('earlier in sweepline consumes later', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.one, y: Decimal.zero);
      final seg1 = Segment.fromRing(p1, p2, dummyRing());
      final seg2 = Segment.fromRing(p1, p2, dummyRing());

      seg2.consume(seg1);
      expect(seg2.consumedBy, same(seg1));
      expect(seg1.consumedBy, null);
    });

    test('cascading consumption', () {
      final p1 = Point(x: Decimal.zero, y: Decimal.zero);
      final p2 = Point(x: Decimal.one, y: Decimal.zero);
      final seg1 = Segment.fromRing(p1, p2, dummyRing());
      final seg2 = Segment.fromRing(p1, p2, dummyRing());
      final seg3 = Segment.fromRing(p1, p2, dummyRing());
      final seg4 = Segment.fromRing(p1, p2, dummyRing());
      final seg5 = Segment.fromRing(p1, p2, dummyRing());

      seg1.consume(seg2);
      seg4.consume(seg2);
      seg3.consume(seg2);
      seg3.consume(seg5);

      expect(seg1.consumedBy, null);
      expect(seg2.consumedBy, same(seg1));
      expect(seg3.consumedBy, same(seg1));
      expect(seg4.consumedBy, same(seg1));
      expect(seg5.consumedBy, same(seg1));
    });
  });

  group('Segment.isAnEndpoint', () {
    final p1 = Point(x: Decimal.zero, y: Decimal.fromInt(-1));
    final p2 = Point(x: Decimal.one, y: Decimal.zero);
    final seg = Segment.fromRing(p1, p2, dummyRing());

    test('returns true for endpoints', () {
      expect(seg.isAnEndpoint(p1), isTrue);
      expect(seg.isAnEndpoint(p2), isTrue);
    });

    test('returns false for non-endpoints', () {
      expect(
          seg.isAnEndpoint(
              Point(x: Decimal.fromInt(-34), y: Decimal.fromInt(46))),
          false);
      expect(
          seg.isAnEndpoint(Point(x: Decimal.zero, y: Decimal.zero)), false);
    });
  });

  group('Segment.comparePoint', () {
    test('general segment comparison with points', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.one, y: Decimal.one),
        dummyRing(),
      );

      expect(
          s1.comparePoint(Point(x: Decimal.zero, y: Decimal.one)), equals(1));
      expect(s1.comparePoint(Point(x: Decimal.one, y: Decimal.fromInt(2))),
          equals(1));
      expect(
          s1.comparePoint(Point(x: Decimal.zero, y: Decimal.zero)), equals(0));
      expect(
          s1.comparePoint(Point(x: Decimal.fromInt(5), y: Decimal.fromInt(-1))),
          equals(-1));
    });

    test('barely above the segment', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.one),
        dummyRing(),
      );
      final pt = Point(
        x: Decimal.fromInt(2),
        y: Decimal.one - Decimal.parse('1e-15'),
      );
      expect(s1.comparePoint(pt), equals(-1));
    });

    test('barely below the segment', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.one),
        dummyRing(),
      );

      final pt = Point(
        x: Decimal.fromInt(2),
        y: Decimal.one +
            (Decimal.parse('1e-15') * Decimal.fromInt(3) / Decimal.fromInt(2))
                .toDecimal(),
      );

      expect(s1.comparePoint(pt), equals(1));
    });

    test('vertical before/after/on', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.one, y: Decimal.fromInt(3)),
        dummyRing(),
      );
      expect(
          seg.comparePoint(Point(x: Decimal.zero, y: Decimal.zero)), equals(1));
      expect(seg.comparePoint(Point(x: Decimal.fromInt(2), y: Decimal.zero)),
          equals(-1));
      expect(
          seg.comparePoint(Point(x: Decimal.one, y: Decimal.zero)), equals(0));
    });

    test('horizontal below/above/on', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.one),
        dummyRing(),
      );
      expect(seg.comparePoint(Point(x: Decimal.zero, y: Decimal.zero)),
          equals(-1));
      expect(seg.comparePoint(Point(x: Decimal.zero, y: Decimal.fromInt(2))),
          equals(1));
      expect(
          seg.comparePoint(Point(x: Decimal.zero, y: Decimal.one)), equals(0));
    });

    test('plane comparisons: upward, downward slopes', () {
      final up = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
        dummyRing(),
      );
      final down = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.fromInt(3)),
        Point(x: Decimal.fromInt(3), y: Decimal.one),
        dummyRing(),
      );

      expect(up.comparePoint(Point(x: Decimal.zero, y: Decimal.fromInt(2))),
          equals(1));
      expect(
          up.comparePoint(Point(x: Decimal.fromInt(4), y: Decimal.fromInt(2))),
          equals(-1));

      expect(down.comparePoint(Point(x: Decimal.zero, y: Decimal.fromInt(2))),
          equals(-1));
      expect(
          down.comparePoint(
              Point(x: Decimal.fromInt(4), y: Decimal.fromInt(2))),
          equals(1));
    });

    test('upward more vertical before/after', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(6)),
        dummyRing(),
      );
      expect(seg.comparePoint(Point(x: Decimal.zero, y: Decimal.fromInt(2))),
          equals(1));
      expect(
          seg.comparePoint(Point(x: Decimal.fromInt(4), y: Decimal.fromInt(2))),
          equals(-1));
    });

    test('downward more vertical before/after', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.fromInt(6)),
        Point(x: Decimal.fromInt(3), y: Decimal.one),
        dummyRing(),
      );
      expect(seg.comparePoint(Point(x: Decimal.zero, y: Decimal.fromInt(2))),
          equals(-1));
      expect(
          seg.comparePoint(Point(x: Decimal.fromInt(4), y: Decimal.fromInt(2))),
          equals(1));
    });

    test('nearly touching downward segment (issue #37)', () {
      final seg = Segment.fromRing(
        Point(x: Decimal.parse('0.523985'), y: Decimal.parse('51.281651')),
        Point(
            x: Decimal.parse('0.5241'), y: Decimal.parse('51.281651000100005')),
        dummyRing(),
      );
      final pt = Point(
        x: Decimal.parse('0.5239850000000027'),
        y: Decimal.parse('51.281651000000004'),
      );
      expect(seg.comparePoint(pt), equals(1));
    });

    test('issue 60-2: avoid false vertical splits', () {
      setPrecision(1e-15);
      final seg = Segment.fromRing(
        Point(x: Decimal.parse('-45.3269382'), y: Decimal.parse('-1.4059341')),
        Point(
            x: Decimal.parse('-45.326737413921656'),
            y: Decimal.parse('-1.40635')),
        dummyRing(),
      );
      final pt = Point(
          x: Decimal.parse('-45.326833968900424'),
          y: Decimal.parse('-1.40615'));
      expect(seg.comparePoint(pt), equals(0));
      setPrecision(); // Reset precision
    });
  });

  group('Segment.getIntersection', () {
    test('colinear full overlap', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.one, y: Decimal.one),
        dummyRing(),
      );
      final s2 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.one, y: Decimal.one),
        dummyRing(),
      );
      expect(s1.getIntersection(s2), null);
      expect(s2.getIntersection(s1), null);
    });

    test('colinear partial overlap upward', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
        dummyRing(),
      );
      final s2 = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
        dummyRing(),
      );
      final inter = Point(x: Decimal.one, y: Decimal.one);
      expect(s1.getIntersection(s2), equals(inter));
      expect(s2.getIntersection(s1), equals(inter));
    });

    test('colinear partial overlap downward', () {
      final s1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.fromInt(2)),
        Point(x: Decimal.fromInt(2), y: Decimal.zero),
        dummyRing(),
      );
      final s2 = Segment.fromRing(
        Point(x: Decimal.parse('-1'), y: Decimal.fromInt(3)),
        Point(x: Decimal.one, y: Decimal.one),
        dummyRing(),
      );
      final inter = Point(x: Decimal.zero, y: Decimal.fromInt(2));
      expect(s1.getIntersection(s2), equals(inter));
      expect(s2.getIntersection(s1), equals(inter));
    });
  });

  group('Segment.getIntersection (continued)', () {
    test('T-intersect at endpoint', () {
      final a = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
        dummyRing(),
      );
      final b = Segment.fromRing(
        Point(x: Decimal.one, y: Decimal.one),
        Point(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
        dummyRing(),
      );
      final inter = Point(x: Decimal.one, y: Decimal.one);
      expect(a.getIntersection(b), equals(inter));
      expect(b.getIntersection(a), equals(inter));
    });

    test('horizontal and vertical intersection', () {
      final a = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(5), y: Decimal.zero),
        dummyRing(),
      );
      final b = Segment.fromRing(
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(-5)),
        Point(x: Decimal.fromInt(3), y: Decimal.fromInt(5)),
        dummyRing(),
      );
      final inter = Point(x: Decimal.fromInt(3), y: Decimal.zero);
      expect(a.getIntersection(b), equals(inter));
      expect(b.getIntersection(a), equals(inter));
    });

    test('no intersection (very far)', () {
      final a = Segment.fromRing(
        Point(x: Decimal.fromInt(1000), y: Decimal.fromInt(10002)),
        Point(x: Decimal.fromInt(2000), y: Decimal.fromInt(20002)),
        dummyRing(),
      );
      final b = Segment.fromRing(
        Point(x: Decimal.parse('-234'), y: Decimal.parse('-123')),
        Point(x: Decimal.parse('-12'), y: Decimal.parse('-23')),
        dummyRing(),
      );
      expect(a.getIntersection(b), null);
      expect(b.getIntersection(a), null);
    });

    test('endpoint intersection consistency (issue #60)', () {
      setPrecision(1e-15);
      final x = Decimal.parse('-91.41360941065206');
      final y = Decimal.parse('29.53135');

      final a1 = Segment.fromRing(
        Point(x: x, y: y),
        Point(x: Decimal.parse('-91.4134943'), y: Decimal.parse('29.5310677')),
        dummyRing(),
      );
      final a2 = Segment.fromRing(
        Point(x: x, y: y),
        Point(x: Decimal.parse('-91.413'), y: Decimal.parse('29.5315')),
        dummyRing(),
      );
      final b = Segment.fromRing(
        Point(x: Decimal.parse('-91.4137213'), y: Decimal.parse('29.5316244')),
        Point(
            x: Decimal.parse('-91.41352785864918'),
            y: Decimal.parse('29.53115')),
        dummyRing(),
      );

      final expected = Point(x: x, y: y);
      expect(a1.getIntersection(b), equals(expected));
      expect(a2.getIntersection(b), equals(expected));
      expect(b.getIntersection(a1), equals(expected));
      expect(b.getIntersection(a2), equals(expected));
      setPrecision();
    });

    test('precision issue: no false positive (issue #79)', () {
      final a = Segment.fromRing(
        Point(
            x: Decimal.parse('145.854148864746'),
            y: Decimal.parse('-41.99816840491791')),
        Point(
            x: Decimal.parse('145.85421323776'),
            y: Decimal.parse('-41.9981723915721')),
        dummyRing(),
      );
      final b = Segment.fromRing(
        Point(
            x: Decimal.parse('145.854148864746'),
            y: Decimal.parse('-41.998168404918')),
        Point(x: Decimal.parse('145.8543'), y: Decimal.parse('-41.9982')),
        dummyRing(),
      );
      expect(a.getIntersection(b), null);
      expect(b.getIntersection(a), null);
    });
  });

  group('Segment.compare', () {
    test('non-intersecting segments', () {
      final seg1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.one, y: Decimal.one),
        dummyRing(),
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.fromInt(4), y: Decimal.fromInt(3)),
        Point(x: Decimal.fromInt(6), y: Decimal.fromInt(7)),
        dummyRing(),
      );
      expect(Segment.compare(seg1, seg2), equals(-1));
      expect(Segment.compare(seg2, seg1), equals(1));
    });

    test('segments with identical geometry but different ring ids', () {
      final ring1 = dummyRing();
      final ring2 = dummyRing();
      final seg1 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
        ring1,
      );
      final seg2 = Segment.fromRing(
        Point(x: Decimal.zero, y: Decimal.zero),
        Point(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
        ring2,
      );

      expect(Segment.compare(seg1, seg2), equals(-1));
      expect(Segment.compare(seg2, seg1), equals(1));
    });

    test('segment consistency from issue #60', () {
      final seg1 = Segment.fromRing(
        Point(
            x: Decimal.parse('-131.57153657554915'),
            y: Decimal.parse('55.01963125')),
        Point(x: Decimal.parse('-131.571478'), y: Decimal.parse('55.0187174')),
        dummyRing(),
      );
      final seg2 = Segment.fromRing(
        Point(
            x: Decimal.parse('-131.57153657554915'),
            y: Decimal.parse('55.01963125')),
        Point(
            x: Decimal.parse('-131.57152375603846'),
            y: Decimal.parse('55.01943125')),
        dummyRing(),
      );

      expect(Segment.compare(seg1, seg2), equals(-1));
      expect(Segment.compare(seg2, seg1), equals(1));
    });

    test('transitivity: seg2 < seg6 < seg4 implies seg2 < seg4', () {
      final seg2 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000018'), y: Decimal.parse('-9.17')),
        Point(
            x: Decimal.parse('-10.000000000000004'), y: Decimal.parse('-8.79')),
        dummyRing(),
      );
      final seg6 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000016'), y: Decimal.parse('1.44')),
        Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5')),
        dummyRing(),
      );
      final seg4 = Segment.fromRing(
        Point(x: Decimal.parse('-10.00000000000001'), y: Decimal.parse('1.75')),
        Point(x: Decimal.parse('-9'), y: Decimal.parse('1.5')),
        dummyRing(),
      );

      expect(Segment.compare(seg2, seg6), equals(-1));
      expect(Segment.compare(seg6, seg4), equals(-1));
      expect(Segment.compare(seg2, seg4), equals(-1));
    });

    test('transitivity #2 from issue #60', () {
      final seg1 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000002'),
            y: Decimal.parse('1.8181818181818183')),
        Point(x: Decimal.parse('-9.999999999999996'), y: Decimal.fromInt(-3)),
        dummyRing(),
      );
      final seg2 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000002'),
            y: Decimal.parse('1.8181818181818183')),
        Point(x: Decimal.zero, y: Decimal.zero),
        dummyRing(),
      );
      final seg3 = Segment.fromRing(
        Point(
            x: Decimal.parse('-10.000000000000002'),
            y: Decimal.parse('1.8181818181818183')),
        Point(x: Decimal.parse('-10.000000000000002'), y: Decimal.fromInt(2)),
        dummyRing(),
      );

      expect(Segment.compare(seg1, seg2), equals(-1));
      expect(Segment.compare(seg2, seg3), equals(-1));
      expect(Segment.compare(seg1, seg3), equals(-1));
    });
  });
}

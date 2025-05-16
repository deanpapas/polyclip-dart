import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

SweepEvent se(Point x) => SweepEvent(x, false);
Point pt(num x, num y) =>
    Point(x: Decimal.parse(x.toString()), y: Decimal.parse(y.toString()));

void main() {
  group('SweepEvent.compare', () {
    test('favor earlier x in point', () {
      final s1 = SweepEvent(pt(-5, 4), false);
      final s2 = SweepEvent(pt(5, 1), false);
      expect(SweepEvent.compare(s1, s2), -1);
      expect(SweepEvent.compare(s2, s1), 1);
    });

    test('then favor earlier y in point', () {
      final s1 = SweepEvent(pt(5, -4), false);
      final s2 = SweepEvent(pt(5, 4), false);
      expect(SweepEvent.compare(s1, s2), -1);
      expect(SweepEvent.compare(s2, s1), 1);
    });

    test('then favor right events over left', () {
      final seg1 = Segment.fromRing(pt(5, 4), pt(3, 2), FakeRingIn());
      final seg2 = Segment.fromRing(pt(5, 4), pt(6, 5), FakeRingIn());
      expect(SweepEvent.compare(seg1.rightSE, seg2.leftSE), -1);
      expect(SweepEvent.compare(seg2.leftSE, seg1.rightSE), 1);
    });

    test('then favor non-vertical segments for left events', () {
      final seg1 = Segment.fromRing(pt(3, 2), pt(3, 4), FakeRingIn());
      final seg2 = Segment.fromRing(pt(3, 2), pt(5, 4), FakeRingIn());
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), -1);
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), 1);
    });

    test('then favor vertical segments for right events', () {
      final seg1 = Segment.fromRing(pt(3, 4), pt(3, 2), FakeRingIn());
      final seg2 = Segment.fromRing(pt(3, 4), pt(1, 2), FakeRingIn());
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), -1);
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), 1);
    });

    test('then favor lower segment', () {
      final seg1 = Segment.fromRing(pt(0, 0), pt(4, 4), FakeRingIn());
      final seg2 = Segment.fromRing(pt(0, 0), pt(5, 6), FakeRingIn());
      expect(SweepEvent.compare(seg1.leftSE, seg2.rightSE), -1);
      expect(SweepEvent.compare(seg2.rightSE, seg1.leftSE), 1);
    });

    test('and favor barely lower segment', () {
      final seg1 = Segment.fromRing(pt(-75.725, 45.357),
          pt(-75.72484615384616, 45.35723076923077), FakeRingIn());
      final seg2 = Segment.fromRing(
          pt(-75.725, 45.357), pt(-75.723, 45.36), FakeRingIn());
      expect(SweepEvent.compare(seg1.leftSE, seg2.leftSE), 1);
      expect(SweepEvent.compare(seg2.leftSE, seg1.leftSE), -1);
    });

    test('then favor lower ring id', () {
      final ring1 = FakeRingIn.fromId(1);
      final ring2 = FakeRingIn.fromId(2);
      final seg1 = Segment.fromRing(pt(0, 0), pt(4, 4), ring1);
      final seg2 = Segment.fromRing(pt(0, 0), pt(5, 5), ring2);
      expect(SweepEvent.compare(seg1.leftSE, seg2.leftSE), -1);
      expect(SweepEvent.compare(seg2.leftSE, seg1.leftSE), 1);
    });

    test('identical equal', () {
      final s1 = SweepEvent(pt(0, 0), false);
      final s3 = SweepEvent(pt(3, 3), false);
      Segment(s1, s3, [FakeRingIn.fromId(1)], []);
      Segment(s1, s3, [FakeRingIn.fromId(1)], []);
      expect(SweepEvent.compare(s1, s1), 0);
    });

    test('totally equal but not identical events are consistent', () {
      final s1 = SweepEvent(pt(0, 0), false);
      final s2 = SweepEvent(pt(0, 0), false);
      final s3 = SweepEvent(pt(3, 3), false);
      Segment(s1, s3, [FakeRingIn.fromId(1)], [1]);
      Segment(s2, s3, [FakeRingIn.fromId(1)], [1]);
      final result = SweepEvent.compare(s1, s2);
      expect(SweepEvent.compare(s1, s2), result);
      expect(SweepEvent.compare(s2, s1), -result);
    });
  });

  group('SweepEvent constructor', () {
    test('events created from same point are already linked', () {
      final p1 = pt(0, 0);
      final s1 = SweepEvent(p1, false);
      final s2 = SweepEvent(p1, false);
      expect(identical(s1.point, p1), true);
      expect(identical(s1.point.events, s2.point.events), true);
    });
  });

  group('SweepEvent link', () {
    test('no linked events', () {
      final s1 = SweepEvent(pt(0, 0), false);
      expect(s1.point.events, [s1]);
      expect(s1.getAvailableLinkedEvents(), []);
    });

    test('link events already linked with others', () {
      final p1 = pt(1, 2);
      final p2 = pt(1, 2);
      final se1 = SweepEvent(p1, false);
      final se2 = SweepEvent(p1, false);
      final se3 = SweepEvent(p2, false);
      final se4 = SweepEvent(p2, false);

      Segment(se1, SweepEvent(pt(5, 5), false), null, []);
      Segment(se2, SweepEvent(pt(6, 6), false), null, []);
      Segment(se3, SweepEvent(pt(7, 7), false), null, []);
      Segment(se4, SweepEvent(pt(8, 8), false), null, []);
      se1.link(se3);

      expect(se1.point.events.length, 4);
      expect(se1.point, se2.point);
      expect(se1.point, se3.point);
      expect(se1.point, se4.point);
    });

    test('same event twice throws', () {
      final p1 = pt(0, 0);
      final s1 = SweepEvent(p1, false);
      final s2 = SweepEvent(p1, false);
      expect(() => s2.link(s1), throwsA(isA<StateError>()));
      expect(() => s1.link(s2), throwsA(isA<StateError>()));
    });

    test('unavailable linked events do not show up', () {
      final p1 = pt(0, 0);
      final se = SweepEvent(p1, false);
      SweepEvent(p1, false)
        ..segment = FakeSegment(isInResult: false, ringOut: null);
      expect(se.getAvailableLinkedEvents(), []);
    });

    test('available linked events show up', () {
      final p1 = pt(0, 0);
      final se = SweepEvent(p1, false);
      final seOkay = SweepEvent(p1, false)
        ..segment = FakeSegment(isInResult: true, ringOut: null);
      expect(se.getAvailableLinkedEvents(), [seOkay]);
    });

    test('link goes both ways', () {
      final p1 = pt(0, 0);
      final seOkay1 = SweepEvent(p1, false)
        ..segment = FakeSegment(isInResult: true, ringOut: null);
      final seOkay2 = SweepEvent(p1, false)
        ..segment = FakeSegment(isInResult: true, ringOut: null);
      expect(seOkay1.getAvailableLinkedEvents(), [seOkay2]);
      expect(seOkay2.getAvailableLinkedEvents(), [seOkay1]);
    });
  });

  group('SweepEvent.getLeftmostComparator', () {
    test('after a segment straight to the right', () {
      final prev = SweepEvent(pt(0, 0), false);
      final base = SweepEvent(pt(1, 0), false);
      final comparator = base.getLeftmostComparator(prev);

      final e1 = SweepEvent(pt(1, 0), false);
      Segment(e1, SweepEvent(pt(0, 1), false), null, []);

      final e2 = SweepEvent(pt(1, 0), false);
      Segment(e2, SweepEvent(pt(1, 1), false), null, []);

      final e3 = SweepEvent(pt(1, 0), false);
      Segment(e3, SweepEvent(pt(2, 0), false), null, []);

      final e4 = SweepEvent(pt(1, 0), false);
      Segment(e4, SweepEvent(pt(1, -1), false), null, []);

      final e5 = SweepEvent(pt(1, 0), false);
      Segment(e5, SweepEvent(pt(0, -1), false), null, []);

      expect(comparator(e1, e2), -1);
      expect(comparator(e2, e3), -1);
      expect(comparator(e3, e4), -1);
      expect(comparator(e4, e5), -1);

      expect(comparator(e2, e1), 1);
      expect(comparator(e3, e2), 1);
      expect(comparator(e4, e3), 1);
      expect(comparator(e5, e4), 1);

      expect(comparator(e1, e3), -1);
      expect(comparator(e1, e4), -1);
      expect(comparator(e1, e5), -1);

      expect(comparator(e1, e1), 0);
    });

    test('after a down and to the left', () {
      final prev = SweepEvent(pt(1, 1), false);
      final base = SweepEvent(pt(0, 0), false);
      final comparator = base.getLeftmostComparator(prev);

      final e1 = SweepEvent(pt(0, 0), false);
      Segment(e1, SweepEvent(pt(0, 1), false), null, []);

      final e2 = SweepEvent(pt(0, 0), false);
      Segment(e2, SweepEvent(pt(1, 0), false), null, []);

      final e3 = SweepEvent(pt(0, 0), false);
      Segment(e3, SweepEvent(pt(0, -1), false), null, []);

      final e4 = SweepEvent(pt(0, 0), false);
      Segment(e4, SweepEvent(pt(-1, 0), false), null, []);

      expect(comparator(e1, e2), 1);
      expect(comparator(e1, e3), 1);
      expect(comparator(e1, e4), 1);

      expect(comparator(e2, e1), -1);
      expect(comparator(e2, e3), -1);
      expect(comparator(e2, e4), -1);

      expect(comparator(e3, e1), -1);
      expect(comparator(e3, e2), 1);
      expect(comparator(e3, e4), -1);

      expect(comparator(e4, e1), -1);
      expect(comparator(e4, e2), 1);
      expect(comparator(e4, e3), 1);
    });
  });
}

class FakeRingIn extends RingIn {
  FakeRingIn()
      : super(
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.0],
          ],
          PolyIn(
              Poly([
                [
                  [0.0, 0.0],
                  [1.0, 0.0],
                  [1.0, 1.0],
                  [0.0, 1.0],
                  [0.0, 0.0],
                ]
              ]),
              MultiPolyIn(
                  Poly([
                    [
                      [0.0, 0.0],
                      [1.0, 0.0],
                      [1.0, 1.0],
                      [0.0, 1.0],
                      [0.0, 0.0],
                    ]
                  ]),
                  true)),
          true,
        );

  static RingIn fromId(int id) {
    // Return a dummy RingIn for testing purposes
    return FakeRingIn();
  }
}

class FakeSegment implements Segment {
  final bool _inResult;
  @override
  final RingOut? ringOut;

  FakeSegment({required bool isInResult, required this.ringOut})
      : _inResult = isInResult;

  @override
  bool isInResult() => _inResult;

  // Stub the rest if needed for tests
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

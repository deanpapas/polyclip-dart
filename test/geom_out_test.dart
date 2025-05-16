import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/polyclip.dart';

void main() {
  Decimal d(num n) => Decimal.parse(n.toString());
  Point pt(num x, num y) => Point(x: d(x), y: d(y));

  RingIn createTestRing() {
    // Create a simple polygon for testing with proper List<double> types
    final ring = <List<double>>[
      <double>[0.0, 0.0],
      <double>[1.0, 1.0],
      <double>[0.0, 0.0]
    ];
    final poly = Poly([ring]);
    final multiPoly = MultiPolyIn(poly, true);
    return multiPoly.polys.first.exteriorRing;
  }

  Segment seg(Point p1, Point p2) => Segment.fromRing(p1, p2, createTestRing());

  group('RingOut.factory', () {
    test('simple triangle', () {
      final p1 = pt(0, 0);
      final p2 = pt(1, 1);
      final p3 = pt(0, 1);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p1)..setInResult(true);

      final rings = RingOut.factory([s1, s2, s3]);
      expect(rings.length, 1);
      expect(rings[0].getGeom(), [
        [0, 0],
        [1, 1],
        [0, 1],
        [0, 0]
      ]);
    });

    test('bow tie', () {
      final p1 = pt(0, 0);
      final p2 = pt(1, 1);
      final p3 = pt(0, 2);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p1)..setInResult(true);

      final p4 = pt(2, 0);
      final p5 = p2;
      final p6 = pt(2, 2);

      final s4 = seg(p4, p5)..setInResult(true);
      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p4)..setInResult(true);

      final rings = RingOut.factory([s1, s2, s3, s4, s5, s6]);
      expect(rings.length, 2);
      expect(rings[0].getGeom(), [
        [0, 0],
        [1, 1],
        [0, 2],
        [0, 0]
      ]);
      expect(rings[1].getGeom(), [
        [1, 1],
        [2, 0],
        [2, 2],
        [1, 1]
      ]);
    });

    test('ringed ring', () {
      final p1 = pt(0, 0);
      final p2 = pt(3, -3);
      final p3 = pt(3, 0);
      final p4 = pt(3, 3);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p4)..setInResult(true);
      final s4 = seg(p4, p1)..setInResult(true);

      final p5 = pt(2, -1);
      final p6 = p3;
      final p7 = pt(2, 1);

      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p7)..setInResult(true);
      final s7 = seg(p7, p5)..setInResult(true);

      final rings = RingOut.factory([s1, s2, s3, s4, s5, s6, s7]);
      expect(rings.length, 2);
      expect(rings[0].getGeom(), [
        [3, 0],
        [2, 1],
        [2, -1],
        [3, 0]
      ]);
      expect(rings[1].getGeom(), [
        [0, 0],
        [3, -3],
        [3, 3],
        [0, 0]
      ]);
    });

    test('ringed ring interior ring starting point extraneous', () {
      final p1 = pt(0, 0);
      final p2 = pt(5, -5);
      final p3 = pt(4, 0);
      final p4 = pt(5, 5);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p4)..setInResult(true);
      final s4 = seg(p4, p1)..setInResult(true);

      final p5 = pt(1, 0);
      final p6 = pt(4, 1);
      final p7 = p3;
      final p8 = pt(4, -1);

      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p7)..setInResult(true);
      final s7 = seg(p7, p8)..setInResult(true);
      final s8 = seg(p8, p5)..setInResult(true);

      final segs = [s1, s2, s3, s4, s5, s6, s7, s8];
      final rings = RingOut.factory(segs);

      expect(rings.length, 2);
      expect(rings[0].getGeom(), [
        [4, 1],
        [1, 0],
        [4, -1],
        [4, 1]
      ]);
      expect(rings[1].getGeom(), [
        [0, 0],
        [5, -5],
        [4, 0],
        [5, 5],
        [0, 0]
      ]);
    });

    test('ringed ring and bow tie at same point', () {
      final p1 = pt(0, 0);
      final p2 = pt(3, -3);
      final p3 = pt(3, 0);
      final p4 = pt(3, 3);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p4)..setInResult(true);
      final s4 = seg(p4, p1)..setInResult(true);

      final p5 = pt(2, -1);
      final p6 = p3;
      final p7 = pt(2, 1);

      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p7)..setInResult(true);
      final s7 = seg(p7, p5)..setInResult(true);

      final p8 = p3;
      final p9 = pt(4, -1);
      final p10 = pt(4, 1);

      final s8 = seg(p8, p9)..setInResult(true);
      final s9 = seg(p9, p10)..setInResult(true);
      final s10 = seg(p10, p8)..setInResult(true);

      final segs = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10];
      final rings = RingOut.factory(segs);

      expect(rings.length, 3);
      expect(rings[0].getGeom(), [
        [3, 0],
        [2, 1],
        [2, -1],
        [3, 0]
      ]);
      expect(rings[1].getGeom(), [
        [0, 0],
        [3, -3],
        [3, 3],
        [0, 0]
      ]);
      expect(rings[2].getGeom(), [
        [3, 0],
        [4, -1],
        [4, 1],
        [3, 0]
      ]);
    });

    test('double bow tie', () {
      final p1 = pt(0, 0);
      final p2 = pt(1, -2);
      final p3 = pt(1, 2);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p1)..setInResult(true);

      final p4 = p2;
      final p5 = pt(2, -3);
      final p6 = pt(2, -1);

      final s4 = seg(p4, p5)..setInResult(true);
      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p4)..setInResult(true);

      final p7 = p3;
      final p8 = pt(2, 1);
      final p9 = pt(2, 3);

      final s7 = seg(p7, p8)..setInResult(true);
      final s8 = seg(p8, p9)..setInResult(true);
      final s9 = seg(p9, p7)..setInResult(true);

      final segs = [s1, s2, s3, s4, s5, s6, s7, s8, s9];
      final rings = RingOut.factory(segs);

      expect(rings.length, 3);
      expect(rings[0].getGeom(), [
        [0, 0],
        [1, -2],
        [1, 2],
        [0, 0]
      ]);
      expect(rings[1].getGeom(), [
        [1, -2],
        [2, -3],
        [2, -1],
        [1, -2]
      ]);
      expect(rings[2].getGeom(), [
        [1, 2],
        [2, 1],
        [2, 3],
        [1, 2]
      ]);
    });

    test('double ringed ring', () {
      final p1 = pt(0, 0);
      final p2 = pt(5, -5);
      final p3 = pt(5, 5);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p1)..setInResult(true);

      final p4 = pt(1, 0);
      final p5 = pt(4, 1);
      final p6 = pt(4, -1);

      final s4 = seg(p4, p5)..setInResult(true);
      final s5 = seg(p5, p6)..setInResult(true);
      final s6 = seg(p6, p4)..setInResult(true);

      final p7 = pt(1, 0);
      final p8 = pt(4, 1);
      final p9 = pt(4, -1);

      final s7 = seg(p7, p8)..setInResult(true);
      final s8 = seg(p8, p9)..setInResult(true);
      final s9 = seg(p9, p7)..setInResult(true);

      final segs = [s1, s2, s3, s4, s5, s6, s7, s8, s9];
      final rings = RingOut.factory(segs);

      expect(rings.length, 3);
      expect(rings[0].getGeom(), [
        [0, 0],
        [5, -5],
        [5, 5],
        [0, 0]
      ]);
      expect(rings[1].getGeom(), [
        [1, 0],
        [4, 1],
        [4, -1],
        [1, 0]
      ]);
      expect(rings[2].getGeom(), [
        [1, 0],
        [4, 1],
        [4, -1],
        [1, 0]
      ]);
    });

    test('errors on malformed ring', () {
      final p1 = pt(0, 0);
      final p2 = pt(1, 1);
      final p3 = pt(0, 1);

      final s1 = seg(p1, p2)..setInResult(true);
      final s2 = seg(p2, p3)..setInResult(true);
      final s3 = seg(p3, p1);
      s3.setInResult(false); // broken ring

      expect(() => RingOut.factory([s1, s2, s3]), throwsA(isA<Exception>()));
    });
  });

  test('exterior ring', () {
    final p1 = pt(0, 0);
    final p2 = pt(1, 1);
    final p3 = pt(0, 1);

    final s1 = seg(p1, p2)..setInResult(true);
    final s2 = seg(p2, p3)..setInResult(true);
    final s3 = seg(p3, p1)..setInResult(true);

    final ring = RingOut.factory([s1, s2, s3])[0];

    expect(ring.enclosingRing(), isNull);
    expect(ring.isExteriorRing(), isTrue);
    expect(ring.getGeom(), [
      [0, 0],
      [1, 1],
      [0, 1],
      [0, 0]
    ]);
  });

  test('interior ring points reversed', () {
    final p1 = pt(0, 0);
    final p2 = pt(1, 1);
    final p3 = pt(0, 1);

    final s1 = seg(p1, p2)..setInResult(true);
    final s2 = seg(p2, p3)..setInResult(true);
    final s3 = seg(p3, p1)..setInResult(true);

    final ring = RingOut.factory([s1, s2, s3])[0];
    ring.setInterior(); // using the extension above

    expect(ring.isExteriorRing(), isFalse);
    expect(ring.getGeom(), [
      [0, 0],
      [0, 1],
      [1, 1],
      [0, 0]
    ]);
  });

  test('removes colinear points successfully', () {
    final p1 = pt(0, 0);
    final p2 = pt(1, 1);
    final p3 = pt(2, 2);
    final p4 = pt(0, 2);

    final s1 = seg(p1, p2)..setInResult(true);
    final s2 = seg(p2, p3)..setInResult(true);
    final s3 = seg(p3, p4)..setInResult(true);
    final s4 = seg(p4, p1)..setInResult(true);

    final ring = RingOut.factory([s1, s2, s3, s4])[0];

    expect(ring.getGeom(), [
      [0, 0],
      [2, 2],
      [0, 2],
      [0, 0]
    ]);
  });

  test('almost equal point handled ok', () {
    precision.set(1e-8);

    final p1 = pt(0.523985, 51.281651);
    final p2 = pt(0.5241, 51.2816);
    final p3 = pt(0.5240213684210527, 51.281687368421);
    final p4 = pt(0.5239850000000027, 51.281651000000004);

    final s1 = seg(p1, p2)..setInResult(true);
    final s2 = seg(p2, p3)..setInResult(true);
    final s3 = seg(p3, p4)..setInResult(true);
    final s4 = seg(p4, p1)..setInResult(true);

    final ring = RingOut.factory([s1, s2, s3, s4])[0];

    expect(ring.getGeom(), [
      [0.523985, 51.281651],
      [0.5241, 51.2816],
      [0.5240213684210527, 51.281687368421],
      [0.523985, 51.281651]
    ]);

    precision.set();
  });

  test('ring with all colinear points returns null', () {
    final p1 = pt(0, 0);
    final p2 = pt(1, 1);
    final p3 = pt(2, 2);
    final p4 = pt(3, 3);

    final s1 = seg(p1, p2)..setInResult(true);
    final s2 = seg(p2, p3)..setInResult(true);
    final s3 = seg(p3, p4)..setInResult(true);
    final s4 = seg(p4, p1)..setInResult(true);

    final ring = RingOut.factory([s1, s2, s3, s4])[0];

    expect(ring.getGeom(), isNull);
  });

  group('PolyOut', () {
    test('basic', () {
      final ring1 = RingOut.mockWithGeom(1);
      final ring2 = RingOut.mockWithGeom(2);
      final ring3 = RingOut.mockWithGeom(3);

      final poly = PolyOut(ring1);
      poly.addInterior(ring2);
      poly.addInterior(ring3);

      expect(ring1.poly, same(poly));
      expect(ring2.poly, same(poly));
      expect(ring3.poly, same(poly));

      expect(poly.getGeom(), [1, 2, 3]);
    });

    test('has all colinear exterior ring', () {
      final ring1 = RingOut.mockWithGeom(null);
      final poly = PolyOut(ring1);

      expect(ring1.poly, same(poly));
      expect(poly.getGeom(), isNull);
    });

    test('has all colinear interior ring', () {
      final ring1 = RingOut.mockWithGeom(1);
      final ring2 = RingOut.mockWithGeom(null);
      final ring3 = RingOut.mockWithGeom(3);

      final poly = PolyOut(ring1);
      poly.addInterior(ring2);
      poly.addInterior(ring3);

      expect(ring1.poly, same(poly));
      expect(ring2.poly, same(poly));
      expect(ring3.poly, same(poly));

      expect(poly.getGeom(), [1, 3]);
    });
  });

  group('MultiPolyOut', () {
    test('basic', () {
      final mp = MultiPolyOut([]);
      final poly1 = PolyOut.mockWithGeom(0);
      final poly2 = PolyOut.mockWithGeom(1);
      mp.polys = [poly1, poly2];

      expect(mp.getGeom(), [0, 1]);
    });

    test('has poly with all colinear exterior ring', () {
      final mp = MultiPolyOut([]);
      final poly1 = PolyOut.mockWithGeom(null);
      final poly2 = PolyOut.mockWithGeom(1);
      mp.polys = [poly1, poly2];

      expect(mp.getGeom(), [1]);
    });
  });
}

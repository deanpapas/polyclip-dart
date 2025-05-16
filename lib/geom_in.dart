import 'package:decimal/decimal.dart';
import 'bbox.dart';
import 'precision.dart';
import 'segment.dart';
import 'sweep_event.dart';

typedef Ring = List<List<double>>;

sealed class Geom {}

class Poly extends Geom {
  final List<Ring> rings;
  Poly(this.rings);
}

class MultiPoly extends Geom {
  final List<Poly> polygons;
  MultiPoly(this.polygons);
}

final Decimal maxDecimal = Decimal.parse('1e50');
final Decimal minDecimal = -maxDecimal;

class RingIn {
  final PolyIn poly;
  final bool isExterior;
  final List<Segment> segments = [];
  late Bbox bbox;

  RingIn(Ring geomRing, this.poly, this.isExterior) {
    if (geomRing.isEmpty || geomRing[0].length != 2) {
      throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    final firstPoint = precision.snap(Point(
      x: Decimal.parse(geomRing[0][0].toString()),
      y: Decimal.parse(geomRing[0][1].toString()),
    ));

    bbox = Bbox(
      ll: Point(x: firstPoint.x, y: firstPoint.y),
      ur: Point(x: firstPoint.x, y: firstPoint.y),
    );

    Point prevPoint = firstPoint;
    for (int i = 1; i < geomRing.length; i++) {
      if (geomRing[i].length != 2) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
      }

      final point = precision.snap(Point(
        x: Decimal.parse(geomRing[i][0].toString()),
        y: Decimal.parse(geomRing[i][1].toString()),
      ));

      if (point.x == prevPoint.x && point.y == prevPoint.y) continue;

      segments.add(Segment.fromRing(prevPoint, point, this));
      _updateBBoxWith(point);

      prevPoint = point;
    }

    if (prevPoint.x != firstPoint.x || prevPoint.y != firstPoint.y) {
      segments.add(Segment.fromRing(prevPoint, firstPoint, this));
    }
  }

  void _updateBBoxWith(Point p) {
    if (p.x < bbox.ll.x) bbox.llx = p.x;
    if (p.y < bbox.ll.y) bbox.lly = p.y;
    if (p.x > bbox.ur.x) bbox.urx = p.x;
    if (p.y > bbox.ur.y) bbox.ury = p.y;
  }

  List<SweepEvent> getSweepEvents() {
    final sweepEvents = <SweepEvent>[];
    for (final segment in segments) {
      sweepEvents.add(segment.leftSE);
      sweepEvents.add(segment.rightSE);
    }
    return sweepEvents;
  }
}

class PolyIn {
  late MultiPolyIn multiPoly;
  late RingIn exteriorRing;
  final List<RingIn> interiorRings = [];
  late Bbox bbox;

  PolyIn(Poly geomPoly, MultiPolyIn multiPoly) {
    this.multiPoly = multiPoly;

    if (geomPoly.rings.isEmpty) {
      throw ArgumentError("Input polygon has no rings");
    }

    exteriorRing = RingIn(geomPoly.rings[0], this, true);
    bbox = Bbox(
      ll: Point(x: exteriorRing.bbox.ll.x, y: exteriorRing.bbox.ll.y),
      ur: Point(x: exteriorRing.bbox.ur.x, y: exteriorRing.bbox.ur.y),
    );

    for (int i = 1; i < geomPoly.rings.length; i++) {
      final ring = RingIn(geomPoly.rings[i], this, false);
      _updateBBoxWith(ring.bbox);
      interiorRings.add(ring);
    }
  }

  void _updateBBoxWith(Bbox other) {
    if (other.ll.x < bbox.ll.x) bbox.llx = other.ll.x;
    if (other.ll.y < bbox.ll.y) bbox.lly = other.ll.y;
    if (other.ur.x > bbox.ur.x) bbox.urx = other.ur.x;
    if (other.ur.y > bbox.ur.y) bbox.ury = other.ur.y;
  }

  List<SweepEvent> getSweepEvents() {
    final sweepEvents = exteriorRing.getSweepEvents();
    for (final ring in interiorRings) {
      sweepEvents.addAll(ring.getSweepEvents());
    }
    return sweepEvents;
  }
}

class MultiPolyIn {
  final bool isSubject;
  final List<PolyIn> polys = [];
  final Bbox bbox = Bbox(
    ll: Point(x: maxDecimal, y: maxDecimal),
    ur: Point(x: minDecimal, y: minDecimal),
  );

  MultiPolyIn(Geom geom, this.isSubject) {
    final geomPolys = switch (geom) {
      Poly p => [p],
      MultiPoly mp => mp.polygons,
    };

    for (final polyGeom in geomPolys) {
      final poly = PolyIn(polyGeom, this);
      _updateBBoxWith(poly.bbox);
      polys.add(poly);
    }
  }

  void _updateBBoxWith(Bbox other) {
    if (other.ll.x < bbox.ll.x) bbox.llx = other.ll.x;
    if (other.ll.y < bbox.ll.y) bbox.lly = other.ll.y;
    if (other.ur.x > bbox.ur.x) bbox.urx = other.ur.x;
    if (other.ur.y > bbox.ur.y) bbox.ury = other.ur.y;
  }

  List<SweepEvent> getSweepEvents() {
    final sweepEvents = <SweepEvent>[];
    for (final poly in polys) {
      sweepEvents.addAll(poly.getSweepEvents());
    }
    return sweepEvents;
  }
}

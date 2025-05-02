import 'package:decimal/decimal.dart';
import 'polyclipbbox.dart';
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

class RingIn {
  final PolyIn poly;
  final bool isExterior;
  final List<Segment> segments = [];
  late PolyclipBBox bbox;

  RingIn(Ring geomRing, this.poly, this.isExterior) {
    if (geomRing.isEmpty) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    if (geomRing[0].length != 2) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    final firstPoint = precision.snap(Point(
      x: Decimal.parse(geomRing[0][0].toString()),
      y: Decimal.parse(geomRing[0][1].toString()),
    )) as Point;
    bbox = PolyclipBBox(
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
      )) as Point;

      // Skip repeated points
      if (point.x == prevPoint.x && point.y == prevPoint.y) {
        continue;
      }

      segments.add(Segment.fromRing(prevPoint, point, this));

      // Update bounding box
      if (point.x < bbox.ll.x) bbox.llx = point.x;
      if (point.y < bbox.ll.y) bbox.lly = point.y;
      if (point.x > bbox.ur.x) bbox.urx = point.x;
      if (point.y > bbox.ur.y) bbox.ury = point.y;

      prevPoint = point;
    }

    // Add segment from last to first if the last point is not the same as the first
    if (prevPoint.x != firstPoint.x || prevPoint.y != firstPoint.y) {
      segments.add(Segment.fromRing(prevPoint, firstPoint, this));
    }
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
  late PolyclipBBox bbox;

  PolyIn(Poly geomPoly, MultiPolyIn multiPoly) {
    this.multiPoly = multiPoly;
    
    if (geomPoly.rings.isEmpty) {
      throw ArgumentError("Input polygon has no rings");
    }

    this.exteriorRing = RingIn(geomPoly.rings[0], this, true);

    // Copy by value
    bbox = PolyclipBBox(
      ll: Point(x: exteriorRing.bbox.ll.x, y: exteriorRing.bbox.ll.y),
      ur: Point(x: exteriorRing.bbox.ur.x, y: exteriorRing.bbox.ur.y),
    );

    for (int i = 1; i < geomPoly.rings.length; i++) {
      final ring = RingIn(geomPoly.rings[i], this, false);
      if (ring.bbox.ll.x < bbox.ll.x) bbox.llx = ring.bbox.ll.x;
      if (ring.bbox.ll.y < bbox.ll.y) bbox.lly = ring.bbox.ll.y;
      if (ring.bbox.ur.x > bbox.ur.x) bbox.urx = ring.bbox.ur.x;
      if (ring.bbox.ur.y > bbox.ur.y) bbox.ury = ring.bbox.ur.y;

      interiorRings.add(ring);
    }
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
  final PolyclipBBox bbox = PolyclipBBox(
    ll: Point(x: Decimal.fromInt(-999999999), y: Decimal.fromInt(-999999999)),
    ur: Point(x: Decimal.fromInt(999999999), y: Decimal.fromInt(999999999)),
  );

  MultiPolyIn(Geom geom, this.isSubject) {
    if (geom is Poly) {
      // Handle single polygon case
      final poly = PolyIn(geom, this);
      if (poly.bbox.ll.x < bbox.ll.x) bbox.llx = poly.bbox.ll.x;
      if (poly.bbox.ll.y < bbox.ll.y) bbox.lly = poly.bbox.ll.y;
      if (poly.bbox.ur.x > bbox.ur.x) bbox.urx = poly.bbox.ur.x;
      if (poly.bbox.ur.y > bbox.ur.y) bbox.ury = poly.bbox.ur.y;
      polys.add(poly);
    } else if (geom is MultiPoly) {
      // Handle multipoly case
      for (final polyGeom in geom.polygons) {
        final poly = PolyIn(polyGeom, this);
        if (poly.bbox.ll.x < bbox.ll.x) bbox.llx = poly.bbox.ll.x;
        if (poly.bbox.ll.y < bbox.ll.y) bbox.lly = poly.bbox.ll.y;
        if (poly.bbox.ur.x > bbox.ur.x) bbox.urx = poly.bbox.ur.x;
        if (poly.bbox.ur.y > bbox.ur.y) bbox.ury = poly.bbox.ur.y;
        polys.add(poly);
      }
    } else {
      throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }
  }

  List<SweepEvent> getSweepEvents() {
    final sweepEvents = <SweepEvent>[];
    for (final poly in polys) {
      sweepEvents.addAll(poly.getSweepEvents());
    }
    return sweepEvents;
  }
}
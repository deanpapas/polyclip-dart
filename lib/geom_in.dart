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

class RingIn {
  final PolyIn poly;
  final bool isExterior;
  final List<Segment> segments = [];
  late Bbox bbox;

  RingIn(Ring geomRing, this.poly, this.isExterior) {
    if (geomRing is! List || geomRing.isEmpty) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    if (geomRing[0].length != 2 || geomRing[0][0] is! double || geomRing[0][1] is! double) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    this.poly = poly;
    this.isExterior = isExterior;
    this.segments = [];

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
      if (geomRing[i].length != 2 ||
          geomRing[i][0] is! double ||
          geomRing[i][1] is! double) {
        throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
      }

      final point = precision.snap(Point(
        x: Decimal.parse(geomRing[i][0].toString()),
        y: Decimal.parse(geomRing[i][1].toString()),
      ));

      // Skip repeated points
      if (point.x == prevPoint.x && point.y == prevPoint.y) {
        continue;
      }

      segments.add(Segment.fromRing(prevPoint, point, this));

      // Update bounding box
      if (point.x < bbox.ll.x) bbox.ll.x = point.x;
      if (point.y < bbox.ll.y) bbox.ll.y = point.y;
      if (point.x > bbox.ur.x) bbox.ur.x = point.x;
      if (point.y > bbox.ur.y) bbox.ur.y = point.y;

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
  late Bbox bbox;

  PolyIn(Poly geomPoly, MultiPolyIn multiPoly) {
    if (geomPoly is! List) {
      throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    this.exteriorRing = RingIn(geomPoly[0], this, true);

    // Copy by value
    bbox = Bbox(
      ll: Point(x: exteriorRing.bbox.ll.x, y: exteriorRing.bbox.ll.y),
      ur: Point(x: exteriorRing.bbox.ur.x, y: exteriorRing.bbox.ur.y),
    );

    for (int i = 1; i < geomPoly.length; i++) {
      final ring = RingIn(geomPoly[i], this, false);
      if (ring.bbox.ll.x < bbox.ll.x) bbox.ll.x = ring.bbox.ll.x;
      if (ring.bbox.ll.y < bbox.ll.y) bbox.ll.y = ring.bbox.ll.y;
      if (ring.bbox.ur.x > bbox.ur.x) bbox.ur.x = ring.bbox.ur.x;
      if (ring.bbox.ur.y > bbox.ur.y) bbox.ur.y = ring.bbox.ur.y;

      interiorRings.add(ring);
    }

    this.multiPoly = multiPoly;
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
    ll: Point(x: Decimal.parse(double.infinity.toString()), y: Decimal.parse(double.infinity.toString())),
    ur: Point(x: Decimal.parse(double.negativeInfinity.toString()), y: Decimal.parse(double.negativeInfinity.toString())),
  );

  MultiPolyIn(Geom geom, this.isSubject) {
    if (geom is! List) {
      throw ArgumentError("Input geometry is not a valid Polygon or MultiPolygon");
    }

    try {
      // If input looks like a polygon, convert it to a multipolygon
      if (geom[0][0][0] is double) {
        geom = [geom as Poly];
      }
    } catch (ex) {
      // Handle malformed input or empty arrays
    }

    for (final polyGeom in geom) {
      final poly = PolyIn(polyGeom as Poly, this);
      if (poly.bbox.ll.x < bbox.ll.x) bbox.ll.x = poly.bbox.ll.x;
      if (poly.bbox.ll.y < bbox.ll.y) bbox.ll.y = poly.bbox.ll.y;
      if (poly.bbox.ur.x > bbox.ur.x) bbox.ur.x = poly.bbox.ur.x;
      if (poly.bbox.ur.y > bbox.ur.y) bbox.ur.y = poly.bbox.ur.y;

      polys.add(poly);
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
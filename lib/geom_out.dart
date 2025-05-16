import 'geom_in.dart';
import 'precision.dart';
import 'segment.dart';
import 'sweep_event.dart';
import 'package:meta/meta.dart';

class RingOut {
  List<SweepEvent> events;
  PolyOut? poly;
  bool? _isExteriorRing;
  RingOut? _enclosingRing;
  dynamic _mockGeom;

  RingOut(this.events) {
    for (final event in events) {
      event.segment.ringOut = this;
    }
    poly = null;
  }

  static List<RingOut> factory(List<Segment> allSegments) {
    final ringsOut = <RingOut>[];

    for (final segment in allSegments) {
      if (!segment.isInResult() || segment.ringOut != null) continue;

      final events = <SweepEvent>[];
      final intersectionLEs = <Map<String, dynamic>>[];

      SweepEvent? prevEvent;
      var event = segment.leftSE;
      var nextEvent = segment.rightSE;
      events.add(event);

      final startingPoint = event.point;

      while (true) {
        prevEvent = event;
        event = nextEvent;
        events.add(event);

        if (event.point == startingPoint) break;      while (true) {
        final availableLEs = event.getAvailableLinkedEvents();
        
        if (availableLEs.isEmpty) {
          // Check if we've reached the starting point but slightly offset due to precision
          if (precision.arePointsEqual(event.point, startingPoint)) {
            break; // Ring is complete, just with slight precision differences
          }
          
          // Otherwise, look for a nearby linked event that could complete the ring
          final nearbyEvents = event.point.events.where((e) => 
            e != event && 
            e.segment.ringOut == null &&
            e.segment.isInResult() &&
            precision.arePointsNearlyEqual(e.point, startingPoint));
            
          if (nearbyEvents.isNotEmpty) {
            nextEvent = nearbyEvents.first;
            break;
          }
          
          final firstPt = events.first.point;
          final lastPt = events.last.point;
          throw Exception(
            'Unable to complete output ring starting at [${firstPt.x}, ${firstPt.y}]. '
            'Last matching segment found ends at [${lastPt.x}, ${lastPt.y}].',
          );
        }

        if (availableLEs.length == 1) {
          nextEvent = availableLEs.first.otherSE;
          break;
        }

        final indexLE = intersectionLEs.indexWhere((e) => precision.arePointsEqual(e['point'], event.point));
          if (indexLE != -1) {
            final intersectionLE = intersectionLEs.removeAt(indexLE);
            final ringEvents = events.sublist(intersectionLE['index']);
            events.removeRange(intersectionLE['index'], events.length);
            ringEvents.insert(0, ringEvents.first.otherSE);
            ringsOut.add(RingOut(ringEvents.reversed.toList()));
            continue;
          }

          intersectionLEs.add({
            'index': events.length,
            'point': event.point,
          });

          final comparator = event.getLeftmostComparator(prevEvent);
          availableLEs.sort(comparator);
          nextEvent = availableLEs.first.otherSE;
          break;
        }
      }

      ringsOut.add(RingOut(events));
    }

    return ringsOut;
  }

  @visibleForTesting
  static RingOut mockWithGeom(dynamic geom) {
    final ring = RingOut([]);
    ring._mockGeom = geom;
    return ring;
  }

  dynamic getGeom() {
    if (_mockGeom != null) return _mockGeom;
    if (events.isEmpty) return null;

    var prevPt = events[0].point;
    final points = [prevPt];

    for (int i = 1; i < events.length - 1; i++) {
      final pt = events[i].point;
      final nextPt = events[i + 1].point;
      if (precision.orient(pt, prevPt, nextPt) == 0) continue;
      points.add(pt);
      prevPt = pt;
    }

    if (points.length == 1) return null;

    final first = points.first;
    final second = points.length > 1 ? points[1] : null;
    if (second != null &&
        precision.orient(first, points.last, second) == 0) {
      points.removeAt(0);
    }

    points.add(points[0]);

    final orderedPoints = <List<double>>[];
    final isExterior = isExteriorRing();
    final step = isExterior ? 1 : -1;
    final iStart = isExterior ? 0 : points.length - 1;
    final iEnd = isExterior ? points.length : -1;

    for (int i = iStart; i != iEnd; i += step) {
      orderedPoints.add([points[i].x.toDouble(), points[i].y.toDouble()]);
    }

    return orderedPoints;
  }

  bool isExteriorRing() {
    _isExteriorRing ??= enclosingRing() == null ? true : !enclosingRing()!.isExteriorRing();
    return _isExteriorRing!;
  }

  RingOut? enclosingRing() {
    _enclosingRing ??= _calcEnclosingRing();
    return _enclosingRing;
  }

  RingOut? _calcEnclosingRing() {
    var leftMostEvt = events[0];
    for (final evt in events.skip(1)) {
      if (SweepEvent.compare(leftMostEvt, evt) > 0) leftMostEvt = evt;
    }

    var prevSeg = leftMostEvt.segment.prevInResult();
    var prevPrevSeg = prevSeg?.prevInResult();

    while (true) {
      if (prevSeg == null) return null;
      if (prevPrevSeg == null) return prevSeg.ringOut;

      if (prevPrevSeg.ringOut != prevSeg.ringOut) {
        return prevPrevSeg.ringOut?.enclosingRing() != prevSeg.ringOut
            ? prevSeg.ringOut
            : prevSeg.ringOut?.enclosingRing();
      }

      prevSeg = prevPrevSeg.prevInResult();
      prevPrevSeg = prevSeg?.prevInResult();
    }
  }
}

class PolyOut {
  RingOut exteriorRing;
  List<RingOut> interiorRings = [];
  dynamic _mockGeom;

  PolyOut(this.exteriorRing) {
    exteriorRing.poly = this;
  }

  @visibleForTesting
  static PolyOut mockWithGeom(dynamic geom) {
    final mockRing = RingOut.mockWithGeom([]);
    final poly = PolyOut(mockRing);
    poly._mockGeom = geom;
    return poly;
  }

  void addInterior(RingOut ring) {
    interiorRings.add(ring);
    ring.poly = this;
  }

  dynamic getGeom() {
    if (_mockGeom != null) return _mockGeom;

    final outer = exteriorRing.getGeom();
    if (outer == null) return null;

    final rings = <List<List<double>>>[outer as List<List<double>>];
    for (final ring in interiorRings) {
      final inner = ring.getGeom();
      if (inner != null) rings.add(inner as List<List<double>>);
    }

    return Poly(rings);
  }
}

class MultiPolyOut {
  List<RingOut> rings;
  late final List<PolyOut> polys;

  MultiPolyOut(this.rings) {
    polys = _composePolys(rings);
  }

  dynamic getGeom() {
    final out = <dynamic>[];
    for (final poly in polys) {
      final geom = poly.getGeom();
      if (geom != null) out.add(geom);
    }
    return MultiPoly(out.cast<Poly>());
  }

  List<PolyOut> _composePolys(List<RingOut> rings) {
    final polys = <PolyOut>[];
    for (final ring in rings) {
      if (ring.poly != null) continue;
      if (ring.isExteriorRing()) {
        polys.add(PolyOut(ring));
      } else {
        final enclosing = ring.enclosingRing();
        if (enclosing != null) {
          if (enclosing.poly == null) polys.add(PolyOut(enclosing));
          enclosing.poly?.addInterior(ring);
        }
      }
    }
    return polys;
  }
}

extension RingOutTestHelper on RingOut {
  void setInterior() {
    _isExteriorRing = false;
  }
}

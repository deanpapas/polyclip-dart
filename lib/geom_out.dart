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

  /* Given the segments from the sweep line pass, compute & return a series
    * of closed rings from all the segments marked to be part of the result */
  static List<RingOut> factory(List<Segment> allSegments) {
    final ringsOut = <RingOut>[];

    for (int i = 0, iMax = allSegments.length; i < iMax; i++) {
      final segment = allSegments[i];
      if (!segment.isInResult() || segment.ringOut != null) continue;

      SweepEvent? prevEvent = null;
      SweepEvent event = segment.leftSE;
      SweepEvent nextEvent = segment.rightSE;
      final events = <SweepEvent>[event];

      final startingPoint = event.point;
      final intersectionLEs = <Map<String, dynamic>>[];

      /* Walk the chain of linked events to form a closed ring */
      while (true) {
        prevEvent = event;
        event = nextEvent;
        events.add(event);

        /* Is the ring complete? */
        if (event.point == startingPoint) break;

        while (true) {
          final availableLEs = event.getAvailableLinkedEvents();

          /* Did we hit a dead end? This shouldn't happen. Indicates some earlier
            * part of the algorithm malfunctioned... please file a bug report. */
          if (availableLEs.isEmpty) {
            final firstPt = events[0].point;
            final lastPt = events[events.length - 1].point;
            throw Exception(
              'Unable to complete output ring starting at [${firstPt.x},'
              ' ${firstPt.y}]. Last matching segment found ends at'
              ' [${lastPt.x}, ${lastPt.y}].',
            );
          }

          /* Only one way to go, so continue on the path */
          if (availableLEs.length == 1) {
            nextEvent = availableLEs[0].otherSE;
            break;
          }

          /* We must have an intersection. Check for a completed loop */
          int? indexLE = null;
          for (int j = 0, jMax = intersectionLEs.length; j < jMax; j++) {
            if (intersectionLEs[j]['point'] == event.point) {
              indexLE = j;
              break;
            }
          }
          /* Found a completed loop. Cut that off and make a ring */
          if (indexLE != null) {
            final intersectionLE = intersectionLEs.removeAt(indexLE);
            final ringEvents = events.sublist(intersectionLE['index']);
            events.removeRange(intersectionLE['index'], events.length);
            ringEvents.insert(0, ringEvents[0].otherSE);
            ringsOut.add(RingOut(ringEvents.reversed.toList()));
            continue;
          }
          /* register the intersection */
          intersectionLEs.add({
            'index': events.length,
            'point': event.point,
          });
          /* Choose the left-most option to continue the walk */
          final comparator = event.getLeftmostComparator(prevEvent);
          availableLEs.sort(comparator);
          nextEvent = availableLEs[0].otherSE;
          break;
        }
      }

      ringsOut.add(RingOut(events));
    }
    return ringsOut;
  }

  RingOut(this.events) {
    for (int i = 0, iMax = events.length; i < iMax; i++) {
      events[i].segment.ringOut = this;
    }
    poly = null;
  }

  @visibleForTesting
  static RingOut mockWithGeom(dynamic geom) {
    final ring = RingOut([]);
    ring._mockGeom = geom;
    return ring;
  }

  dynamic getGeom() {
    if (_mockGeom != null) return _mockGeom;

    // Guard against empty events list
    if (events.isEmpty) return null;

    // Remove superfluous points (ie extra points along a straight line),
    var prevPt = events[0].point;
    final points = [prevPt];
    for (int i = 1, iMax = events.length - 1; i < iMax; i++) {
      final pt = events[i].point;
      final nextPt = events[i + 1].point;
      if (precision.orient(pt, prevPt, nextPt) == 0) continue;
      points.add(pt);
      prevPt = pt;
    }

    // ring was all (within rounding error of angle calc) colinear points
    if (points.length == 1) return null;

    // check if the starting point is necessary
    final pt = points[0];
    if (points.length > 1) {
      final prevPt = points[points.length - 1];
      final nextPt = points[1];
      if (precision.orient(pt, prevPt, nextPt) == 0) points.removeAt(0);
    }

    // Check if the last point is the same as the first point within precision and remove if necessary
    if (points.isNotEmpty && precision.pointsSame(points.last, points[0])) {
      points.removeLast();
    }

    points.add(points[0]);

    // For interior rings, reverse the points to maintain proper winding order
    final orderedPoints = <List<double>>[];
    if (!isExteriorRing()) {
      // For interior rings, we need to start with the upper-most point to maintain
      // consistent orientation after reversal
      var startIdx = 0;
      for (var i = 1; i < points.length - 1; i++) {
        if (points[i].y > points[startIdx].y ||
            (points[i].y == points[startIdx].y &&
                points[i].x < points[startIdx].x)) {
          startIdx = i;
        }
      }

      // Add points in reverse order starting from the found index
      for (var i = 0; i < points.length; i++) {
        var idx = (startIdx - i + points.length - 1) % (points.length - 1);
        orderedPoints.add([points[idx].x.toDouble(), points[idx].y.toDouble()]);
      }
    } else {
      for (int i = 0; i < points.length; i++) {
        orderedPoints.add([points[i].x.toDouble(), points[i].y.toDouble()]);
      }
    }

    return orderedPoints;
  }

  bool isExteriorRing() {
    if (_isExteriorRing == null) {
      final enclosing = enclosingRing();
      _isExteriorRing = enclosing != null ? !enclosing.isExteriorRing() : true;
    }
    return _isExteriorRing!;
  }

  void setExteriorRing(bool isExterior) {
    _isExteriorRing = isExterior;
  }

  RingOut? enclosingRing() {
    if (_enclosingRing == null) {
      _enclosingRing = _calcEnclosingRing();
    }
    return _enclosingRing;
  }

  /* Returns the ring that encloses this one, if any */
  RingOut? _calcEnclosingRing() {
    // start with the ealier sweep line event so that the prevSeg
    // chain doesn't lead us inside of a loop of ours
    var leftMostEvt = events[0];
    for (int i = 1, iMax = events.length; i < iMax; i++) {
      final evt = events[i];
      if (SweepEvent.compare(leftMostEvt, evt) > 0) leftMostEvt = evt;
    }

    Segment? prevSeg = leftMostEvt.segment.prevInResult();
    Segment? prevPrevSeg = prevSeg != null ? prevSeg.prevInResult() : null;

    while (true) {
      // no segment found, thus no ring can enclose us
      if (prevSeg == null) return null;

      // no segments below prev segment found, thus the ring of the prev
      // segment must loop back around and enclose us
      if (prevPrevSeg == null) return prevSeg.ringOut;

      // if the two segments are of different rings, the ring of the prev
      // segment must either loop around us or the ring of the prev prev
      // seg, which would make us and the ring of the prev peers
      if (prevPrevSeg.ringOut != prevSeg.ringOut) {
        if (prevPrevSeg.ringOut?.enclosingRing() != prevSeg.ringOut) {
          return prevSeg.ringOut;
        } else {
          return prevSeg.ringOut?.enclosingRing();
        }
      }

      // two segments are from the same ring, so this was a penisula
      // of that ring. iterate downward, keep searching
      prevSeg = prevPrevSeg.prevInResult();
      prevPrevSeg = prevSeg != null ? prevSeg.prevInResult() : null;
    }
  }
}

class PolyOut {
  RingOut exteriorRing;
  List<RingOut> interiorRings;
  dynamic _mockGeom;

  PolyOut(this.exteriorRing) : interiorRings = [] {
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

    final geom0 = exteriorRing.getGeom();
    if (geom0 == null)
      return null; // <- This prevents passing null to the Poly constructor

    // Continue as normal
    final rings = <List<List<double>>>[geom0 as List<List<double>>];
    for (final ring in interiorRings) {
      final geom = ring.getGeom();
      if (geom != null) rings.add(geom as List<List<double>>);
    }
    return Poly(rings);
  }
}

class MultiPolyOut {
  List<RingOut> rings;
  List<PolyOut> polys;

  MultiPolyOut(this.rings) : polys = [] {
    polys = _composePolys(rings);
  }

  dynamic getGeom() {
    if (polys.any((p) => p._mockGeom != null)) {
      final mockGeoms = <dynamic>[];
      for (final poly in polys) {
        final geom = poly.getGeom();
        if (geom != null) mockGeoms.add(geom);
      }
      return mockGeoms;
    }

    final realPolys = <Poly>[];
    for (final poly in polys) {
      final geom = poly.getGeom();
      if (geom != null) realPolys.add(geom as Poly); // Only add if non-null
    }
    return MultiPoly(realPolys);
  }

  List<PolyOut> _composePolys(List<RingOut> rings) {
    final polys = <PolyOut>[];
    for (int i = 0, iMax = rings.length; i < iMax; i++) {
      final ring = rings[i];
      if (ring.poly != null) continue;
      if (ring.isExteriorRing()) {
        polys.add(PolyOut(ring));
      } else {
        final enclosingRing = ring.enclosingRing();
        if (enclosingRing != null) {
          if (enclosingRing.poly == null) polys.add(PolyOut(enclosingRing));
          enclosingRing.poly?.addInterior(ring);
        }
      }
    }
    return polys;
  }
}

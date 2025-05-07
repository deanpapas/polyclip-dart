import 'package:decimal/decimal.dart';
import 'segment.dart';
import 'vector.dart';

class Point extends Vector {
  List<SweepEvent> events;

  Point({
    required Decimal x,
    required Decimal y,
    List<SweepEvent>? events,
  })  : events = events ?? [],
        super(x: x, y: y);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class SweepEvent {
  Point point;
  bool isLeft;
  late Segment segment;
  late SweepEvent otherSE;
  SweepEvent? consumedBy;

  // for ordering sweep events in the sweep event queue
  static int compare(SweepEvent a, SweepEvent b) {
    // favor event with a point that the sweep line hits first
    final ptCmp = SweepEvent.comparePoints(a.point, b.point);
    if (ptCmp != 0) return ptCmp;

    // the points are the same, so link them if needed
    if (a.point != b.point) a.link(b);

    // favor right events over left
    if (a.isLeft != b.isLeft) return a.isLeft ? 1 : -1;

    // we have two matching left or right endpoints
    // ordering of this case is the same as for their segments
    return Segment.compare(a.segment, b.segment);
  }

  // for ordering points in sweep line order
  static int comparePoints(Point aPt, Point bPt) {
    if (aPt.x < bPt.x) return -1;
    if (aPt.x > bPt.x) return 1;

    if (aPt.y < bPt.y) return -1;
    if (aPt.y > bPt.y) return 1;

    return 0;
  }

  // Warning: 'point' input will be modified and re-used (for performance)
  SweepEvent(this.point, this.isLeft) {
    point.events.add(this);
    // this.segment, this.otherSE set by factory
  }

  void link(SweepEvent other) {
    if (other.point == this.point) {
      throw Exception("Tried to link already linked events");
    }
    final otherEvents = other.point.events;
    for (int i = 0, iMax = otherEvents.length; i < iMax; i++) {
      final evt = otherEvents[i];
      this.point.events.add(evt);
      evt.point = this.point;
    }
    checkForConsuming();
  }

  /* Do a pass over our linked events and check to see if any pair
    * of segments match, and should be consumed. */
  void checkForConsuming() {
    // FIXME: The loops in this method run O(n^2) => no good.
    //        Maintain little ordered sweep event trees?
    //        Can we maintaining an ordering that avoids the need
    //        for the re-sorting with getLeftmostComparator in geom-out?

    // Compare each pair of events to see if other events also match
    final numEvents = this.point.events.length;
    for (int i = 0; i < numEvents; i++) {
      final evt1 = this.point.events[i];
      if (evt1.segment.consumedBy != null) continue;
      for (int j = i + 1; j < numEvents; j++) {
        final evt2 = this.point.events[j];
        if (evt2.consumedBy != null) continue;
        if (evt1.otherSE.point.events != evt2.otherSE.point.events) continue;
        evt1.segment.consume(evt2.segment);
      }
    }
  }

  List<SweepEvent> getAvailableLinkedEvents() {
    // point.events is always of length 2 or greater
    final events = <SweepEvent>[];
    for (int i = 0, iMax = this.point.events.length; i < iMax; i++) {
      final evt = this.point.events[i];
      if (evt != this &&
          evt.segment.ringOut == null &&
          evt.segment.isInResult()) {
        events.add(evt);
      }
    }
    return events;
  }

  /*
    Returns a comparator function for sorting linked events that will
    favor the event that will give us the smallest left-side angle.
    All ring construction starts as low as possible heading to the right,
    so by always turning left as sharp as possible we'll get polygons
    without uncessary loops & holes.
   
    The comparator function has a compute cache such that it avoids
    re-computing already-computed values.
   */
  int Function(SweepEvent, SweepEvent) getLeftmostComparator(
      SweepEvent baseEvent) {
    final cache = <SweepEvent, Map<String, Decimal>>{};

    void fillCache(SweepEvent linkedEvent) {
      final nextEvent = linkedEvent.otherSE;
      cache[linkedEvent] = {
        'sine': sineOfAngle(this.point, baseEvent.point, nextEvent.point),
        'cosine': cosineOfAngle(this.point, baseEvent.point, nextEvent.point),
      };
    }

    return (SweepEvent a, SweepEvent b) {
      if (!cache.containsKey(a)) fillCache(a);
      if (!cache.containsKey(b)) fillCache(b);

      final asine = cache[a]!['sine']!;
      final acosine = cache[a]!['cosine']!;
      final bsine = cache[b]!['sine']!;
      final bcosine = cache[b]!['cosine']!;

      // both on or above x-axis
      if (asine >= Decimal.zero && bsine >= Decimal.zero) {
        if (acosine < bcosine) return 1;
        if (acosine > bcosine) return -1;
        return 0;
      }

      // both below x-axis
      if (asine < Decimal.zero && bsine < Decimal.zero) {
        if (acosine < bcosine) return -1;
        if (acosine > bcosine) return 1;
        return 0;
      }

      // one above x-axis, one below
      if (bsine < asine) return -1;
      if (bsine > asine) return 1;
      return 0;
    };
  }
}

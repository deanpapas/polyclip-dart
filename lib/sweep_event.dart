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
}

class SweepEvent {
  Point point;
  bool isLeft;
  late Segment segment;
  late SweepEvent otherSE;
  SweepEvent? consumedBy;

  SweepEvent(this.point, this.isLeft) {
    point.events.add(this);
  }

  static int compare(SweepEvent a, SweepEvent b) {
    final ptCmp = SweepEvent.comparePoints(a.point, b.point);
    if (ptCmp != 0) return ptCmp;

    if (!identical(a.point, b.point)) a.link(b);

    if (a.isLeft != b.isLeft) return a.isLeft ? 1 : -1;

    return Segment.compare(a.segment, b.segment);
  }

  static int comparePoints(Point aPt, Point bPt) {
    if (aPt.x < bPt.x) return -1;
    if (aPt.x > bPt.x) return 1;

    if (aPt.y < bPt.y) return -1;
    if (aPt.y > bPt.y) return 1;

    return 0;
  }

  void link(SweepEvent other) {
    if (identical(other.point, this.point)) return;

    final otherEvents = other.point.events;
    for (int i = 0, iMax = otherEvents.length; i < iMax; i++) {
      final evt = otherEvents[i];
      point.events.add(evt);
      evt.point = point;
    }

    checkForConsuming();
  }

  void checkForConsuming() {
    final numEvents = point.events.length;
    for (int i = 0; i < numEvents; i++) {
      final evt1 = point.events[i];
      if (evt1.segment.consumedBy != null) continue;
      for (int j = i + 1; j < numEvents; j++) {
        final evt2 = point.events[j];
        if (evt2.consumedBy != null) continue;
        if (evt1.otherSE.point.events != evt2.otherSE.point.events) continue;
        evt1.segment.consume(evt2.segment);
      }
    }
  }

  List<SweepEvent> getAvailableLinkedEvents() {
    final events = <SweepEvent>[];
    for (int i = 0, iMax = point.events.length; i < iMax; i++) {
      final evt = point.events[i];
      if (evt != this &&
          evt.segment.ringOut == null &&
          evt.segment.isInResult()) {
        events.add(evt);
      }
    }
    return events;
  }

  int Function(SweepEvent, SweepEvent) getLeftmostComparator(
      SweepEvent baseEvent) {
    final cache = <SweepEvent, Map<String, Decimal>>{};

    void fillCache(SweepEvent linkedEvent) {
      final nextEvent = linkedEvent.otherSE;
      cache[linkedEvent] = {
        'sine': sineOfAngle(point, baseEvent.point, nextEvent.point),
        'cosine': cosineOfAngle(point, baseEvent.point, nextEvent.point),
      };
    }

    return (SweepEvent a, SweepEvent b) {
      if (!cache.containsKey(a)) fillCache(a);
      if (!cache.containsKey(b)) fillCache(b);

      final asine = cache[a]!['sine']!;
      final acosine = cache[a]!['cosine']!;
      final bsine = cache[b]!['sine']!;
      final bcosine = cache[b]!['cosine']!;

      if (asine >= Decimal.zero && bsine >= Decimal.zero) {
        if (acosine < bcosine) return 1;
        if (acosine > bcosine) return -1;
        return 0;
      }

      if (asine < Decimal.zero && bsine < Decimal.zero) {
        if (acosine < bcosine) return -1;
        if (acosine > bcosine) return 1;
        return 0;
      }

      if (bsine < asine) return -1;
      if (bsine > asine) return 1;
      return 0;
    };
  }
}

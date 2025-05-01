import 'polyclipbbox.dart';
import 'geom_in.dart';
import 'geom_out.dart';
import 'operation.dart';
import 'precision.dart';
import 'sweep_event.dart';
import 'vector.dart';

class State {
    List<RingIn> rings;
    List<int> windings;
    List<MultiPolyIn> multiPolys;
  
    State({
        required this.rings,
        required this.windings,
        required this.multiPolys,
    });
  
    State.empty() : rings = [], windings = [], multiPolys = [];
  
    State clone() {
        return State(
            rings: [...rings],
            windings: [...windings],
            multiPolys: [...multiPolys],
        );
    } 
}

// Give segments unique ID's to get consistent sorting of
// segments and sweep events when all else is identical
int segmentId = 0;

class Segment {
    int id;
    SweepEvent leftSE;
    SweepEvent rightSE;
    List<RingIn>? rings;
    List<int>? windings;
    RingOut? ringOut;
    Segment? consumedBy;
    Segment? prev;
    Segment? _prevInResult;
    State? _beforeState;
    State? _afterState;
    bool? _isInResult;

    /* This compare() function is for ordering segments in the sweep
    * line tree, and does so according to the following criteria:
    *
    * Consider the vertical line that lies an infinestimal step to the
    * right of the right-more of the two left endpoints of the input
    * segments. Imagine slowly moving a point up from negative infinity
    * in the increasing y direction. Which of the two segments will that
    * point intersect first? That segment comes 'before' the other one.
    *
    * If neither segment would be intersected by such a line, (if one
    * or more of the segments are vertical) then the line to be considered
    * is directly on the right-more of the two left inputs.
    */
    static int compare(Segment a, Segment b) {
        final alx = a.leftSE.point.x;
        final blx = b.leftSE.point.x;
        final arx = a.rightSE.point.x;
        final brx = b.rightSE.point.x;

        // check if they're even in the same vertical plane
        if (brx.compareTo(alx) < 0) return 1;
        if (arx.compareTo(blx) < 0) return -1;

        final aly = a.leftSE.point.y;
        final bly = b.leftSE.point.y;
        final ary = a.rightSE.point.y;
        final bry = b.rightSE.point.y;

        // is left endpoint of segment B the right-more?
        if (alx < blx) {
            // are the two segments in the same horizontal plane?
            if (bly.compareTo(aly) < 0 && bly.compareTo(ary) < 0) return 1;
            if (bly > aly && bly > ary) return -1;

            // is the B left endpoint colinear to segment A?
            final aCmpBLeft = a.comparePoint(b.leftSE.point);
            if (aCmpBLeft < 0) return 1;
            if (aCmpBLeft > 0) return -1;

            // is the A right endpoint colinear to segment B?
            final bCmpARight = b.comparePoint(a.rightSE.point);
            if (bCmpARight != 0) return bCmpARight;

            // colinear segments, consider the one with left-more
            // left endpoint to be first (arbitrary?)
            return -1;
        }

        // is left endpoint of segment A the right-more?
        if (alx > blx) {
            if (aly.compareTo(bly) < 0 && aly.compareTo(bry) < 0) return -1;
            if (aly > bly && aly > bry) return 1;

            // is the A left endpoint colinear to segment B?
            final bCmpALeft = b.comparePoint(a.leftSE.point);
            if (bCmpALeft != 0) return bCmpALeft;

            // is the B right endpoint colinear to segment A?
            final aCmpBRight = a.comparePoint(b.rightSE.point);
            if (aCmpBRight < 0) return 1;
            if (aCmpBRight > 0) return -1;

            // colinear segments, consider the one with left-more
            // left endpoint to be first (arbitrary?)
            return 1;
        }

        // if we get here, the two left endpoints are in the same
        // vertical plane, ie alx === blx

        // consider the lower left-endpoint to come first
        if (aly < bly) return -1;
        if (aly > bly) return 1;

        // left endpoints are identical
        // check for colinearity by using the left-more right endpoint

        // is the A right endpoint more left-more?
        if (arx.compareTo(brx) < 0) {
            final bCmpARight = b.comparePoint(a.rightSE.point);
            if (bCmpARight != 0) return bCmpARight;
        }

        // is the B right endpoint more left-more?
        if (arx > brx) {
            final aCmpBRight = a.comparePoint(b.rightSE.point);
            if (aCmpBRight < 0) return 1;
            if (aCmpBRight > 0) return -1;
        }

        if (arx != brx) {
            // are these two [almost] vertical segments with opposite orientation?
            // if so, the one with the lower right endpoint comes first
            final ay = ary - aly;
            final ax = arx - alx;
            final by = bry - bly;
            final bx = brx - blx;
            if (ay > ax && by < bx) return 1;
            if (ay < ax && by > bx) return -1;
        }

        // we have colinear segments with matching orientation
        // consider the one with more left-more right endpoint to be first
        if (arx > brx) return 1;
        if (arx.compareTo(brx) < 0) return -1;

        // if we get here, two two right endpoints are in the same
        // vertical plane, ie arx === brx

        // consider the lower right-endpoint to come first
        if (ary.compareTo(bry) < 0) return -1;
        if (ary > bry) return 1;

        // right endpoints identical as well, so the segments are identical
        // fall back on creation order as consistent tie-breaker
        if (a.id < b.id) return -1;
        if (a.id > b.id) return 1;

        // identical segment, ie a === b
        return 0;
    }

    /* Warning: a reference to ringWindings input will be stored,
    *  and possibly will be later modified */
    Segment(this.leftSE, this.rightSE, this.rings, this.windings) : id = ++segmentId {
        leftSE.segment = this;
        leftSE.otherSE = rightSE;
        rightSE.segment = this;
        rightSE.otherSE = leftSE;
        // left unset for performance, set later in algorithm
        // this.ringOut, this.consumedBy, this.prev
    }

    static Segment fromRing(Point pt1, Point pt2, RingIn ring) {
        late Point leftPt, rightPt;
        late int winding;

        // ordering the two points according to sweep line ordering
        final cmpPts = SweepEvent.comparePoints(pt1, pt2);
        if (cmpPts < 0) {
            leftPt = pt1;
            rightPt = pt2;
            winding = 1;
        } else if (cmpPts > 0) {
            leftPt = pt2;
            rightPt = pt1;
            winding = -1;
        } else {
        throw Exception(
            'Tried to create degenerate segment at [${pt1.x}, ${pt1.y}]',
        );
        }

        final leftSE = SweepEvent(leftPt, true);
        final rightSE = SweepEvent(rightPt, false);
        return Segment(leftSE, rightSE, [ring], [winding]);
    }

    /* When a segment is split, the rightSE is replaced with a new sweep event */
    void replaceRightSE(SweepEvent newRightSE) {
        rightSE = newRightSE;
        rightSE.segment = this;
        rightSE.otherSE = leftSE;
        leftSE.otherSE = rightSE;
    }

    PolyclipBBox bbox() {
        final y1 = leftSE.point.y;
        final y2 = rightSE.point.y;
        return PolyclipBBox(
            ll: Point(x: leftSE.point.x, y: y1.compareTo(y2) < 0 ? y1 : y2),
            ur: Point(x: rightSE.point.x, y: y1 > y2 ? y1 : y2),
        );
    }

    /* A vector from the left point to the right */
    Vector vector() {
        return Vector(
            x: rightSE.point.x - leftSE.point.x,
            y: rightSE.point.y - leftSE.point.y,
        );
    }

    bool isAnEndpoint(Point pt) {
        return (pt.x == leftSE.point.x && pt.y == leftSE.point.y) ||
            (pt.x == rightSE.point.x && pt.y == rightSE.point.y);
    }

    /* Compare this segment with a point.
    *
    * A point P is considered to be colinear to a segment if there
    * exists a distance D such that if we travel along the segment
    * from one * endpoint towards the other a distance D, we find
    * ourselves at point P.
    *
    * Return value indicates:
    *
    *   1: point lies above the segment (to the left of vertical)
    *   0: point is colinear to segment
    *  -1: point lies below the segment (to the right of vertical)
    */
    int comparePoint(Point point) {
        return precision.orient(leftSE.point, point, rightSE.point);
    }

    /**
    * Given another segment, returns the first non-trivial intersection
    * between the two segments (in terms of sweep line ordering), if it exists.
    *
    * A 'non-trivial' intersection is one that will cause one or both of the
    * segments to be split(). As such, 'trivial' vs. 'non-trivial' intersection:
    *
    *   * endpoint of segA with endpoint of segB --> trivial
    *   * endpoint of segA with point along segB --> non-trivial
    *   * endpoint of segB with point along segA --> non-trivial
    *   * point along segA with point along segB --> non-trivial
    *
    * If no non-trivial intersection exists, return null
    * Else, return null.
    */
    Point? getIntersection(Segment other) {
        // If bboxes don't overlap, there can't be any intersections
        final tBbox = bbox();
        final oBbox = other.bbox();
        final bboxOverlap = getBboxOverlap(tBbox, oBbox);
        if (bboxOverlap == null) return null;

        // We first check to see if the endpoints can be considered intersections.
        // This will 'snap' intersections to endpoints if possible, and will
        // handle cases of colinearity.

        final tlp = leftSE.point;
        final trp = rightSE.point;
        final olp = other.leftSE.point;
        final orp = other.rightSE.point;

        // does each endpoint touch the other segment?
        // note that we restrict the 'touching' definition to only allow segments
        // to touch endpoints that lie forward from where we are in the sweep line pass
        final touchesOtherLSE = isInBbox(tBbox, olp) && comparePoint(olp) == 0;
        final touchesThisLSE = isInBbox(oBbox, tlp) && other.comparePoint(tlp) == 0;
        final touchesOtherRSE = isInBbox(tBbox, orp) && comparePoint(orp) == 0;
        final touchesThisRSE = isInBbox(oBbox, trp) && other.comparePoint(trp) == 0;

        // do left endpoints match?
        if (touchesThisLSE && touchesOtherLSE) {
        // these two cases are for colinear segments with matching left
        // endpoints, and one segment being longer than the other
        if (touchesThisRSE && !touchesOtherRSE) return trp;
        if (!touchesThisRSE && touchesOtherRSE) return orp;
        // either the two segments match exactly (two trival intersections)
        // or just on their left endpoint (one trivial intersection
        return null;
        }

        // does this left endpoint matches (other doesn't)
        if (touchesThisLSE) {
            // check for segments that just intersect on opposing endpoints
            if (touchesOtherRSE) {
            if (tlp.x == orp.x && tlp.y == orp.y) return null;
        }
        // t-intersection on left endpoint
        return tlp;
        }

        // does other left endpoint matches (this doesn't)
        if (touchesOtherLSE) {
            // check for segments that just intersect on opposing endpoints
            if (touchesThisRSE) {
                if (trp.x == olp.x && trp.y == olp.y) return null;
            }
        // t-intersection on left endpoint
        return olp;
        }

        // trivial intersection on right endpoints
        if (touchesThisRSE && touchesOtherRSE) return null;

        // t-intersections on just one right endpoint
        if (touchesThisRSE) return trp;
        if (touchesOtherRSE) return orp;

        // None of our endpoints intersect. Look for a general intersection between
        // infinite lines laid over the segments
        final pt = intersection(tlp, vector(), olp, other.vector());

        // are the segments parrallel? Note that if they were colinear with overlap,
        // they would have an endpoint intersection and that case was already handled above
        if (pt == null) return null;

        // is the intersection found between the lines not on the segments?
        if (!isInBbox(bboxOverlap, pt)) return null;

        // round the the computed point if needed
        return precision.snap(pt) as Point;
    }

  /*
   Split the given segment into multiple segments on the given points.
   Each existing segment will retain its leftSE and a new rightSE will be
   generated for it.
   A new segment will be generated which will adopt the original segment's
   rightSE, and a new leftSE will be generated for it.
   If there are more than two points given to split on, new segments
   in the middle will be generated with new leftSE and rightSE's.
   An array of the newly generated SweepEvents will be returned.
   
   Warning: input array of points is modified
   */
    List<SweepEvent> split(Point point) {
        final newEvents = <SweepEvent>[];
        final alreadyLinked = true;

        final newLeftSE = SweepEvent(point, true);
        final newRightSE = SweepEvent(point, false);
        final oldRightSE = rightSE;
        replaceRightSE(newRightSE);
        newEvents.add(newRightSE);
        newEvents.add(newLeftSE);
        final newSeg = Segment(
            newLeftSE,
            oldRightSE,
            rings!.toList(),
            windings!.toList(),
        );

        // when splitting a nearly vertical downward-facing segment,
        // sometimes one of the resulting new segments is vertical, in which
        // case its left and right events may need to be swapped
        if (SweepEvent.comparePoints(newSeg.leftSE.point, newSeg.rightSE.point) > 0) {
            newSeg.swapEvents();
        }
        if (SweepEvent.comparePoints(leftSE.point, rightSE.point) > 0) {
            swapEvents();
        }

        // in the point we just used to create new sweep events with was already
        // linked to other events, we need to check if either of the affected
        // segments should be consumed
        if (alreadyLinked) {
            newLeftSE.checkForConsuming();
            newRightSE.checkForConsuming();
        }

        return newEvents;
    }

    /* Swap which event is left and right */
    void swapEvents() {
        final tmpEvt = rightSE;
        rightSE = leftSE;
        leftSE = tmpEvt;
        leftSE.isLeft = true;
        rightSE.isLeft = false;
        for (int i = 0, iMax = windings!.length; i < iMax; i++) {
            windings![i] *= -1;
        }
    }

    /* Consume another segment. We take their rings under our wing
    * and mark them as consumed. Use for perfectly overlapping segments */
    void consume(Segment other) {
        Segment consumer = this;
        Segment consumee = other;
        while (consumer.consumedBy != null) consumer = consumer.consumedBy!;
        while (consumee.consumedBy != null) consumee = consumee.consumedBy!;

        final cmp = Segment.compare(consumer, consumee);
        if (cmp == 0) return; // already consumed
        // the winner of the consumption is the earlier segment
        // according to sweep line ordering
        if (cmp > 0) {
            final tmp = consumer;
            consumer = consumee;
            consumee = tmp;
        }

        // make sure a segment doesn't consume it's prev
        if (consumer.prev == consumee) {
            final tmp = consumer;
            consumer = consumee;
            consumee = tmp;
        }

        for (int i = 0, iMax = consumee.rings!.length; i < iMax; i++) {
            final ring = consumee.rings![i];
            final winding = consumee.windings![i];
            final index = consumer.rings!.indexOf(ring);
            if (index == -1) {
                consumer.rings!.add(ring);
                consumer.windings!.add(winding);
            } else {
                consumer.windings![index] += winding;
            }
        }
        consumee.rings = null;
        consumee.windings = null;
        consumee.consumedBy = consumer;

        // mark sweep events consumed as to maintain ordering in sweep event queue
        consumee.leftSE.consumedBy = consumer.leftSE;
        consumee.rightSE.consumedBy = consumer.rightSE;
    }

    /* The first segment previous segment chain that is in the result */
    Segment? prevInResult() {
        if (_prevInResult != null) return _prevInResult;
        if (prev == null) {
            _prevInResult = null;
        } else if (prev!.isInResult()) {
            _prevInResult = prev;
        } else {
            _prevInResult = prev!.prevInResult();
        }
        return _prevInResult;
    }

    State beforeState() {
        if (_beforeState != null) return _beforeState!;
        if (prev == null) {
            _beforeState = State.empty();
        } else {
            final seg = prev!.consumedBy ?? prev!;
            _beforeState = seg.afterState();
        }
        return _beforeState!;
    }

    State afterState() {
        if (_afterState != null) return _afterState!;

        final beforeState = this.beforeState();
        // baseline for before state initialised here
        _afterState = beforeState.clone();
    
        final ringsAfter = _afterState!.rings;
        final windingsAfter = _afterState!.windings;
        final mpsAfter = _afterState!.multiPolys;

        // calculate ringsAfter, windingsAfter
        for (int i = 0, iMax = rings!.length; i < iMax; i++) {
            final ring = rings![i];
            final winding = windings![i];
            final index = ringsAfter.indexOf(ring);
            if (index == -1) {
                ringsAfter.add(ring);
                windingsAfter.add(winding);
            } else {
                windingsAfter[index] += winding;
            }
        }

        // calculate polysAfter
        final polysAfter = [];
        final polysExclude = [];
        for (int i = 0, iMax = ringsAfter.length; i < iMax; i++) {
            if (windingsAfter[i] == 0) continue; // non-zero rule
            final ring = ringsAfter[i];
            final poly = ring.poly;
            if (polysExclude.contains(poly)) continue;
            if (ring.isExterior) {
                polysAfter.add(poly);
            } else {
                if (!polysExclude.contains(poly)) polysExclude.add(poly);
                final index = polysAfter.indexOf(ring.poly);
                if (index != -1) polysAfter.removeAt(index);
            }
        }

        // calculate multiPolysAfter
        for (int i = 0, iMax = polysAfter.length; i < iMax; i++) {
            final mp = polysAfter[i].multiPoly;
            if (!mpsAfter.contains(mp)) mpsAfter.add(mp);
        }

        return _afterState!;
    }

    /* Is this segment part of the final result? */
    bool isInResult() {
        // if we've been consumed, we're not in the result
        if (consumedBy != null) return false;

        if (_isInResult != null) return _isInResult!;

        final mpsBefore = beforeState().multiPolys;
        final mpsAfter = afterState().multiPolys;

        switch (operation.type) {
            case "union": {
            // UNION - included iff:
            //  * On one side of us there is 0 poly interiors AND
            //  * On the other side there is 1 or more.
            final noBefores = mpsBefore.isEmpty;
            final noAfters = mpsAfter.isEmpty;
            _isInResult = noBefores != noAfters;
            break;
        }

        case "intersection": {
            // INTERSECTION - included iff:
            //  * on one side of us all multipolys are rep. with poly interiors AND
            //  * on the other side of us, not all multipolys are represented
            //    with poly interiors
            int least;
            int most;
            if (mpsBefore.length < mpsAfter.length) {
                least = mpsBefore.length;
                most = mpsAfter.length;
            } else {
                least = mpsAfter.length;
                most = mpsBefore.length;
            }
            _isInResult = most == operation.numMultiPolys && least < most;
            break;
        }

        case "xor": {
            // XOR - included iff:
            //  * the difference between the number of multipolys represented
            //    with poly interiors on our two sides is an odd number
            final diff = (mpsBefore.length - mpsAfter.length).abs();
            _isInResult = diff % 2 == 1;
            break;
        }

        case "difference": {
            // DIFFERENCE included iff:
            //  * on exactly one side, we have just the subject
            bool isJustSubject(List<MultiPolyIn> mps) => 
                mps.length == 1 && mps[0].isSubject;
                _isInResult = isJustSubject(mpsBefore) != isJustSubject(mpsAfter);
                break;
        }
      
        default:
            _isInResult = false;
        }

        return _isInResult!;
    }
}
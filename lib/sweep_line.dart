import 'dart:collection';
import 'segment.dart';
import 'sweep_event.dart';

/*
 * NOTE:  We must be careful not to change any segments while
 *        they are in the SplayTree. AFAIK, there's no way to tell
 *        the tree to rebalance itself - thus before splitting
 *        a segment that's in the tree, we remove it from the tree,
 *        do the split, then re-insert it. (Even though splitting a
 *        segment *shouldn't* change its correct position in the
 *        sweep line tree, the reality is because of rounding errors,
 *        it sometimes does.)
 */

class SweepLine {
    final SplayTreeSet<SweepEvent> queue;
    final SplayTreeSet<Segment> tree;
    final List<Segment> segments = [];

    SweepLine(this.queue, [int Function(Segment, Segment) comparator = Segment.compare]) :
        tree = SplayTreeSet<Segment>(comparator);

    List<SweepEvent> process(SweepEvent event) {
        final segment = event.segment;
        final newEvents = <SweepEvent>[];

        // if we've already been consumed by another segment,
        // clean up our body parts and get out
        if (event.consumedBy != null) {
            if (event.isLeft) {
                queue.remove(event.otherSE);
            } else {
                tree.remove(segment);
            }
            return newEvents;
        }

        if (event.isLeft) tree.add(segment);

        Segment? prevSeg = segment;
        Segment? nextSeg = segment;

        // skip consumed segments still in tree
        do {
            prevSeg = findLastBefore(tree, prevSeg);
        } while (prevSeg != null && prevSeg.consumedBy != null);

        // skip consumed segments still in tree
        do {
            nextSeg = findFirstAfter(tree, nextSeg);
        } while (nextSeg != null && nextSeg.consumedBy != null);

        if (event.isLeft) {
            // Check for intersections against the previous segment in the sweep line
            Point? prevMySplitter = null;
            if (prevSeg != null) {
                final prevInter = prevSeg.getIntersection(segment);
                if (prevInter != null) {
                    if (!segment.isAnEndpoint(prevInter)) prevMySplitter = prevInter;
                    if (!prevSeg.isAnEndpoint(prevInter)) {
                        final newEventsFromSplit = _splitSafely(prevSeg, prevInter);
                        newEvents.addAll(newEventsFromSplit);
                    }
                }
            }

            // Check for intersections against the next segment in the sweep line
            Point? nextMySplitter = null;
            if (nextSeg != null) {
                final nextInter = nextSeg.getIntersection(segment);
                if (nextInter != null) {
                    if (!segment.isAnEndpoint(nextInter)) nextMySplitter = nextInter;
                    if (!nextSeg.isAnEndpoint(nextInter)) {
                        final newEventsFromSplit = _splitSafely(nextSeg, nextInter);
                        newEvents.addAll(newEventsFromSplit);
                    }
                }
            }

            // For simplicity, even if we find more than one intersection we only
            // spilt on the 'earliest' (sweep-line style) of the intersections.
            // The other intersection will be handled in a future process().
            if (prevMySplitter != null || nextMySplitter != null) {
                Point? mySplitter = null;
                if (prevMySplitter == null) {
                    mySplitter = nextMySplitter;
                } else if (nextMySplitter == null) {
                    mySplitter = prevMySplitter;
                } else {
                    final cmpSplitters = SweepEvent.comparePoints(
                        prevMySplitter,
                        nextMySplitter,
                    );
                    mySplitter = cmpSplitters <= 0 ? prevMySplitter : nextMySplitter;
                }

                // Rounding errors can cause changes in ordering,
                // so remove affected segments and right sweep events before splitting
                queue.remove(segment.rightSE);
                newEvents.add(segment.rightSE);

                final newEventsFromSplit = segment.split(mySplitter!);
                newEvents.addAll(newEventsFromSplit);
            }

            if (newEvents.isNotEmpty) {
                // We found some intersections, so re-do the current event to
                // make sure sweep line ordering is totally consistent for later
                // use with the segment 'prev' pointers
                tree.remove(segment);
                newEvents.add(event);
            } else {
                // done with left event
                segments.add(segment);
                segment.prev = prevSeg;
            }
        } else {
            // event.isRight

            // since we're about to be removed from the sweep line, check for
            // intersections between our previous and next segments
            if (prevSeg != null && nextSeg != null) {
                final inter = prevSeg.getIntersection(nextSeg);
                if (inter != null) {
                    if (!prevSeg.isAnEndpoint(inter)) {
                        final newEventsFromSplit = _splitSafely(prevSeg, inter);
                        newEvents.addAll(newEventsFromSplit);
                    }
                    if (!nextSeg.isAnEndpoint(inter)) {
                        final newEventsFromSplit = _splitSafely(nextSeg, inter);
                        newEvents.addAll(newEventsFromSplit);
                    }
                }
            }

            tree.remove(segment);
        }

        return newEvents;
    }

    /* Safely split a segment that is currently in the datastructures
     * IE - a segment other than the one that is currently being processed. */
    List<SweepEvent> _splitSafely(Segment seg, Point pt) {
        tree.remove(seg);
        final rightSE = seg.rightSE;
        queue.remove(rightSE);
        final newEvents = seg.split(pt);
        newEvents.add(rightSE);
        // splitting can trigger consumption
        if (seg.consumedBy == null) tree.add(seg);
        return newEvents;
    }

    // Helper method to find the last element before the given element
    Segment? findLastBefore(SplayTreeSet<Segment> tree, Segment? segment) {
        if (segment == null) return null;
        final iterator = tree.toList().reversed.iterator;
        Segment? result;
        
        while (iterator.moveNext()) {
            final current = iterator.current;
            if (Segment.compare(current, segment) < 0) {
                result = current;
                break;
            }
        }
        
        return result;
    }

    // Helper method to find the first element after the given element
    Segment? findFirstAfter(SplayTreeSet<Segment> tree, Segment? segment) {
        if (segment == null) return null;
        final iterator = tree.iterator;
        Segment? result;
        
        while (iterator.moveNext()) {
            final current = iterator.current;
            if (Segment.compare(current, segment) > 0) {
                result = current;
                break;
            }
        }
        
        return result;
    }
}
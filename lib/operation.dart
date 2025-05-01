import 'dart:collection';
import 'polyclipbbox.dart';
import 'geom_in.dart';
import 'geom_out.dart';
import 'precision.dart';
import 'sweep_event.dart';
import 'sweep_line.dart';

/// Singleton class for performing geometric operations on polygons
class Operation {
  String? type;
  int? numMultiPolys;
  
  // Private constructor for singleton pattern
  Operation._();
  
  // Singleton instance
  static final Operation _instance = Operation._();
  
  // Factory constructor to return the singleton instance
  factory Operation() => _instance;
  
  /// Run a boolean operation on the given geometries
  List<dynamic> run(String type, Geom geom, List<Geom> moreGeoms) {
    this.type = type;
    /* Convert inputs to MultiPoly objects */
    final multipolys = <MultiPolyIn>[MultiPolyIn(geom, true)];
    for (int i = 0; i < moreGeoms.length; i++) {
      multipolys.add(MultiPolyIn(moreGeoms[i], false));
    }
    numMultiPolys = multipolys.length;
    
    /* BBox optimization for difference operation
     * If the bbox of a multipolygon that's part of the clipping doesn't
     * intersect the bbox of the subject at all, we can just drop that
     * multiploygon. */
    if (this.type == "difference") {
      // in place removal
      final subject = multipolys[0];
      int i = 1;
      while (i < multipolys.length) {
        if (getBboxOverlap(multipolys[i].bbox, subject.bbox) != null) {
          i++;
        } else {
          multipolys.removeAt(i);
        }
      }
    }
    
    /* BBox optimization for intersection operation
     * If we can find any pair of multipolygons whose bbox does not overlap,
     * then the result will be empty. */
    if (this.type == "intersection") {
      // TODO: this is O(n^2) in number of polygons. By sorting the bboxes,
      //       it could be optimized to O(n * ln(n))
      for (int i = 0; i < multipolys.length; i++) {
        final mpA = multipolys[i];
        for (int j = i + 1; j < multipolys.length; j++) {
          if (getBboxOverlap(mpA.bbox, multipolys[j].bbox) == null) {
            return [];
          }
        }
      }
    }
    
    /* Put segment endpoints in a priority queue */
    final queue = SplayTreeSet<SweepEvent>(SweepEvent.compare);
    for (int i = 0; i < multipolys.length; i++) {
      final sweepEvents = multipolys[i].getSweepEvents();
      for (int j = 0; j < sweepEvents.length; j++) {
        queue.add(sweepEvents[j]);
      }
    }
    
    /* Pass the sweep line over those endpoints */
    final sweepLine = SweepLine(queue);
    SweepEvent? evt;
    if (queue.isNotEmpty) {
      evt = queue.first;
      queue.remove(evt);
    }
    
    while (evt != null) {
      final newEvents = sweepLine.process(evt);
      for (int i = 0; i < newEvents.length; i++) {
        final newEvt = newEvents[i];
        if (newEvt.consumedBy == null) {
          queue.add(newEvt);
        }
      }
      
      if (queue.isNotEmpty) {
        evt = queue.first;
        queue.remove(evt);
      } else {
        evt = null;
      }
    }
    
    // free some memory we don't need anymore
    precision.reset();
    
    /* Collect and compile segments we're keeping into a multipolygon */
    final ringsOut = RingOut.factory(sweepLine.segments);
    final result = MultiPolyOut(ringsOut);
    return result.getGeom() as List<dynamic>;
  }
}

// Singleton instance available by import
final operation = Operation();
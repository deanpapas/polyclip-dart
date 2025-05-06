import 'dart:collection';
import 'package:decimal/decimal.dart';
import 'vector.dart';
import 'compare.dart';
import 'sweep_event.dart'; // for Point

typedef Snap = Point Function(Vector v);

/// Creates a snap function that optionally snaps vector coordinates to a grid.
///
/// If [eps] is provided, coordinates that are close to each other (within [eps])
/// will snap to the same value using SplayTreeSet's ordering with epsilon comparison.
/// If [eps] is null, the identity function is returned, which doesn't modify vectors.
Snap snap({double? eps}) {
  if (eps != null) {
    final comparer = compareWithDecimalEpsilon(Decimal.parse(eps.toString()));
    final xTree = SplayTreeSet<Decimal>(comparer);
    final yTree = SplayTreeSet<Decimal>(comparer);

    Decimal snapCoord(Decimal coord, SplayTreeSet<Decimal> tree) {
      tree.add(coord);
      return tree.firstWhere(
        (element) => comparer(element, coord) == 0,
        orElse: () => coord,
      );
    }

    Point Function(Vector) snapVector = (Vector v) {
      return Point(
        x: snapCoord(v.x, xTree),
        y: snapCoord(v.y, yTree),
      );
    };

    // Pre-warm
    snapVector(Vector(x: Decimal.zero, y: Decimal.zero));

    return snapVector;
  }

  // Fall back to identity (returning the same position as a Point)
  return (Vector v) => Point(x: v.x, y: v.y);
}

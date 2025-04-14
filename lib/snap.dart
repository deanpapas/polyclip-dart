import 'dart:collection';
import 'package:decimal/decimal.dart';
import 'vector.dart';
import 'compare.dart';
import 'identity.dart';

/// Creates a snap function that optionally snaps vector coordinates to a grid.
/// 
/// If [eps] is provided, coordinates that are close to each other (within [eps])
/// will snap to the same value using SplayTreeSet's ordering with epsilon comparison.
/// If [eps] is null, the identity function is returned, which doesn't modify vectors.
/// 
/// Returns a function that takes a Vector and returns a potentially snapped Vector.
Function snap({double? eps}) {
  if (eps != null) {
    // Cast the comparison function to the correct type
    final comparer = compareWithEpsilon(eps) as int Function(Decimal, Decimal);
    final xTree = SplayTreeSet<Decimal>(comparer);
    final yTree = SplayTreeSet<Decimal>(comparer);
    
    Decimal snapCoord(Decimal coord, SplayTreeSet<Decimal> tree) {
      tree.add(coord);
      // Find the closest value that was actually stored (which might be the coord itself or
      // something within eps that was already in the tree)
      final near = tree.firstWhere(
        (element) => comparer(element, coord) == 0,
        orElse: () => coord
      );
      return near;
    }
    
    Vector Function(Vector) snapVector = (Vector v) {
      return Vector(
        x: snapCoord(v.x, xTree),
        y: snapCoord(v.y, yTree),
      );
    };
    
    // Initialize with origin point
    snapVector(Vector(x: Decimal.zero, y: Decimal.zero));
    
    return snapVector;
  }
  
  return identity;
}
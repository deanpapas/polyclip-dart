import 'vector.dart';
import 'package:decimal/decimal.dart';

/// A function type that, given three Vectors (points) a, b, c,
/// returns:
///   0 if they are considered collinear,
///  -1 if area2 < 0 (a->c->b is a clockwise turn),
///   1 if area2 > 0 (a->c->b is a counter-clockwise turn).
typedef CollinearityTest = int Function(Vector a, Vector b, Vector c);

/// Returns a constant function that always returns false.
/// Mirrors JavaScript's `constant(false)` utility.
bool Function(Decimal, Decimal, Decimal, Decimal, Decimal) constantFalse() {
  return (_, __, ___, ____, _____) => false;
}

/// Returns a function that checks if three points (a, b, c) are collinear.
/// If [eps] is provided, the code considers them collinear when
/// (area2^2) <= ((cx - ax)^2 + (cy - ay)^2) * eps.
/// If [eps] is null, it treats them as never collinear.
CollinearityTest createCollinearityChecker([double? eps]) {
  final bool Function(Decimal, Decimal, Decimal, Decimal, Decimal) almostCollinear =
      eps != null
          ? (area2, ax, ay, cx, cy) {
              final dx = cx - ax;
              final dy = cy - ay;
              final threshold = (dx * dx + dy * dy) * Decimal.parse(eps.toString());
              return area2 * area2 <= threshold;
            }
          : constantFalse();

  return (Vector a, Vector b, Vector c) {
    final ax = a.x, ay = a.y;
    final cx = c.x, cy = c.y;

    final area2 = (ay - cy) * (b.x - cx) - (ax - cx) * (b.y - cy);

    if (almostCollinear(area2, ax, ay, cx, cy)) return 0;

    return area2 < Decimal.zero ? -1 : (area2 > Decimal.zero ? 1 : 0);
  };
}

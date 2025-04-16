import 'vector.dart';
import 'package:decimal/decimal.dart';

/// A function type that, given three Vectors (points) a, b, c,
/// returns:
///   0 if they are considered collinear,
///  -1 if area2 < 0 (a->c->b is a clockwise turn),
///   1 if area2 > 0 (a->c->b is a counter-clockwise turn).
typedef CollinearityTest = int Function(Vector a, Vector b, Vector c);

/// Returns a function that checks if three points (a, b, c) are collinear.
/// If [eps] is provided, the code considers them collinear when
/// (area2^2) <= ((cx - ax)^2 + (cy - ay)^2) * eps.
/// If [eps] is null, it treats them as never collinear (mimicking `constant(false)`).
CollinearityTest createCollinearityChecker([double? eps]) {
  // This function checks if area2 is small enough to be considered ~ 0,
  // taking into account the distance between a and c.
  bool almostCollinear(
    double area2,
    double ax,
    double ay,
    double cx,
    double cy,
  ) {
    if (eps == null) {
      return false;
    }
    final dx = cx - ax;
    final dy = cy - ay;
    // area2^2 <= (dx^2 + dy^2) * eps
    return (area2 * area2) <= (dx * dx + dy * dy) * eps;
  }

  // Return the main function that computes orientation of a, b, c.
  return (Vector a, Vector b, Vector c) {
    final ax = a.x, ay = a.y;
    final cx = c.x, cy = c.y;

    final area2 = (ay - cy) * (b.x - cx) - (ax - cx) * (b.y - cy);

    if (almostCollinear(area2.toDouble(), ax.toDouble(), ay.toDouble(), cx.toDouble(), cy.toDouble())) {
      return 0;
    }

    if (area2 < Decimal.fromInt(0)) return -1;
    if (area2 > Decimal.fromInt(0)) return 1;
    return 0; // Collinear case
  };
}

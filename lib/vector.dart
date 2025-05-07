import 'package:decimal/decimal.dart';
import 'dart:math' as math;

/// Represents a 2D vector with high-precision x and y coordinates.
class Vector {
  final Decimal x;
  final Decimal y;

  const Vector({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      other is Vector && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Approximates the square root of a Decimal value by converting to double.
/// Note: This sacrifices arbitrary precision.
Decimal sqrtDecimal(Decimal value) {
  if (value < Decimal.zero) {
    throw ArgumentError('Cannot compute sqrt of a negative number');
  }
  final d = value.toDouble();
  final sqrtD = math.sqrt(d);
  return Decimal.parse(sqrtD.toString());
}

/// Cross Product of two vectors (treated as originating at the origin).
Decimal crossProduct(Vector a, Vector b) {
  return (a.x * b.y) - (a.y * b.x);
}

/// Dot Product of two vectors.sp
Decimal dotProduct(Vector a, Vector b) {
  return (a.x * b.x) + (a.y * b.y);
}

/// Returns the length (magnitude) of the vector.
Decimal length(Vector v) {
  return sqrtDecimal(dotProduct(v, v));
}

/// Returns the sine of the angle between vectors (pShared->pAngle) and (pShared->pBase).
Decimal sineOfAngle(Vector pShared, Vector pBase, Vector pAngle) {
  final vBase = Vector(
    x: Decimal.parse((pBase.x - pShared.x).toString()),
    y: Decimal.parse((pBase.y - pShared.y).toString()),
  );
  final vAngle = Vector(
    x: Decimal.parse((pAngle.x - pShared.x).toString()),
    y: Decimal.parse((pAngle.y - pShared.y).toString()),
  );

  final crossProd = crossProduct(vAngle, vBase);
  final lenAngle = length(vAngle);
  final lenBase = length(vBase);
  final denominator = lenAngle * lenBase;

  final result = crossProd.toDouble() / denominator.toDouble();
  return Decimal.parse(result.toString());
}

/// Returns the cosine of the angle between vectors (pShared->pAngle) and (pShared->pBase).
Decimal cosineOfAngle(Vector pShared, Vector pBase, Vector pAngle) {
  final vBase = Vector(
    x: Decimal.parse((pBase.x - pShared.x).toString()),
    y: Decimal.parse((pBase.y - pShared.y).toString()),
  );
  final vAngle = Vector(
    x: Decimal.parse((pAngle.x - pShared.x).toString()),
    y: Decimal.parse((pAngle.y - pShared.y).toString()),
  );

  final dotProd = dotProduct(vAngle, vBase);
  final lenAngle = length(vAngle);
  final lenBase = length(vBase);
  final denominator = lenAngle * lenBase;

  final result = dotProd.toDouble() / denominator.toDouble();
  return Decimal.parse(result.toString());
}

/// Returns the intersection point where the line (defined by a point [pt] and direction vector [v])
/// crosses a horizontal line with the given y coordinate.
/// Returns null if the line is parallel to the horizontal line.
Vector? horizontalIntersection(Vector pt, Vector v, Decimal y) {
  if (v.y == Decimal.zero) return null;
  final ratio = Decimal.parse((v.x / v.y).toString());
  final yDiff = Decimal.parse((y - pt.y).toString());
  final xOffset = Decimal.parse((ratio * yDiff).toString());
  final x = pt.x + xOffset;
  return Vector(x: x, y: y);
}

/// Returns the intersection point where the line (defined by a point [pt] and direction vector [v])
/// crosses a vertical line with the given x coordinate.
/// Returns null if the line is parallel to the vertical line.
Vector? verticalIntersection(Vector pt, Vector v, Decimal x) {
  if (v.x == Decimal.zero) return null;
  final ratio = Decimal.parse((v.y / v.x).toString());
  final xDiff = Decimal.parse((x - pt.x).toString());
  final yOffset = Decimal.parse((ratio * xDiff).toString());
  final y = pt.y + yOffset;
  return Vector(x: x, y: y);
}

/// Given two lines, each defined by a base point and a vector, returns the intersection point.
/// For vertical and horizontal lines, shortcuts are used and if the lines are parallel, null is returned.
Vector? intersection(Vector pt1, Vector v1, Vector pt2, Vector v2) {
  if (v1.x == Decimal.zero) return verticalIntersection(pt2, v2, pt1.x);
  if (v2.x == Decimal.zero) return verticalIntersection(pt1, v1, pt2.x);
  if (v1.y == Decimal.zero) return horizontalIntersection(pt2, v2, pt1.y);
  if (v2.y == Decimal.zero) return horizontalIntersection(pt1, v1, pt2.y);

  final kross = crossProduct(v1, v2);
  if (kross == Decimal.zero) return null;

  // Vector from pt1 to pt2
  final ve = Vector(
    x: pt2.x - pt1.x,
    y: pt2.y - pt1.y,
  );

  final crossVEv1R = Decimal.parse(crossProduct(ve, v1).toString());
  final crossVEv2R = Decimal.parse(crossProduct(ve, v2).toString());
  final krossR = Decimal.parse(kross.toString());

  // d1 and d2, specify how many digits of precision you want to keep
  const int scale = 28; // or however many you need
  final d1 = (crossVEv1R / krossR).toDecimal(scaleOnInfinitePrecision: scale);
  final d2 = (crossVEv2R / krossR).toDecimal(scaleOnInfinitePrecision: scale);

  // Intersection can be derived in two ways:
  //   X1 = pt1 + d2 * v1
  //   X2 = pt2 + d1 * v2
  // We compute both and take their average to reduce rounding error.
  final x1 = pt1.x + (d2 * v1.x);
  final x2 = pt2.x + (d1 * v2.x);
  final y1 = pt1.y + (d2 * v1.y);
  final y2 = pt2.y + (d1 * v2.y);

  // (x1 + x2)/2 and (y1 + y2)/2 may be a rational again;
  // convert back to Decimal with finite precision.
  final xR = (x1.toDouble() + x2.toDouble()) / 2;
  final yR = (y1.toDouble() + y2.toDouble()) / 2;

  final x = Decimal.parse(xR.toString());
  final y = Decimal.parse(yR.toString());

  return Vector(x: x, y: y);
}

/// Returns a vector that is perpendicular to the given vector [v].
Vector perpendicular(Vector v) {
  return Vector(x: -v.y, y: v.x);
}

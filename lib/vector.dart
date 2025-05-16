import 'package:decimal/decimal.dart';
import 'dart:math' as math;

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

Decimal sqrtDecimal(Decimal value) {
  if (value < Decimal.zero) throw ArgumentError('Cannot sqrt negative');
  return Decimal.parse(math.sqrt(value.toDouble()).toString());
}

Decimal crossProduct(Vector a, Vector b) => a.x * b.y - a.y * b.x;

Decimal dotProduct(Vector a, Vector b) => a.x * b.x + a.y * b.y;

Decimal length(Vector v) => sqrtDecimal(dotProduct(v, v));

Decimal sineOfAngle(Vector pShared, Vector pBase, Vector pAngle) {
  final vBase = Vector(x: pBase.x - pShared.x, y: pBase.y - pShared.y);
  final vAngle = Vector(x: pAngle.x - pShared.x, y: pAngle.y - pShared.y);

  final crossProd = crossProduct(vAngle, vBase);
  final lenAngle = length(vAngle);
  final lenBase = length(vBase);

  final result = crossProd.toDouble() / (lenAngle * lenBase).toDouble();
  return Decimal.parse(result.toString());
}

Decimal cosineOfAngle(Vector pShared, Vector pBase, Vector pAngle) {
  final vBase = Vector(x: pBase.x - pShared.x, y: pBase.y - pShared.y);
  final vAngle = Vector(x: pAngle.x - pShared.x, y: pAngle.y - pShared.y);

  final dotProd = dotProduct(vAngle, vBase);
  final lenAngle = length(vAngle);
  final lenBase = length(vBase);

  final result = dotProd.toDouble() / (lenAngle * lenBase).toDouble();
  return Decimal.parse(result.toString());
}

Vector? horizontalIntersection(Vector pt, Vector v, Decimal y) {
  if (v.y == Decimal.zero) return null;

  // Ensure Decimal operands only
  final ratio = Decimal.parse((v.x / v.y).toString());
  final yDiff = Decimal.parse((y - pt.y).toString());
  final xOffset = ratio * yDiff;
  final x = pt.x + xOffset;

  return Vector(x: x, y: y);
}

Vector? verticalIntersection(Vector pt, Vector v, Decimal x) {
  if (v.x == Decimal.zero) return null;

  final ratio = Decimal.parse((v.y / v.x).toString());
  final xDiff = Decimal.parse((x - pt.x).toString());
  final yOffset = ratio * xDiff;
  final y = pt.y + yOffset;

  return Vector(x: x, y: y);
}

Vector? intersection(Vector pt1, Vector v1, Vector pt2, Vector v2) {
  if (v1.x == Decimal.zero) return verticalIntersection(pt2, v2, pt1.x);
  if (v2.x == Decimal.zero) return verticalIntersection(pt1, v1, pt2.x);
  if (v1.y == Decimal.zero) return horizontalIntersection(pt2, v2, pt1.y);
  if (v2.y == Decimal.zero) return horizontalIntersection(pt1, v1, pt2.y);

  final kross = crossProduct(v1, v2);
  if (kross == Decimal.zero) return null;

  final ve = Vector(x: pt2.x - pt1.x, y: pt2.y - pt1.y);
  final Decimal d1 = (crossProduct(ve, v1) / kross).toDecimal(scaleOnInfinitePrecision: 28);
  final Decimal d2 = (crossProduct(ve, v2) / kross).toDecimal(scaleOnInfinitePrecision: 28);

  // No parse().toString() hack needed — now all operands are Decimal
  final x1 = pt1.x + d2 * v1.x;
  final x2 = pt2.x + d1 * v2.x;
  final y1 = pt1.y + d2 * v1.y;
  final y2 = pt2.y + d1 * v2.y;

  final x = Decimal.parse(((x1.toDouble() + x2.toDouble()) / 2).toString());
  final y = Decimal.parse(((y1.toDouble() + y2.toDouble()) / 2).toString());

  return Vector(x: x, y: y);
}

Vector perpendicular(Vector v) => Vector(x: -v.y, y: v.x);

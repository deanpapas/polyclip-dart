import 'vector.dart';
import 'package:geotypes/geotypes.dart';
import 'package:decimal/decimal.dart';

/// A bounding box has the format:
///   { ll: Vector(x: xmin, y: ymin), ur: Vector(x: xmax, y: ymax) }
class PolyclipBBox extends BBox {
  Vector get ll => Vector(x: Decimal.parse(lat1.toString()), y: Decimal.parse(lng1.toString()));
  Vector get ur => Vector(x: Decimal.parse(lat2.toString()), y: Decimal.parse(lng2.toString()));

  PolyclipBBox({required Vector ll, required Vector ur})
      : super(
          ll.y.toDouble(),
          ll.x.toDouble(),
          ur.y.toDouble(),
          ur.x.toDouble(),
        );
}

/// Checks if [point] lies within the [bbox].
bool isInBbox(PolyclipBBox bbox, Vector point) {
  return (bbox.ll.x <= point.x &&
          point.x <= bbox.ur.x &&
          bbox.ll.y <= point.y &&
          point.y <= bbox.ur.y);
}

/// Returns either null, or the overlapping [Bbox] of [b1] and [b2].
/// If there is only one point of overlap, a Bbox with identical points is returned.
PolyclipBBox? getBboxOverlap(PolyclipBBox b1, PolyclipBBox b2) {
  // Check if the two bounding boxes fail to overlap
  if (b2.ur.x < b1.ll.x ||
      b1.ur.x < b2.ll.x ||
      b2.ur.y < b1.ll.y ||
      b1.ur.y < b2.ll.y) {
    return null;
  }

  // Find the "middle" two X values
  final lowerX = (b1.ll.x < b2.ll.x) ? b2.ll.x : b1.ll.x;
  final upperX = (b1.ur.x < b2.ur.x) ? b1.ur.x : b2.ur.x;

  // Find the "middle" two Y values
  final lowerY = (b1.ll.y < b2.ll.y) ? b2.ll.y : b1.ll.y;
  final upperY = (b1.ur.y < b2.ur.y) ? b1.ur.y : b2.ur.y;

  // Construct the overlap bounding box
  return PolyclipBBox(
    ll: Vector(x: lowerX, y: lowerY),
    ur: Vector(x: upperX, y: upperY),
  );
}

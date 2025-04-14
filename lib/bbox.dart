import 'vector.dart';

/// A bounding box has the format:
///   { ll: Vector(x: xmin, y: ymin), ur: Vector(x: xmax, y: ymax) }
class Bbox {
  final Vector ll;
  final Vector ur;

  const Bbox({required this.ll, required this.ur});
}

/// Checks if [point] lies within the [bbox].
bool isInBbox(Bbox bbox, Vector point) {
  return (bbox.ll.x <= point.x &&
          point.x <= bbox.ur.x &&
          bbox.ll.y <= point.y &&
          point.y <= bbox.ur.y);
}

/// Returns either null, or the overlapping [Bbox] of [b1] and [b2].
/// If there is only one point of overlap, a Bbox with identical points is returned.
Bbox? getBboxOverlap(Bbox b1, Bbox b2) {
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
  return Bbox(
    ll: Vector(x: lowerX, y: lowerY),
    ur: Vector(x: upperX, y: upperY),
  );
}

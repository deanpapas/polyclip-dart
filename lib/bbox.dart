import 'package:decimal/decimal.dart';
import 'vector.dart';

/// A bounding box specifically designed for the polyclip algorithm
class Bbox {
  Vector _ll;
  Vector _ur;

  Vector get ll => _ll;
  Vector get ur => _ur;

  Bbox({required Vector ll, required Vector ur})
      : _ll = ll,
        _ur = ur;

  set llx(Decimal value) => _ll = Vector(x: value, y: _ll.y);
  set lly(Decimal value) => _ll = Vector(x: _ll.x, y: value);
  set urx(Decimal value) => _ur = Vector(x: value, y: _ur.y);
  set ury(Decimal value) => _ur = Vector(x: _ur.x, y: value);
}

/// Returns true if the point lies inside the bbox
bool isInBbox(Bbox bbox, Vector point) {
  return (bbox.ll.x <= point.x &&
      point.x <= bbox.ur.x &&
      bbox.ll.y <= point.y &&
      point.y <= bbox.ur.y);
}

/// Returns the overlapping bbox of b1 and b2, or null if there's no overlap.
Bbox? getBboxOverlap(Bbox b1, Bbox b2) {
  if (b2.ur.x < b1.ll.x ||
      b1.ur.x < b2.ll.x ||
      b2.ur.y < b1.ll.y ||
      b1.ur.y < b2.ll.y) {
    return null;
  }

  final lowerX = b1.ll.x < b2.ll.x ? b2.ll.x : b1.ll.x;
  final upperX = b1.ur.x < b2.ur.x ? b1.ur.x : b2.ur.x;
  final lowerY = b1.ll.y < b2.ll.y ? b2.ll.y : b1.ll.y;
  final upperY = b1.ur.y < b2.ur.y ? b1.ur.y : b2.ur.y;

  return Bbox(
    ll: Vector(x: lowerX, y: lowerY),
    ur: Vector(x: upperX, y: upperY),
  );
}

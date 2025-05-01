import 'package:decimal/decimal.dart';
import 'package:geotypes/geotypes.dart';
import 'vector.dart';

/// A bounding box specifically designed for the polyclip algorithm
class PolyclipBBox {
  // Internal vector representation for the lower-left and upper-right corners
  Vector _ll;
  Vector _ur;
  
  // Getters for the internal coordinates
  Vector get ll => _ll;
  Vector get ur => _ur;
  
  // Constructor
  PolyclipBBox({required Vector ll, required Vector ur})
      : _ll = ll,
        _ur = ur;
  
  // Create from a GeoTypes BBox
  PolyclipBBox.fromBBox(BBox bbox)
      : _ll = Vector(x: Decimal.parse(bbox.lng1.toString()), y: Decimal.parse(bbox.lat1.toString())),
        _ur = Vector(x: Decimal.parse(bbox.lng2.toString()), y: Decimal.parse(bbox.lat2.toString()));
  
  // Setters for ll.x, ll.y, ur.x, ur.y
  set llx(Decimal value) {
    _ll = Vector(x: value, y: _ll.y);
  }
  
  set lly(Decimal value) {
    _ll = Vector(x: _ll.x, y: value);
  }
  
  set urx(Decimal value) {
    _ur = Vector(x: value, y: _ur.y);
  }
  
  set ury(Decimal value) {
    _ur = Vector(x: _ur.x, y: value);
  }
  
  // Convert to GeoTypes BBox
  BBox toBBox() => BBox(
    _ll.x.toDouble(),  // lng1 
    _ll.y.toDouble(),  // lat1
    _ur.x.toDouble(),  // lng2
    _ur.y.toDouble(),  // lat2
  );
}

/// Checks if [point] lies within the [bbox].
bool isInBbox(PolyclipBBox bbox, Vector point) {
  return (bbox.ll.x <= point.x &&
          point.x <= bbox.ur.x &&
          bbox.ll.y <= point.y &&
          point.y <= bbox.ur.y);
}

/// Returns either null, or the overlapping [PolyclipBBox] of [b1] and [b2].
/// If there is only one point of overlap, a PolyclipBBox with identical points is returned.
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
import 'package:turf/turf.dart' as turf;
import 'package:test/test.dart';

void main() {
  group('Create intersecting squares', () {
    test('should create two intersecting square bounding boxes', () {
      // Define the bounding boxes of the two squares
      final turf.BBox bbox1 = turf.BBox.named(
        lng1: -2,
        lat1: -2,
        lng2: 2,
        lat2: 2,
      );
      final turf.BBox bbox2 = turf.BBox.named(
        lng1: 0,
        lat1: 0,
        lng2: 4,
        lat2: 4,
      );

      // Create square bounding boxes from the original bounding boxes
      final turf.BBox squareBbox1 = square(bbox1);
      final turf.BBox squareBbox2 = square(bbox2);

      // Verify that the bounding boxes are created.
      expect(squareBbox1, isA<turf.BBox>());
      expect(squareBbox2, isA<turf.BBox>());

      // Verify that the squares intersect.
      bool intersects = _checkBoxIntersection(squareBbox1, squareBbox2);
      expect(intersects, true, reason: 'Squares should intersect');
    });
  });
}

// Helper function to check if two bounding boxes intersect
bool _checkBoxIntersection(turf.BBox bbox1, turf.BBox bbox2) {
  return !(bbox2.lng1 > bbox1.lng2 ||
           bbox2.lng2 < bbox1.lng1 ||
           bbox2.lat1 > bbox1.lat2 ||
           bbox2.lat2 < bbox1.lat1);
}

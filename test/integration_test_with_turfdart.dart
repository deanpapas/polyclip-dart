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

      // Create square polygons from the bounding boxes using turf.bboxPolygon
      final turf.Polygon square1 = turf.bboxPolygon(bbox1).geometry!;
      final turf.Polygon square2 = turf.bboxPolygon(bbox2).geometry!;

      // Verify that the polygons are created.
      expect(square1, isA<turf.Polygon>());
      expect(square2, isA<turf.Polygon>());

      // Verify that the squares intersect using bounding box intersection check
      bool intersects = _checkBoxIntersection(bbox1, bbox2);
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

import 'package:decimal/decimal.dart';
import 'package:polyclip_dart/geom_in.dart';
import 'package:polyclip_dart/geom_out.dart';
import 'package:polyclip_dart/segment.dart'; //might need to change imports

void main() {
  // Define polygons using Decimal for high precision
   final Ring polygon1 = [
    [Decimal.fromInt(0).toDouble(), Decimal.fromInt(0).toDouble()],
    [Decimal.fromInt(0).toDouble(), Decimal.fromInt(10).toDouble()],
    [Decimal.fromInt(10).toDouble(), Decimal.fromInt(10).toDouble()],
    [Decimal.fromInt(10).toDouble(), Decimal.fromInt(0).toDouble()],
    [Decimal.fromInt(0).toDouble(), Decimal.fromInt(0).toDouble()], // Close the ring
  ];

  final Ring polygon2 = [
    [Decimal.fromInt(2).toDouble(), Decimal.fromInt(2).toDouble()],
    [Decimal.fromInt(2).toDouble(), Decimal.fromInt(8).toDouble()],
    [Decimal.fromInt(8).toDouble(), Decimal.fromInt(8).toDouble()],
    [Decimal.fromInt(8).toDouble(), Decimal.fromInt(2).toDouble()],
    [Decimal.fromInt(2).toDouble(), Decimal.fromInt(2).toDouble()], // Close the ring
  ];
  // Wrap polygons in PolyIn
  final polyIn1 = PolyIn(Poly([polygon1]), MultiPolyIn(Poly([polygon1]), true));
  final polyIn2 = PolyIn(Poly([polygon2]), MultiPolyIn(Poly([polygon2]), false));

  // Combine all sweep events
  final allSegments = <Segment>[];
  allSegments.addAll(polyIn1.getSweepEvents().map((e) => e.segment));
  allSegments.addAll(polyIn2.getSweepEvents().map((e) => e.segment));

  // Perform the intersection
  final intersectedRings = RingOut.factory(allSegments);

  // Print the results
  if (intersectedRings.isNotEmpty) {
    for (final ring in intersectedRings) {
      print('Intersected Ring: ${ring.getGeom()}');
    }
  } else {
    print('No intersection found');
  }
}
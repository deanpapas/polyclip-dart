import 'package:geotypes/geotypes.dart';
import 'package:polyclip_dart/index.dart';
void main() {
  // Define two solid squares as polygons using geotypes
  Polygon square1 = Polygon(
    coordinates: [
      [
        Position(0, 0),
        Position(10, 0),
        Position(10, 10),
        Position(0, 10),
        Position(0, 0),
      ]
    ]
  );

  Polygon square2 = Polygon(
    coordinates: [
      [
        Position(5, 5),
        Position(15, 5),
        Position(15, 15),
        Position(5, 15),
        Position(5, 5),
      ]
    ]
  );  


  // Compute their intersection
  var result = intersection(square1, square2);

  // Check if the result is non-empty (means they intersect)
  bool doTheyIntersect = result.isNotEmpty;

  print("Do the squares intersect? $doTheyIntersect");
}


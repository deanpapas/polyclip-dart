import 'geom_in.dart';
import 'precision.dart';
import 'operation.dart';

export 'geom_in.dart';

import 'package:geotypes/geotypes.dart';

Polygon union(Polygon geom, List<Polygon> moreGeoms) =>
    operation.run('union', geom, moreGeoms) as Polygon;

Polygon intersection(Polygon geom, List<Polygon> moreGeoms) =>
    operation.run('intersection', geom, moreGeoms) as Polygon;

Polygon xor(Polygon geom, List<Polygon> moreGeoms) =>
    operation.run('xor', geom, moreGeoms) as Polygon;

Polygon difference(Polygon geom, List<Polygon> moreGeoms) =>
    operation.run('difference', geom, moreGeoms) as Polygon;

// Expose the setPrecision function from precision
final setPrecision = precision.set;

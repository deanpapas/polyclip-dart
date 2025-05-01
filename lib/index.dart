import 'geom-in.dart';
import 'precision.dart';
import 'operation.dart';

export 'geom-in.dart';

Geom union(Geom geom, List<Geom> moreGeoms) =>
    operation.run('union', geom, moreGeoms) as Geom;

Geom intersection(Geom geom, List<Geom> moreGeoms) =>
    operation.run('intersection', geom, moreGeoms) as Geom;

Geom xor(Geom geom, List<Geom> moreGeoms) =>
    operation.run('xor', geom, moreGeoms) as Geom;

Geom difference(Geom geom, List<Geom> moreGeoms) =>
    operation.run('difference', geom, moreGeoms) as Geom;

// Expose the setPrecision function from precision
final setPrecision = precision.set;

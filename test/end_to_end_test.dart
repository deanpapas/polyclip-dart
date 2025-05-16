import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../lib/index.dart';

void main() {
  final String endToEndDir = 'test/end-to-end';

  final List<String> targets = Directory(endToEndDir)
      .listSync()
      .whereType<Directory>()
      .map((d) => p.basename(d.path))
      .where((name) => !name.startsWith('.'))
      .toList();
  const List<String> targetsSkip = [];
  const List<String> opsSkip = [];

  group('end to end', () {
    for (final target in targets) {
      final String targetDir = p.join(endToEndDir, target);

      final File argsFile = File(p.join(targetDir, 'args.geojson'));
      final Map<String, dynamic> argsGeojson =
          jsonDecode(argsFile.readAsStringSync());
      final features = argsGeojson['features'] as List<dynamic>;
      final List<Geom> args = features.map<Geom>((f) {
        final geometry = f['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;
        
        // Convert coordinates to Poly objects
        if (coords.isEmpty) return Poly([]);

        final List<List<List<double>>> rings = <List<List<double>>>[];
        
        // Process each ring
        for (final ring in coords) {
          if (!(ring is List)) continue;
          
          final List<List<double>> processedRing = <List<double>>[];
          
          // Process each point in the ring
          for (final point in ring) {
            if (!(point is List) || point.length != 2) continue;
            
            final x = point[0];
            final y = point[1];
            
            if (x is num && y is num) {
              processedRing.add([x.toDouble(), y.toDouble()]);
            }
          }
          
          if (processedRing.isNotEmpty) {
            rings.add(processedRing);
          }
        }
        
        return Poly(rings);
      }).toList();

      final List<List<dynamic>> resultPathsAndOperationTypes =
          Directory(targetDir)
              .listSync()
              .whereType<File>()
              .where((f) =>
                  p.extension(f.path) == '.geojson' &&
                  !p.basename(f.path).contains('args'))
              .expand((f) {
        final opType = p.basenameWithoutExtension(f.path);
        if (opType == 'all') {
          return [
            ['union', f.path],
            ['intersection', f.path],
            ['xor', f.path],
            ['difference', f.path],
          ];
        } else {
          return [
            [opType, f.path]
          ];
        }
      }).toList();

      group(target, () {
        for (final pair in resultPathsAndOperationTypes) {
          final String operationType = pair[0];
          final String resultPath = pair[1];
          final bool skipTest =
              targetsSkip.contains(target) || opsSkip.contains(operationType);

          test(operationType, () {
            final Map<String, dynamic> resultGeojson =
                jsonDecode(File(resultPath).readAsStringSync());

            final expected = resultGeojson['geometry']['coordinates'];
            final precisionOpt =
                resultGeojson['properties']?['options']?['precision'];

            if (precisionOpt != null) {
              setPrecision(precisionOpt);
            }
            final firstGeom = args[0];
            final moreGeoms = args.sublist(1);

            final result = switch (operationType) {
              'union' => union(firstGeom, moreGeoms),
              'intersection' => intersection(firstGeom, moreGeoms),
              'xor' => xor(firstGeom, moreGeoms),
              'difference' => difference(firstGeom, moreGeoms),
              _ => throw Exception(
                  "Unknown operation '$operationType' in $resultPath")
            };

            expect(result, equals(expected));
          }, skip: skipTest);
        }
      });
    }
  });
}

import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:polyclip_dart/polyclip.dart';


void main() {
  group('Vector Operations', () {
    // Unit tests for specific operations
    test('Cross Product Calculation', () {
      final pt1 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2));
      final pt2 = Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      
      final result = crossProduct(pt1, pt2);
      
      expect(result, equals(Decimal.fromInt(-2)));
    });

    test('Dot Product Calculation', () {
      final pt1 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2));
      final pt2 = Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
      
      final result = dotProduct(pt1, pt2);
      
      expect(result, equals(Decimal.fromInt(11)));
    });

    group('Vector Length', () {
      test('Horizontal Vector', () {
        final v = Vector(x: Decimal.fromInt(3), y: Decimal.zero);
        expect(length(v), equals(Decimal.fromInt(3)));
      });

      test('Vertical Vector', () {
        final v = Vector(x: Decimal.zero, y: Decimal.fromInt(-2));
        expect(length(v), equals(Decimal.fromInt(2)));
      });

      test('Pythagorean Triple (3-4-5)', () {
        final v = Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(4));
        expect(length(v), equals(Decimal.fromInt(5)));
      });
    });

    group('Angle Calculations', () {
      test('Parallel Vectors', () {
        final shared = Vector(x: Decimal.zero, y: Decimal.zero);
        final base = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
        final angle = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
        
        expect(sineOfAngle(shared, base, angle), equals(Decimal.zero));
        expect(cosineOfAngle(shared, base, angle), equals(Decimal.fromInt(1)));
      });

      test('Perpendicular Vectors (90 degrees)', () {
        final shared = Vector(x: Decimal.zero, y: Decimal.zero);
        final base = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
        final angle = Vector(x: Decimal.zero, y: Decimal.fromInt(-1));
        
        expect(sineOfAngle(shared, base, angle), equals(Decimal.fromInt(1)));
        expect(cosineOfAngle(shared, base, angle), equals(Decimal.zero));
      });

      test('45 Degree Angle', () {
        final shared = Vector(x: Decimal.zero, y: Decimal.zero);
        final base = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
        final angle = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(-1));
        
        // Check if the result is approximately sqrt(2)/2 ≈ 0.7071
        final sineResult = sineOfAngle(shared, base, angle);
        final cosineResult = cosineOfAngle(shared, base, angle);
        
        expect(sineResult.toDouble(), closeTo(0.7071067811865475, 1e-10));
        expect(cosineResult.toDouble(), closeTo(0.7071067811865475, 1e-10));
      });
    });

    group('Perpendicular Vector', () {
      test('Creates Perpendicular to Vertical Vector', () {
        final v = Vector(x: Decimal.zero, y: Decimal.fromInt(1));
        final r = perpendicular(v);
        
        expect(dotProduct(v, r), equals(Decimal.zero),
            reason: 'Perpendicular vectors should have dot product of 0');
        expect(crossProduct(v, r), isNot(equals(Decimal.zero)),
            reason: 'Cross product should not be 0');
      });

      test('Creates Perpendicular to Horizontal Vector', () {
        final v = Vector(x: Decimal.fromInt(1), y: Decimal.zero);
        final r = perpendicular(v);
        
        expect(dotProduct(v, r), equals(Decimal.zero));
        expect(crossProduct(v, r), isNot(equals(Decimal.zero)));
      });
    });

    group('Line Intersections', () {
      test('Vertical Intersection with Horizontal Line', () {
        final p = Vector(x: Decimal.fromInt(42), y: Decimal.fromInt(3));
        final v = Vector(x: Decimal.fromInt(-2), y: Decimal.zero);
        final x = Decimal.fromInt(37);
        
        final i = verticalIntersection(p, v, x)!;
        
        expect(i.x, equals(Decimal.fromInt(37)));
        expect(i.y, equals(Decimal.fromInt(3)));
      });

      test('Vertical Intersection with Vertical Line Returns Null', () {
        final p = Vector(x: Decimal.fromInt(42), y: Decimal.fromInt(3));
        final v = Vector(x: Decimal.zero, y: Decimal.fromInt(4));
        final x = Decimal.fromInt(37);
        
        expect(verticalIntersection(p, v, x), isNull);
      });

      test('Horizontal Intersection with Vertical Line', () {
        final p = Vector(x: Decimal.fromInt(42), y: Decimal.fromInt(3));
        final v = Vector(x: Decimal.zero, y: Decimal.fromInt(4));
        final y = Decimal.fromInt(37);
        
        final i = horizontalIntersection(p, v, y)!;
        
        expect(i.x, equals(Decimal.fromInt(42)));
        expect(i.y, equals(Decimal.fromInt(37)));
      });

      test('Horizontal Intersection with Horizontal Line Returns Null', () {
        final p = Vector(x: Decimal.fromInt(42), y: Decimal.fromInt(3));
        final v = Vector(x: Decimal.fromInt(-2), y: Decimal.zero);
        final y = Decimal.fromInt(37);
        
        expect(horizontalIntersection(p, v, y), isNull);
      });
    });

    group('General Line Intersection', () {
      final p1 = Vector(x: Decimal.fromInt(42), y: Decimal.fromInt(42));
      final p2 = Vector(x: Decimal.fromInt(-32), y: Decimal.fromInt(46));

      test('Parallel Lines Return Null', () {
        final v1 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2));
        final v2 = Vector(x: Decimal.fromInt(-1), y: Decimal.fromInt(-2));
        
        final i = intersection(p1, v1, p2, v2);
        
        expect(i, isNull);
      });

      test('Intersecting Horizontal and Vertical Lines', () {
        final v1 = Vector(x: Decimal.zero, y: Decimal.fromInt(2));
        final v2 = Vector(x: Decimal.fromInt(-1), y: Decimal.zero);
        
        final i = intersection(p1, v1, p2, v2)!;
        
        expect(i.x, equals(Decimal.fromInt(42)));
        expect(i.y, equals(Decimal.fromInt(46)));
      });

      test('Intersection Between 45° and 135° Lines', () {
        final v1 = Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(1));
        final v2 = Vector(x: Decimal.fromInt(-1), y: Decimal.fromInt(1));
        
        final i = intersection(p1, v1, p2, v2)!;
        
        expect(i.x, equals(Decimal.fromInt(7)));
        expect(i.y, equals(Decimal.fromInt(7)));
      });

      test('Consistency Test with High-Precision Coordinates', () {
        final p1 = Vector(
          x: Decimal.parse('0.523787'),
          y: Decimal.parse('51.281453'),
        );
        final v1 = Vector(
          x: Decimal.parse('0.0002729999999999677'),
          y: Decimal.parse('0.0002729999999999677'),
        );
        final p2 = Vector(
          x: Decimal.parse('0.523985'),
          y: Decimal.parse('51.281651'),
        );
        final v2 = Vector(
          x: Decimal.parse('0.000024999999999941735'),
          y: Decimal.parse('0.000049000000004184585'),
        );
        
        final i1 = intersection(p1, v1, p2, v2)!;
        final i2 = intersection(p2, v2, p1, v1)!;
        
        expect(i1.x, equals(i2.x), reason: 'Results should be consistent regardless of parameter order');
        expect(i1.y, equals(i2.y), reason: 'Results should be consistent regardless of parameter order');
      });
    });
  });
}
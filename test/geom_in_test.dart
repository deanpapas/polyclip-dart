import 'package:test/test.dart';
import 'package:polyclip_dart/polyclip.dart';

void main() {
  group('RingIn', () {
    test('create an interior ring', () {
      final poly = Poly([
        [
          [0.0, 0.0],
          [1.0, 1.0],
          [1.0, 0.0],
          [0.0, 0.0],
        ]
      ]);
      final multi = MultiPolyIn(poly, true);
      final parentPolyIn = multi.polys.first;

      final ring = RingIn([
        [0.0, 0.0],
        [1.0, 1.0],
        [1.0, 0.0],
        [0.0, 0.0],
      ], parentPolyIn, false);

      expect(ring.isExterior, isFalse);
    });
  });

  group('PolyIn', () {
    test('creation', () {
      final multiPoly = MultiPolyIn(
          Poly([
            [
              [0.0, 0.0],
              [10.0, 0.0],
              [10.0, 10.0],
              [0.0, 10.0],
              [0.0, 0.0],
            ],
            [
              [0.0, 0.0],
              [1.0, 1.0],
              [1.0, 0.0],
              [0.0, 0.0],
            ],
            [
              [2.0, 2.0],
              [2.0, 3.0],
              [3.0, 3.0],
              [3.0, 2.0],
              [2.0, 2.0],
            ],
          ]),
          true);

      final poly = multiPoly.polys.first;

      expect(poly.multiPoly, same(multiPoly));
      expect(poly.exteriorRing.segments.length, equals(4));
      expect(poly.interiorRings.length, equals(2));
      expect(poly.interiorRings[0].segments.length, equals(3));
      expect(poly.interiorRings[1].segments.length, equals(4));
      expect(poly.getSweepEvents().length, equals(22));
    });
  });

  group('MultiPolyIn', () {
    test('creation with multipoly', () {
      final multipoly = MultiPolyIn(
          MultiPoly([
            Poly([
              [
                [0.0, 0.0],
                [1.0, 1.0],
                [0.0, 1.0],
                [0.0, 0.0],
              ]
            ]),
            Poly([
              [
                [0.0, 0.0],
                [4.0, 0.0],
                [4.0, 9.0],
                [0.0, 0.0],
              ],
              [
                [2.0, 2.0],
                [3.0, 3.0],
                [3.0, 2.0],
                [2.0, 2.0],
              ]
            ])
          ]),
          true);

      expect(multipoly.polys.length, equals(2));
      expect(multipoly.getSweepEvents().length, equals(18));
    });

    test('creation with poly', () {
      final multipoly = MultiPolyIn(
          Poly([
            [
              [0.0, 0.0],
              [1.0, 1.0],
              [0.0, 1.0],
              [0.0, 0.0],
            ]
          ]),
          true);

      expect(multipoly.polys.length, equals(1));
      expect(multipoly.getSweepEvents().length, equals(6));
    });

    test('third or more coordinates are ignored', () {
      final multipoly = MultiPolyIn(
          Poly([
            [
              [0.0, 0.0, 42.0],
              [1.0, 1.0, 128.0],
              [0.0, 1.0, 84.0],
              [0.0, 0.0, 42.0],
            ].map((c) => [c[0], c[1]]).toList()
          ]),
          true);

      expect(multipoly.polys.length, equals(1));
      expect(multipoly.getSweepEvents().length, equals(6));
    });

    test('creation with invalid input', () {
      expect(
        () => MultiPolyIn("not a geometry" as dynamic, true),
        throwsA(isA<TypeError>()),
      );
    });

    test('creation with point', () {
      expect(() => MultiPolyIn([42, 43] as dynamic, true),
          throwsA(isA<TypeError>()));
    });

    test('creation with ring', () {
      expect(
          () => MultiPolyIn(
              [
                [0.0, 0.0],
                [1.0, 1.0],
                [1.0, 0.0]
              ] as dynamic,
              true),
          throwsA(isA<TypeError>()));
    });

    test('creation with empty polygon / ring', () {
      expect(() => MultiPolyIn(Poly([]), true),
          throwsA(predicate((e) => e.toString().contains('no rings'))));
    });

    test('creation with empty ring / point', () {
      expect(
          () => MultiPolyIn(Poly([[]]), true),
          throwsA(predicate((e) =>
              e.toString().contains('not a valid Polygon or MultiPolygon'))));
    });

    test('creation with multipolygon with invalid coordinate', () {
      expect(
          () => MultiPolyIn(
              MultiPoly([
                Poly([
                  [
                    [0.0, 0.0],
                    [0.0, 1.0],
                    [[] as dynamic, 0.0] // invalid type
                  ]
                ])
              ]),
              true),
          throwsA(isA<TypeError>()));
    });

    test('creation with polygon with missing coordinate', () {
      expect(
          () => MultiPolyIn(
              Poly([
                [
                  [0.0, 0.0],
                  [1.0],
                  [1.0, 1.0]
                ] as dynamic
              ]),
              true),
          throwsA(predicate((e) =>
              e.toString().contains('not a valid Polygon or MultiPolygon'))));
    });

    test('creation with multipolygon with invalid coordinate', () {
      final invalidRing = [
        [0.0, 0.0],
        [0.0, 1.0],
        [double.nan, 0.0], // invalid format for Decimal.parse
        [0.0, 0.0]
      ];

      final poly = Poly([invalidRing]);
      final multi = MultiPoly([poly]);

      expect(
        () => MultiPolyIn(multi, true),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

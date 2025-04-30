import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:polyclip_dart/polyclip.dart';

/// Helper function to compare two Bbox objects or check both are null.
/// If they're not null, it compares each field.
void expectBboxEquals(PolyclipBBox? actual, PolyclipBBox? expected, {String? reason}) {
  if (actual == null && expected == null) {
    // both null is considered "equal"
    return;
  }
  expect(actual, isNotNull,
      reason: reason ?? 'Expected bbox is not null, but actual is null');
  expect(expected, isNotNull,
      reason: reason ?? 'Actual bbox is not null, but expected is null');

  final a = actual!;
  final e = expected!;

  expect(a.ll.x, e.ll.x, reason: reason ?? 'Mismatch in ll.x');
  expect(a.ll.y, e.ll.y, reason: reason ?? 'Mismatch in ll.y');
  expect(a.ur.x, e.ur.x, reason: reason ?? 'Mismatch in ur.x');
  expect(a.ur.y, e.ur.y, reason: reason ?? 'Mismatch in ur.y');
}

void main() {
  group('Bbox Tests', () {
    group('isInBbox', () {
      test('outside', () {
        final bbox = PolyclipBBox(
          ll: Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2)),
          ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
        );

        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.zero, y: Decimal.fromInt(3)),
          ),
          isFalse,
          reason: 'Point x=0 is left of the bbox',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(30)),
          ),
          isFalse,
          reason: 'Point y=30 is above the bbox',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(-30)),
          ),
          isFalse,
          reason: 'Point y=-30 is below the bbox',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(9), y: Decimal.fromInt(3)),
          ),
          isFalse,
          reason: 'Point x=9 is right of the bbox',
        );
      });

      test('inside', () {
        final bbox = PolyclipBBox(
          ll: Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2)),
          ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
        );

        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(2)),
          ),
          isTrue,
          reason: 'Matches lower-left corner exactly',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
          ),
          isTrue,
          reason: 'Matches upper-right corner exactly',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(6)),
          ),
          isTrue,
          reason: 'Touches left side and top side',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(2)),
          ),
          isTrue,
          reason: 'Touches right side and bottom side',
        );
        expect(
          isInBbox(
            bbox,
            Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
          ),
          isTrue,
          reason: 'Clearly inside',
        );
      });

      test('barely inside & outside', () {
        // Approximation of Number.EPSILON
        final decimalEpsilon = Decimal.parse('2.220446049250313e-16');

        final bbox = PolyclipBBox(
          ll: Vector(x: Decimal.fromInt(1), y: Decimal.parse('0.8')),
          ur: Vector(x: Decimal.parse('1.2'), y: Decimal.fromInt(6)),
        );

        // "Barely inside"
        expect(
          isInBbox(
            bbox,
            Vector(
              x: Decimal.parse('1.2') - decimalEpsilon,
              y: Decimal.fromInt(6),
            ),
          ),
          isTrue,
          reason: 'Point is just within the max X boundary',
        );

        // "Barely outside"
        expect(
          isInBbox(
            bbox,
            Vector(
              x: Decimal.parse('1.2') + decimalEpsilon,
              y: Decimal.fromInt(6),
            ),
          ),
          isFalse,
          reason: 'Point is just beyond the max X boundary',
        );

        // Barely inside again
        expect(
          isInBbox(
            bbox,
            Vector(
              x: Decimal.fromInt(1),
              y: Decimal.parse('0.8') + decimalEpsilon,
            ),
          ),
          isTrue,
          reason: 'Point is just above the min Y boundary',
        );

        // Barely outside
        expect(
          isInBbox(
            bbox,
            Vector(
              x: Decimal.fromInt(1),
              y: Decimal.parse('0.8') - decimalEpsilon,
            ),
          ),
          isFalse,
          reason: 'Point is just below the min Y boundary',
        );
      });
    });

    group('getBboxOverlap', () {
      final b1 = PolyclipBBox(
        ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
        ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
      );

      group('disjoint - none', () {
        test('above', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(7)),
            ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(8)),
          );
          final overlap = getBboxOverlap(b1, b2);
          expect(overlap, isNull, reason: 'b2 is entirely above and to the right of b1');
        });

        test('left', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(5)),
            ur: Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(8)),
          );
          final overlap = getBboxOverlap(b1, b2);
          expect(overlap, isNull, reason: 'b2 is entirely left of b1');
        });

        test('down', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
            ur: Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(3)),
          );
          final overlap = getBboxOverlap(b1, b2);
          expect(overlap, isNull, reason: 'b2 is entirely below b1');
        });

        test('right', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(12), y: Decimal.fromInt(1)),
            ur: Vector(x: Decimal.fromInt(14), y: Decimal.fromInt(9)),
          );
          final overlap = getBboxOverlap(b1, b2);
          expect(overlap, isNull, reason: 'b2 is entirely to the right of b1');
        });
      });

      group('touching - one point', () {
        test('upper right corner of b1', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
            ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(8)),
          );
          final overlap = getBboxOverlap(b1, b2);

          expect(overlap, isNotNull);
          expectBboxEquals(
            overlap,
            PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
            ),
          );
        });

        test('upper left corner of b1', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(6)),
            ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(8)),
          );
          final overlap = getBboxOverlap(b1, b2);

          expect(overlap, isNotNull);
          expectBboxEquals(
            overlap,
            PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
            ),
          );
        });

        test('lower left corner of b1', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(0), y: Decimal.fromInt(0)),
            ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
          );
          final overlap = getBboxOverlap(b1, b2);

          expect(overlap, isNotNull);
          expectBboxEquals(
            overlap,
            PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
            ),
          );
        });

        test('lower right corner of b1', () {
          final b2 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(0)),
            ur: Vector(x: Decimal.fromInt(12), y: Decimal.fromInt(4)),
          );
          final overlap = getBboxOverlap(b1, b2);

          expect(overlap, isNotNull);
          expectBboxEquals(
            overlap,
            PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
            ),
          );
        });
      });

      group('overlapping - two points', () {
        group('full overlap', () {
          test('matching bboxes', () {
            final overlap = getBboxOverlap(b1, b1);
            expectBboxEquals(
              overlap,
              b1,
              reason: 'Identical bboxes should return themselves',
            );
          });

          test('one side & two corners matching', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(overlap, b2);
          });

          test('one corner matching, part of two sides', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(overlap, b2);
          });

          test('part of a side matching, no corners', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.parse('4.5'), y: Decimal.parse('4.5')),
              ur: Vector(x: Decimal.parse('5.5'), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(overlap, b2);
          });

          test('completely enclosed - no side or corner matching', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.parse('4.5'), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.parse('5.5'), y: Decimal.parse('5.5')),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(overlap, b2);
          });
        });

        group('partial overlap', () {
          test('full side overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(4)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
              ),
            );
          });

          test('partial side overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.parse('4.5')),
              ur: Vector(x: Decimal.fromInt(7), y: Decimal.parse('5.5')),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(5), y: Decimal.parse('4.5')),
                ur: Vector(x: Decimal.fromInt(6), y: Decimal.parse('5.5')),
              ),
            );
          });

          test('corner overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(7)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
                ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
              ),
            );
          });
        });
      });

      group('line bboxes', () {
        group('vertical line & normal', () {
          test('no overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(3)),
              ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(0)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
              ),
            );
          });

          test('line overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(0)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(9)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
              ),
            );
          });
        });

        group('horizontal line & normal', () {
          test('no overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(3), y: Decimal.fromInt(7)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(7)),
            );
            final overlap = getBboxOverlap(b1, b2);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
                ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ),
            );
          });

          test('line overlap', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expectBboxEquals(overlap, b2);
          });
        });

        group('two vertical lines', () {
          final v1 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
            ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
          );

          test('no overlap', () {
            final v2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(7)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(8)),
            );
            final overlap = getBboxOverlap(v1, v2);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final v2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(3)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
            );
            final overlap = getBboxOverlap(v1, v2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
              ),
            );
          });

          test('line overlap', () {
            final v2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(3)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(v1, v2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(5)),
              ),
            );
          });
        });

        group('two horizontal lines', () {
          final h1 = PolyclipBBox(
            ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
            ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
          );

          test('no overlap', () {
            final h2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(h1, h2);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final h2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(h1, h2);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
                ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
              ),
            );
          });

          test('line overlap', () {
            final h2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(7), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(h1, h2);

            expectBboxEquals(overlap, h1);
          });
        });

        group('horizontal and vertical lines', () {
          test('no overlap', () {
            final h1 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(6)),
            );
            final v1 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(7)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(9)),
            );
            final overlap = getBboxOverlap(h1, v1);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final h1 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(6)),
            );
            final v1 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(9)),
            );
            final overlap = getBboxOverlap(h1, v1);

            expect(overlap, isNotNull);
            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
                ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(6)),
              ),
            );
          });
        });

        group('produced line box', () {
          test('horizontal', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(8)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
                ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
              ),
            );
          });

          test('vertical', () {
            final b2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(2)),
              ur: Vector(x: Decimal.fromInt(8), y: Decimal.fromInt(8)),
            );
            final overlap = getBboxOverlap(b1, b2);

            expectBboxEquals(
              overlap,
              PolyclipBBox(
                ll: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(4)),
                ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(6)),
              ),
            );
          });
        });
      });

      group('point bboxes', () {
        group('point & normal', () {
          test('no overlap', () {
            final p = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
              ur: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
            );
            final overlap = getBboxOverlap(b1, p);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final p = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(b1, p);
            expectBboxEquals(overlap, p);
          });
        });

        group('point & line', () {
          test('no overlap', () {
            final p = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
              ur: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
            );
            final l = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(8)),
            );
            final overlap = getBboxOverlap(l, p);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final p = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
            );
            final l = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(6), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(l, p);
            expectBboxEquals(overlap, p);
          });
        });

        group('point & point', () {
          test('no overlap', () {
            final p1 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
              ur: Vector(x: Decimal.fromInt(2), y: Decimal.fromInt(2)),
            );
            final p2 = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
              ur: Vector(x: Decimal.fromInt(4), y: Decimal.fromInt(6)),
            );
            final overlap = getBboxOverlap(p1, p2);
            expect(overlap, isNull);
          });

          test('point overlap', () {
            final p = PolyclipBBox(
              ll: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
              ur: Vector(x: Decimal.fromInt(5), y: Decimal.fromInt(5)),
            );
            final overlap = getBboxOverlap(p, p);
            expectBboxEquals(overlap, p);
          });
        });
      });
    });
  });
}

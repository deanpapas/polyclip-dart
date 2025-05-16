import 'package:decimal/decimal.dart';

typedef CompareDecimals = int Function(Decimal a, Decimal b);

CompareDecimals compareWithDecimalEpsilon([Decimal? eps]) {
  final bool Function(Decimal a, Decimal b) almostEqual = eps != null
      ? (a, b) => (b - a).abs() <= eps
      : (_, __) => false;

  return (Decimal a, Decimal b) {
    if (almostEqual(a, b)) return 0;
    return a.compareTo(b);
  };
}

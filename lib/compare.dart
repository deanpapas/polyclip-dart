import 'package:decimal/decimal.dart';

typedef CompareDecimals = int Function(Decimal a, Decimal b);

/// Returns a comparison function for Decimal values.
/// If [eps] is provided, values within [eps] of each other are considered equal.
CompareDecimals compareWithDecimalEpsilon(Decimal eps) {
  return (Decimal a, Decimal b) {
    final diff = (b - a).abs();
    final result = diff <= eps;
    if (result) return 0;
    return a.compareTo(b);
  };
}

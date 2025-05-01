import 'package:decimal/decimal.dart';

typedef CompareDecimals = int Function(Decimal a, Decimal b);

/// Returns a comparison function for Decimal values.
/// If [eps] is provided, values within [eps] of each other are considered equal.
CompareDecimals compareWithDecimalEpsilon(Decimal eps) {
  return (Decimal a, Decimal b) {
    final diff = (b - a).abs();
    final result = diff <= eps;
    print('[compareWithDecimalEpsilon] a=$a, b=$b, |diff|=$diff, eps=$eps, equal=$result');
    if (result) return 0;
    return a.compareTo(b);
  };
}

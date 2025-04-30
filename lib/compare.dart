import 'package:decimal/decimal.dart';

typedef CompareDecimals = int Function(Decimal a, Decimal b);

/// Returns a comparison function for Decimal values.
/// If [eps] is provided, values within [eps] of each other are considered equal.
CompareDecimals compareWithEpsilon([double? eps]) {
  // Define an "almost equal" function if epsilon is provided, otherwise return a function that always returns false
  final almostEqual = eps != null
      ? (Decimal a, Decimal b) => (b - a).abs() <= Decimal.parse(eps.toString())
      : (Decimal a, Decimal b) => false;

  // Return the comparison function
  return (Decimal a, Decimal b) {
    if (almostEqual(a, b)) return 0;
    return a.compareTo(b);
  };
}
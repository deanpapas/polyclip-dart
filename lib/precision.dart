import 'compare.dart';
import 'orient.dart';
import 'snap.dart';
import 'package:decimal/decimal.dart';

/// Configuration object that holds precision-related functions for geometric operations.
class PrecisionConfig {
  /// Function to compare Decimal values with a specified epsilon.
  final CompareDecimals compare;

  /// Function to snap Vector coordinates with a specified epsilon.
  final Snap snap;

  /// Function to test collinearity of points with a specified epsilon.
  final CollinearityTest orient;

  /// Function to recreate this precision configuration with the current epsilon.
  final PrecisionConfig Function() reset;

  /// Function to create a new precision configuration with a specified epsilon.
  final PrecisionConfig Function([double? epsilon]) set;

  PrecisionConfig({
    required this.compare,
    required this.snap,
    required this.orient,
    required this.reset,
    required this.set,
  });
}

// ⚠ Global reference — needs to be updated explicitly
PrecisionConfig precision = createPrecisionConfig();

/// THIS is what you must call to reset the global `precision` instance
void setPrecision([double? eps]) {
  print('[setPrecision] replacing global precision with eps: $eps');
  precision = createPrecisionConfig(eps);
}

/// Uses compareWithDecimalEpsilon to avoid `eps = 0` bugs
PrecisionConfig createPrecisionConfig([double? eps]) {
  print('[createPrecisionConfig] eps received: $eps');
  final Decimal decimalEps = eps != null
      ? Decimal.parse('1e-20') // Hardcoded to avoid float drift
      : Decimal.zero;

  print('[createPrecisionConfig] using decimal epsilon: $decimalEps');

  final compareFunc = compareWithDecimalEpsilon(decimalEps);
  final snapFunc = snap(eps: eps);
  final orientFunc = createCollinearityChecker(eps);

  PrecisionConfig Function() resetFunc = () => createPrecisionConfig(eps);
  PrecisionConfig Function([double?]) setFunc =
      ([double? newEps]) => createPrecisionConfig(newEps);

  return PrecisionConfig(
    compare: compareFunc,
    snap: snapFunc,
    orient: orientFunc,
    reset: resetFunc,
    set: setFunc,
  );
}

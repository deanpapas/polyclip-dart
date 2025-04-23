import 'compare.dart';
import 'orient.dart';
import 'snap.dart';

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

/// Creates a precision configuration with the specified epsilon value.
PrecisionConfig createPrecisionConfig([double? eps]) {
  // Create functions using the specified epsilon
  final compareFunc = compareWithEpsilon(eps);
  final snapFunc = snap(eps: eps);
  final orientFunc = createCollinearityChecker(eps);
  
  // Create a function that recreates this configuration
  PrecisionConfig Function() resetFunc = () => createPrecisionConfig(eps);
  
  // Create a function that creates a new configuration with a new epsilon
  PrecisionConfig Function([double?]) setFunc = ([double? newEps]) => 
      createPrecisionConfig(newEps);
  
  return PrecisionConfig(
    compare: compareFunc,
    snap: snapFunc,
    orient: orientFunc,
    reset: resetFunc,
    set: setFunc,
  );
}

/// Global precision configuration, initialized with default settings.
PrecisionConfig precision = createPrecisionConfig();
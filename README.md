# polyclip-dart

A Dart port of the [polyclip-ts](https://github.com/deanpapas/polyclip-ts) package for polygon clipping operations. This library provides robust, high-precision polygon boolean operations (union, intersection, difference, xor) using the [Decimal](https://pub.dev/packages/decimal) package for accurate arithmetic.

## Features

- Perform boolean operations (union, intersection, difference, xor) on polygons.
- Handles complex polygons, including those with holes.
- Uses arbitrary-precision arithmetic for reliable geometric calculations.
- Includes bounding box utilities and geometric primitives.

## Installation

Add to your pubspec.yaml:

```yaml
dependencies:
  polyclip_dart: ^0.1.0
```

Then run:

```sh
dart pub get
```

## Usage

```dart
import 'package:polyclip_dart/polyclip.dart';

void main() {
  // Define your polygons as lists of Vector points
  final polygonA = [Vector(x: Decimal.fromInt(0), y: Decimal.fromInt(0)), ...];
  final polygonB = [Vector(x: Decimal.fromInt(1), y: Decimal.fromInt(1)), ...];

  // Perform a union operation
  final result = union([polygonA, polygonB]);
  print(result);
}
```

See the test directory for more usage examples.

## Development

- Requires Dart SDK >=3.0.0 <4.0.0.
- Run tests with:
  ```sh
  dart test
  ```

## Contributing

Contributions are welcome! Please open issues or pull requests on [GitHub](https://github.com/deanpapas/polyclip-dart).

## License

MIT License. See LICENSE for details.
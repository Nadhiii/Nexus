/// Helper Extensions for Common Dart/Flutter operations
library;

/// Extension to safely access list elements without index out of bounds
extension ListExtension<T> on List<T> {
  /// Returns the element at [index] or null if index is out of bounds
  T? elementAtOrNull(int index) {
    return index < length ? this[index] : null;
  }
}

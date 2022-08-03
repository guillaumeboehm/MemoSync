/// Extends the string object with some usefull functions
extension StringExtension on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

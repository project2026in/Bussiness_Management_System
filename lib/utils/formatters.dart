class Formatters {
  /// Capitalizes the first letter of each word in a string.
  /// Example: 'hafis mohamed' -> 'Hafis Mohamed'
  static String capitalizeWords(String input) {
    if (input.trim().isEmpty) return input.trim();
    
    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class Helper {
  static bool IsDevanagari(String text) {
    final devanagariRegex = RegExp(r'[\u0900-\u097F]');
    return devanagariRegex.hasMatch(text);
  }
}

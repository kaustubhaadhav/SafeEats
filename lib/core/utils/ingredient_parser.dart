/// Utility class for parsing and normalizing ingredient text
class IngredientParser {
  /// Parses a raw ingredient text and returns a list of normalized ingredient names
  static List<String> parse(String? ingredientsText) {
    if (ingredientsText == null || ingredientsText.isEmpty) return [];

    // Remove common noise patterns
    String cleaned = ingredientsText
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), ' ') // Remove parenthetical info
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ') // Remove bracketed info
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ') // Remove braced info
        .replaceAll(RegExp(r'\d+\.?\d*\s*%'), '') // Remove percentages
        .replaceAll(RegExp(r'contains less than \d+% of:?', caseSensitive: false), ',')
        .replaceAll(RegExp(r'contains:?', caseSensitive: false), ',')
        .replaceAll(RegExp(r'ingredients:?', caseSensitive: false), '')
        .replaceAll(RegExp(r'and/or', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\bor\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), ',')
        .replaceAll(RegExp(r'[*†‡§®™©]'), '') // Remove reference symbols
        .replaceAll(RegExp(r'\.(?!\d)'), ',') // Replace periods with commas
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    // Split by common delimiters
    List<String> ingredients = cleaned
        .split(RegExp(r'[,;:]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 1)
        .map((s) => normalize(s))
        .where((s) => s.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();

    return ingredients;
  }

  /// Normalizes an ingredient name for matching
  static String normalize(String ingredient) {
    return ingredient
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extracts E-numbers from ingredient text
  static List<String> extractENumbers(String ingredientsText) {
    final eNumberRegex = RegExp(r'e\s*\d{3,4}[a-z]?', caseSensitive: false);
    final matches = eNumberRegex.allMatches(ingredientsText.toLowerCase());
    
    return matches
        .map((m) => m.group(0)!.replaceAll(RegExp(r'\s'), '').toLowerCase())
        .toSet()
        .toList();
  }

  /// Checks if an ingredient text mentions common preservatives
  static bool containsPreservatives(String ingredientsText) {
    final preservativeKeywords = [
      'preservative',
      'sodium benzoate',
      'potassium sorbate',
      'calcium propionate',
      'sodium nitrite',
      'sodium nitrate',
      'bha',
      'bht',
      'tbhq',
      'e200',
      'e202',
      'e211',
      'e250',
      'e251',
      'e320',
      'e321',
    ];

    final lowerText = ingredientsText.toLowerCase();
    return preservativeKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Checks if an ingredient text mentions artificial colors
  static bool containsArtificialColors(String ingredientsText) {
    final colorKeywords = [
      'artificial color',
      'fd&c',
      'red 40',
      'red 3',
      'yellow 5',
      'yellow 6',
      'blue 1',
      'blue 2',
      'green 3',
      'caramel color',
      'e102',
      'e110',
      'e122',
      'e123',
      'e124',
      'e127',
      'e129',
      'e131',
      'e132',
      'e133',
      'e150',
      'e151',
      'e155',
    ];

    final lowerText = ingredientsText.toLowerCase();
    return colorKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Checks if an ingredient text mentions artificial sweeteners
  static bool containsArtificialSweeteners(String ingredientsText) {
    final sweetenerKeywords = [
      'aspartame',
      'sucralose',
      'saccharin',
      'acesulfame',
      'neotame',
      'advantame',
      'e950',
      'e951',
      'e952',
      'e954',
      'e955',
      'e961',
      'e962',
    ];

    final lowerText = ingredientsText.toLowerCase();
    return sweetenerKeywords.any((keyword) => lowerText.contains(keyword));
  }
}
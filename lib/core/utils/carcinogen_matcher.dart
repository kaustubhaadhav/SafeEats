import '../../features/carcinogen/domain/entities/carcinogen.dart';
import 'ingredient_parser.dart';

/// Result of matching ingredients against carcinogen database
class CarcinogenMatchResult {
  final String ingredient;
  final List<Carcinogen> matchedCarcinogens;

  CarcinogenMatchResult({
    required this.ingredient,
    required this.matchedCarcinogens,
  });
}

/// Utility class for matching ingredients against known carcinogens
class CarcinogenMatcher {
  final List<Carcinogen> _carcinogens;

  CarcinogenMatcher(this._carcinogens);

  /// Finds all carcinogens that match the given ingredients
  List<CarcinogenMatchResult> findMatches(List<String> ingredients) {
    List<CarcinogenMatchResult> results = [];

    for (String ingredient in ingredients) {
      String normalized = IngredientParser.normalize(ingredient);
      List<Carcinogen> matchedCarcinogens = [];

      for (Carcinogen carcinogen in _carcinogens) {
        if (_isMatch(normalized, carcinogen)) {
          matchedCarcinogens.add(carcinogen);
        }
      }

      if (matchedCarcinogens.isNotEmpty) {
        results.add(CarcinogenMatchResult(
          ingredient: ingredient,
          matchedCarcinogens: matchedCarcinogens,
        ));
      }
    }

    return results;
  }

  /// Gets all unique carcinogens from match results
  List<Carcinogen> getUniqueCarcinogens(List<CarcinogenMatchResult> results) {
    final Set<String> seen = {};
    final List<Carcinogen> unique = [];

    for (final result in results) {
      for (final carcinogen in result.matchedCarcinogens) {
        if (!seen.contains(carcinogen.id)) {
          seen.add(carcinogen.id);
          unique.add(carcinogen);
        }
      }
    }

    return unique;
  }

  /// Calculates the overall risk level based on detected carcinogens
  RiskLevel calculateOverallRisk(List<Carcinogen> carcinogens) {
    if (carcinogens.isEmpty) return RiskLevel.safe;

    int maxRisk = carcinogens
        .map((c) => c.riskLevel.value)
        .reduce((a, b) => a > b ? a : b);

    return RiskLevel.fromValue(maxRisk);
  }

  bool _isMatch(String ingredient, Carcinogen carcinogen) {
    String normalizedName = _normalize(carcinogen.name);

    // Direct match - check if ingredient contains carcinogen name or vice versa
    if (_containsMatch(ingredient, normalizedName)) {
      return true;
    }

    // Check aliases
    for (String alias in carcinogen.aliases) {
      String normalizedAlias = _normalize(alias);
      if (_containsMatch(ingredient, normalizedAlias)) {
        return true;
      }
    }

    // Check E-numbers
    if (carcinogen.aliases.any((alias) {
      final eNumberMatch = RegExp(r'^e\d{3,4}[a-z]?$', caseSensitive: false);
      if (eNumberMatch.hasMatch(alias)) {
        return ingredient.contains(alias.toLowerCase().replaceAll(' ', ''));
      }
      return false;
    })) {
      return true;
    }

    // Fuzzy matching for longer ingredient names
    if (_fuzzyMatch(ingredient, normalizedName)) {
      return true;
    }

    return false;
  }

  bool _containsMatch(String ingredient, String target) {
    // Exact word match
    if (ingredient == target) return true;
    
    // Check if target is a complete word within ingredient
    final wordBoundary = RegExp(r'\b' + RegExp.escape(target) + r'\b');
    if (wordBoundary.hasMatch(ingredient)) return true;
    
    // Check if ingredient is a complete word within target
    final reverseWordBoundary = RegExp(r'\b' + RegExp.escape(ingredient) + r'\b');
    if (ingredient.length >= 4 && reverseWordBoundary.hasMatch(target)) return true;
    
    return false;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  bool _fuzzyMatch(String a, String b) {
    // Only apply fuzzy matching for longer strings
    if (a.length < 5 || b.length < 5) return false;

    // Check if one string starts with the other
    if (a.startsWith(b) || b.startsWith(a)) return true;

    // Levenshtein distance check for similar strings
    int distance = _levenshteinDistance(a, b);
    int maxLength = a.length > b.length ? a.length : b.length;

    // Allow 15% difference for longer strings
    return distance <= (maxLength * 0.15).ceil();
  }

  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<List<int>> dp = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,      // deletion
          dp[i][j - 1] + 1,      // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[a.length][b.length];
  }
}
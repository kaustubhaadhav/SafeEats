import 'dart:convert';

/// Response model from the SafeEats backend /scan endpoint
class BackendScanResponse {
  final String productName;
  final List<BackendIngredientResult> ingredients;
  final String overallRisk;
  final bool cached;
  final String rulesVersion;

  const BackendScanResponse({
    required this.productName,
    required this.ingredients,
    required this.overallRisk,
    required this.cached,
    required this.rulesVersion,
  });

  factory BackendScanResponse.fromJson(Map<String, dynamic> json) {
    return BackendScanResponse(
      productName: json['product_name'] as String? ?? 'Unknown Product',
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((i) => BackendIngredientResult.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      overallRisk: json['overall_risk'] as String? ?? 'safe',
      cached: json['cached'] as bool? ?? false,
      rulesVersion: json['rules_version'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'overall_risk': overallRisk,
      'cached': cached,
      'rules_version': rulesVersion,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory BackendScanResponse.fromJsonString(String jsonString) {
    return BackendScanResponse.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

/// Individual ingredient result from the backend
class BackendIngredientResult {
  final String raw;
  final String canonical;
  final String risk;
  final String? source;
  final String? notes;

  const BackendIngredientResult({
    required this.raw,
    required this.canonical,
    required this.risk,
    this.source,
    this.notes,
  });

  factory BackendIngredientResult.fromJson(Map<String, dynamic> json) {
    return BackendIngredientResult(
      raw: json['raw'] as String? ?? '',
      canonical: json['canonical'] as String? ?? '',
      risk: json['risk'] as String? ?? 'safe',
      source: json['source'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'canonical': canonical,
      'risk': risk,
      'source': source,
      'notes': notes,
    };
  }
}
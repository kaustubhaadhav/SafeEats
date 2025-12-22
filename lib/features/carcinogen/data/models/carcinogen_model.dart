import 'dart:convert';
import '../../domain/entities/carcinogen.dart';

class CarcinogenModel extends Carcinogen {
  const CarcinogenModel({
    required super.id,
    required super.name,
    required super.aliases,
    super.casNumber,
    required super.source,
    super.classification,
    required super.riskLevel,
    required super.description,
    required super.commonFoods,
    super.sourceUrl,
  });

  factory CarcinogenModel.fromJson(Map<String, dynamic> json) {
    return CarcinogenModel(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: _parseStringList(json['aliases']),
      casNumber: json['cas_number'] as String?,
      source: _parseSource(json['source'] as String),
      classification: json['classification'] as String?,
      riskLevel: RiskLevel.fromValue(json['risk_level'] as int),
      description: json['description'] as String? ?? '',
      commonFoods: _parseStringList(json['common_foods']),
      sourceUrl: json['source_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aliases': jsonEncode(aliases),
      'cas_number': casNumber,
      'source': source == CarcinogenSource.iarc ? 'IARC' : 'PROP65',
      'classification': classification,
      'risk_level': riskLevel.value,
      'description': description,
      'common_foods': jsonEncode(commonFoods),
      'source_url': sourceUrl,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // If JSON parsing fails, try splitting by comma
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  static CarcinogenSource _parseSource(String source) {
    switch (source.toUpperCase()) {
      case 'IARC':
        return CarcinogenSource.iarc;
      case 'PROP65':
      case 'PROP 65':
      case 'CALIFORNIA PROP 65':
        return CarcinogenSource.prop65;
      default:
        return CarcinogenSource.iarc;
    }
  }
}
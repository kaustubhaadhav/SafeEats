import 'package:equatable/equatable.dart';

enum CarcinogenSource { iarc, prop65 }

enum RiskLevel {
  safe(0, 'Safe', 0xFF22C55E),
  low(1, 'Low Risk', 0xFF84CC16),
  medium(2, 'Medium Risk', 0xFFF59E0B),
  high(3, 'High Risk', 0xFFF97316),
  critical(4, 'Critical Risk', 0xFFEF4444);

  final int value;
  final String label;
  final int color;

  const RiskLevel(this.value, this.label, this.color);

  static RiskLevel fromValue(int value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevel.safe,
    );
  }

  String get description {
    switch (this) {
      case RiskLevel.safe:
        return 'No known carcinogens detected in this product.';
      case RiskLevel.low:
        return 'Contains substances with limited evidence of carcinogenicity.';
      case RiskLevel.medium:
        return 'Contains substances possibly carcinogenic to humans (IARC Group 2B or similar).';
      case RiskLevel.high:
        return 'Contains substances probably carcinogenic to humans (IARC Group 2A or similar).';
      case RiskLevel.critical:
        return 'Contains substances known to be carcinogenic to humans (IARC Group 1).';
    }
  }

  String get shortDescription {
    switch (this) {
      case RiskLevel.safe:
        return 'No concerns found';
      case RiskLevel.low:
        return 'Minor concerns';
      case RiskLevel.medium:
        return 'Possible carcinogen';
      case RiskLevel.high:
        return 'Probable carcinogen';
      case RiskLevel.critical:
        return 'Known carcinogen';
    }
  }
}

class Carcinogen extends Equatable {
  final String id;
  final String name;
  final List<String> aliases;
  final String? casNumber;
  final CarcinogenSource source;
  final String? classification;
  final RiskLevel riskLevel;
  final String description;
  final List<String> commonFoods;
  final String? sourceUrl;

  const Carcinogen({
    required this.id,
    required this.name,
    required this.aliases,
    this.casNumber,
    required this.source,
    this.classification,
    required this.riskLevel,
    required this.description,
    required this.commonFoods,
    this.sourceUrl,
  });

  String get sourceName {
    switch (source) {
      case CarcinogenSource.iarc:
        return 'IARC (International Agency for Research on Cancer)';
      case CarcinogenSource.prop65:
        return 'California Proposition 65';
    }
  }

  String get sourceShortName {
    switch (source) {
      case CarcinogenSource.iarc:
        return 'IARC';
      case CarcinogenSource.prop65:
        return 'Prop 65';
    }
  }

  @override
  List<Object?> get props => [id, name, source];
}
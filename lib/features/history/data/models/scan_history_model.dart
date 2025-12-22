import 'dart:convert';
import '../../../carcinogen/domain/entities/carcinogen.dart';
import '../../domain/entities/scan_history.dart';

class ScanHistoryModel extends ScanHistory {
  const ScanHistoryModel({
    super.id,
    required super.barcode,
    super.productName,
    super.brand,
    super.imageUrl,
    required super.ingredients,
    required super.detectedCarcinogenIds,
    required super.overallRiskLevel,
    required super.scannedAt,
  });

  factory ScanHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScanHistoryModel(
      id: json['id'] as int?,
      barcode: json['barcode'] as String,
      productName: json['product_name'] as String?,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      ingredients: _parseStringList(json['ingredients']),
      detectedCarcinogenIds: _parseStringList(json['detected_carcinogens']),
      overallRiskLevel: RiskLevel.fromValue(json['overall_risk_level'] as int? ?? 0),
      scannedAt: DateTime.parse(json['scanned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'product_name': productName,
      'brand': brand,
      'image_url': imageUrl,
      'ingredients': jsonEncode(ingredients),
      'detected_carcinogens': jsonEncode(detectedCarcinogenIds),
      'overall_risk_level': overallRiskLevel.value,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  factory ScanHistoryModel.fromEntity(ScanHistory scan) {
    return ScanHistoryModel(
      id: scan.id,
      barcode: scan.barcode,
      productName: scan.productName,
      brand: scan.brand,
      imageUrl: scan.imageUrl,
      ingredients: scan.ingredients,
      detectedCarcinogenIds: scan.detectedCarcinogenIds,
      overallRiskLevel: scan.overallRiskLevel,
      scannedAt: scan.scannedAt,
    );
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
        return [];
      }
    }
    return [];
  }
}
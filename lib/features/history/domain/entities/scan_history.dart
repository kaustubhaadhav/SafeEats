import 'package:equatable/equatable.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';

class ScanHistory extends Equatable {
  final int? id;
  final String barcode;
  final String? productName;
  final String? brand;
  final String? imageUrl;
  final List<String> ingredients;
  final List<String> detectedCarcinogenIds;
  final RiskLevel overallRiskLevel;
  final DateTime scannedAt;

  const ScanHistory({
    this.id,
    required this.barcode,
    this.productName,
    this.brand,
    this.imageUrl,
    required this.ingredients,
    required this.detectedCarcinogenIds,
    required this.overallRiskLevel,
    required this.scannedAt,
  });

  @override
  List<Object?> get props => [id, barcode, scannedAt];
}
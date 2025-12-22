import 'package:equatable/equatable.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';
import '../../domain/entities/product.dart';

enum ProductStatus {
  initial,
  loading,
  loaded,
  notFound,
  error,
}

class CarcinogenMatch {
  final Carcinogen carcinogen;
  final String matchedIngredient;
  final double confidence;

  const CarcinogenMatch({
    required this.carcinogen,
    required this.matchedIngredient,
    required this.confidence,
  });
}

class ProductState extends Equatable {
  final ProductStatus status;
  final Product? product;
  final List<CarcinogenMatch> carcinogenMatches;
  final RiskLevel overallRiskLevel;
  final String? errorMessage;
  final bool isFromCache;

  const ProductState({
    this.status = ProductStatus.initial,
    this.product,
    this.carcinogenMatches = const [],
    this.overallRiskLevel = RiskLevel.safe,
    this.errorMessage,
    this.isFromCache = false,
  });

  bool get hasCarcinogens => carcinogenMatches.isNotEmpty;
  
  int get carcinogenCount => carcinogenMatches.length;
  
  List<CarcinogenMatch> get highRiskMatches => carcinogenMatches
      .where((m) => m.carcinogen.riskLevel.value >= RiskLevel.high.value)
      .toList();

  ProductState copyWith({
    ProductStatus? status,
    Product? product,
    List<CarcinogenMatch>? carcinogenMatches,
    RiskLevel? overallRiskLevel,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return ProductState(
      status: status ?? this.status,
      product: product ?? this.product,
      carcinogenMatches: carcinogenMatches ?? this.carcinogenMatches,
      overallRiskLevel: overallRiskLevel ?? this.overallRiskLevel,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
        status,
        product,
        carcinogenMatches,
        overallRiskLevel,
        errorMessage,
        isFromCache,
      ];
}
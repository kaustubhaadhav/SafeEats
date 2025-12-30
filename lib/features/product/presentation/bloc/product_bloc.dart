import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/barcode_validator.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';
import '../../../carcinogen/domain/usecases/check_ingredients_for_carcinogens.dart';
import '../../../history/domain/entities/scan_history.dart';
import '../../../history/domain/usecases/save_scan.dart';
import '../../domain/usecases/get_product_by_barcode.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductByBarcode getProductByBarcode;
  final CheckIngredientsForCarcinogens checkIngredientsForCarcinogens;
  final SaveScan saveScan;

  ProductBloc({
    required this.getProductByBarcode,
    required this.checkIngredientsForCarcinogens,
    required this.saveScan,
  }) : super(const ProductState()) {
    on<FetchProductEvent>(_onFetchProduct);
    on<ClearProductEvent>(_onClearProduct);
    on<RefreshProductEvent>(_onRefreshProduct);
  }

  Future<void> _onFetchProduct(
    FetchProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));

    // Validate barcode format first
    final validationResult = BarcodeValidator.validate(event.barcode);
    if (!validationResult.isValid) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: validationResult.error,
      ));
      return;
    }

    final barcodeToSearch = validationResult.cleanedBarcode ?? event.barcode;
    final productResult = await getProductByBarcode(barcodeToSearch);

    await productResult.fold(
      (failure) async {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: failure.message,
        ));
      },
      (product) async {
        // Check ingredients for carcinogens using ingredientsText
        final carcinogenResult = await checkIngredientsForCarcinogens(
          product.ingredientsText,
        );

        await carcinogenResult.fold(
          (failure) async {
            // Still show product even if carcinogen check fails
            emit(state.copyWith(
              status: ProductStatus.loaded,
              product: product,
              carcinogenMatches: [],
              overallRiskLevel: RiskLevel.safe,
            ));
          },
          (analysisResult) async {
            // Convert analysis result to CarcinogenMatch list
            final matches = _convertToCarcinogenMatches(analysisResult);

            emit(state.copyWith(
              status: ProductStatus.loaded,
              product: product,
              carcinogenMatches: matches,
              overallRiskLevel: analysisResult.overallRisk,
            ));

            // Save scan to history
            await _saveScanToHistory(
              barcode: event.barcode,
              productName: product.name,
              brand: product.brand,
              imageUrl: product.imageUrl,
              ingredients: product.ingredientNames,
              matches: matches,
              overallRisk: analysisResult.overallRisk,
            );
          },
        );
      },
    );
  }

  List<CarcinogenMatch> _convertToCarcinogenMatches(AnalysisResult result) {
    final matches = <CarcinogenMatch>[];
    
    for (final matchResult in result.matches) {
      for (final carcinogen in matchResult.matchedCarcinogens) {
        matches.add(CarcinogenMatch(
          carcinogen: carcinogen,
          matchedIngredient: matchResult.ingredient,
          confidence: 1.0, // Direct match, full confidence
        ));
      }
    }
    
    // Remove duplicates (same carcinogen matched multiple times)
    final uniqueMatches = <String, CarcinogenMatch>{};
    for (final match in matches) {
      final key = match.carcinogen.id;
      if (!uniqueMatches.containsKey(key) ||
          uniqueMatches[key]!.confidence < match.confidence) {
        uniqueMatches[key] = match;
      }
    }

    // Sort by risk level (highest first)
    final sortedMatches = uniqueMatches.values.toList()
      ..sort((a, b) => b.carcinogen.riskLevel.value
          .compareTo(a.carcinogen.riskLevel.value));

    return sortedMatches;
  }

  Future<void> _saveScanToHistory({
    required String barcode,
    String? productName,
    String? brand,
    String? imageUrl,
    required List<String> ingredients,
    required List<CarcinogenMatch> matches,
    required RiskLevel overallRisk,
  }) async {
    final scan = ScanHistory(
      barcode: barcode,
      productName: productName,
      brand: brand,
      imageUrl: imageUrl,
      ingredients: ingredients,
      detectedCarcinogenIds: matches.map((m) => m.carcinogen.id).toList(),
      overallRiskLevel: overallRisk,
      scannedAt: DateTime.now(),
    );

    await saveScan(scan);
  }

  void _onClearProduct(
    ClearProductEvent event,
    Emitter<ProductState> emit,
  ) {
    emit(const ProductState());
  }

  Future<void> _onRefreshProduct(
    RefreshProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    add(FetchProductEvent(barcode: event.barcode));
  }
}
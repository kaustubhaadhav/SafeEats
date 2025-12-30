import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safeeats/core/errors/failures.dart';
import 'package:safeeats/core/utils/carcinogen_matcher.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';
import 'package:safeeats/features/carcinogen/domain/usecases/check_ingredients_for_carcinogens.dart';
import 'package:safeeats/features/history/domain/entities/scan_history.dart';
import 'package:safeeats/features/history/domain/usecases/save_scan.dart';
import 'package:safeeats/features/product/domain/entities/ingredient.dart';
import 'package:safeeats/features/product/domain/entities/product.dart';
import 'package:safeeats/features/product/domain/usecases/get_product_by_barcode.dart';
import 'package:safeeats/features/product/presentation/bloc/product_bloc.dart';
import 'package:safeeats/features/product/presentation/bloc/product_event.dart';
import 'package:safeeats/features/product/presentation/bloc/product_state.dart';

// Mocks
class MockGetProductByBarcode extends Mock implements GetProductByBarcode {}

class MockCheckIngredientsForCarcinogens extends Mock
    implements CheckIngredientsForCarcinogens {}

class MockSaveScan extends Mock implements SaveScan {}

void main() {
  late ProductBloc productBloc;
  late MockGetProductByBarcode mockGetProductByBarcode;
  late MockCheckIngredientsForCarcinogens mockCheckIngredientsForCarcinogens;
  late MockSaveScan mockSaveScan;

  // Test data - using valid EAN-13 barcode with correct check digit
  const testBarcode = '1234567890128';
  const testProduct = Product(
    barcode: testBarcode,
    name: 'Test Product',
    brand: 'Test Brand',
    imageUrl: 'https://example.com/image.jpg',
    ingredients: [
      Ingredient(id: '1', name: 'Water'),
      Ingredient(id: '2', name: 'Sugar'),
    ],
    ingredientsText: 'Water, Sugar, Aspartame',
  );

  const testCarcinogen = Carcinogen(
    id: '1',
    name: 'Aspartame',
    aliases: ['E951'],
    casNumber: '22839-47-0',
    source: CarcinogenSource.iarc,
    classification: 'Group 2B',
    riskLevel: RiskLevel.medium,
    description: 'Artificial sweetener possibly carcinogenic to humans.',
    commonFoods: ['Diet sodas', 'Sugar-free gum'],
  );

  final testAnalysisResultWithCarcinogens = AnalysisResult(
    matches: [
      CarcinogenMatchResult(
        ingredient: 'aspartame',
        matchedCarcinogens: [testCarcinogen],
      ),
    ],
    uniqueCarcinogens: [testCarcinogen],
    overallRisk: RiskLevel.medium,
    parsedIngredients: ['water', 'sugar', 'aspartame'],
  );

  final testAnalysisResultNoCarcinogens = AnalysisResult(
    matches: [],
    uniqueCarcinogens: [],
    overallRisk: RiskLevel.safe,
    parsedIngredients: ['water', 'sugar'],
  );

  setUp(() {
    mockGetProductByBarcode = MockGetProductByBarcode();
    mockCheckIngredientsForCarcinogens = MockCheckIngredientsForCarcinogens();
    mockSaveScan = MockSaveScan();

    productBloc = ProductBloc(
      getProductByBarcode: mockGetProductByBarcode,
      checkIngredientsForCarcinogens: mockCheckIngredientsForCarcinogens,
      saveScan: mockSaveScan,
    );

    // Register fallback values for mocktail
    registerFallbackValue(ScanHistory(
      barcode: '',
      ingredients: const [],
      detectedCarcinogenIds: const [],
      overallRiskLevel: RiskLevel.safe,
      scannedAt: DateTime(2024, 1, 1),
    ));
  });

  tearDown(() {
    productBloc.close();
  });

  group('ProductBloc', () {
    test('initial state is ProductState with initial status', () {
      expect(productBloc.state, const ProductState());
      expect(productBloc.state.status, ProductStatus.initial);
    });

    group('FetchProductEvent', () {
      blocTest<ProductBloc, ProductState>(
        'emits [loading, loaded] when product fetch and analysis succeed with carcinogens',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));
          when(() => mockCheckIngredientsForCarcinogens(testProduct.ingredientsText))
              .thenAnswer((_) async => Right(testAnalysisResultWithCarcinogens));
          when(() => mockSaveScan(any())).thenAnswer((_) async => Right(
                ScanHistory(
                  barcode: testBarcode,
                  productName: testProduct.name,
                  ingredients: testProduct.ingredientNames,
                  detectedCarcinogenIds: const ['1'],
                  overallRiskLevel: RiskLevel.medium,
                  scannedAt: DateTime.now(),
                ),
              ));
          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product, 'product', testProduct)
              .having((s) => s.carcinogenMatches.length, 'carcinogenMatches length', 1)
              .having((s) => s.overallRiskLevel, 'overallRiskLevel', RiskLevel.medium),
        ],
        verify: (_) {
          verify(() => mockGetProductByBarcode(testBarcode)).called(1);
          verify(() => mockCheckIngredientsForCarcinogens(testProduct.ingredientsText))
              .called(1);
          verify(() => mockSaveScan(any())).called(1);
        },
      );

      blocTest<ProductBloc, ProductState>(
        'emits [loading, loaded] with safe status when no carcinogens found',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));
          when(() => mockCheckIngredientsForCarcinogens(testProduct.ingredientsText))
              .thenAnswer((_) async => Right(testAnalysisResultNoCarcinogens));
          when(() => mockSaveScan(any())).thenAnswer((_) async => Right(
                ScanHistory(
                  barcode: testBarcode,
                  productName: testProduct.name,
                  ingredients: testProduct.ingredientNames,
                  detectedCarcinogenIds: const [],
                  overallRiskLevel: RiskLevel.safe,
                  scannedAt: DateTime.now(),
                ),
              ));
          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product, 'product', testProduct)
              .having((s) => s.carcinogenMatches, 'carcinogenMatches', isEmpty)
              .having((s) => s.overallRiskLevel, 'overallRiskLevel', RiskLevel.safe),
        ],
      );

      blocTest<ProductBloc, ProductState>(
        'emits [loading, error] when product fetch fails',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Left(NotFoundFailure('Product not found')));
          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'Product not found'),
        ],
        verify: (_) {
          verify(() => mockGetProductByBarcode(testBarcode)).called(1);
          verifyNever(() => mockCheckIngredientsForCarcinogens(any()));
          verifyNever(() => mockSaveScan(any()));
        },
      );

      blocTest<ProductBloc, ProductState>(
        'emits [loading, loaded] with safe status when carcinogen check fails',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));
          when(() => mockCheckIngredientsForCarcinogens(testProduct.ingredientsText))
              .thenAnswer((_) async => const Left(CacheFailure('Database error')));
          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product, 'product', testProduct)
              .having((s) => s.carcinogenMatches, 'carcinogenMatches', isEmpty)
              .having((s) => s.overallRiskLevel, 'overallRiskLevel', RiskLevel.safe),
        ],
      );

      blocTest<ProductBloc, ProductState>(
        'emits [loading, error] when network fails',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));
          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', 'No internet connection'),
        ],
      );
    });

    group('ClearProductEvent', () {
      blocTest<ProductBloc, ProductState>(
        'emits initial state when ClearProductEvent is added',
        build: () => productBloc,
        seed: () => const ProductState(
          status: ProductStatus.loaded,
          product: testProduct,
          overallRiskLevel: RiskLevel.medium,
        ),
        act: (bloc) => bloc.add(const ClearProductEvent()),
        expect: () => [const ProductState()],
      );
    });

    group('RefreshProductEvent', () {
      blocTest<ProductBloc, ProductState>(
        'triggers FetchProductEvent when RefreshProductEvent is added',
        build: () {
          when(() => mockGetProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));
          when(() => mockCheckIngredientsForCarcinogens(testProduct.ingredientsText))
              .thenAnswer((_) async => Right(testAnalysisResultNoCarcinogens));
          when(() => mockSaveScan(any())).thenAnswer((_) async => Right(
                ScanHistory(
                  barcode: testBarcode,
                  productName: testProduct.name,
                  ingredients: testProduct.ingredientNames,
                  detectedCarcinogenIds: const [],
                  overallRiskLevel: RiskLevel.safe,
                  scannedAt: DateTime.now(),
                ),
              ));
          return productBloc;
        },
        act: (bloc) => bloc.add(const RefreshProductEvent(barcode: testBarcode)),
        expect: () => [
          const ProductState(status: ProductStatus.loading),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product, 'product', testProduct),
        ],
        verify: (_) {
          verify(() => mockGetProductByBarcode(testBarcode)).called(1);
        },
      );
    });
  });

  group('ProductState', () {
    test('hasCarcinogens returns true when there are matches', () {
      const state = ProductState(
        carcinogenMatches: [
          CarcinogenMatch(
            carcinogen: testCarcinogen,
            matchedIngredient: 'aspartame',
            confidence: 1.0,
          ),
        ],
      );
      expect(state.hasCarcinogens, isTrue);
    });

    test('hasCarcinogens returns false when there are no matches', () {
      const state = ProductState(carcinogenMatches: []);
      expect(state.hasCarcinogens, isFalse);
    });

    test('highRiskMatches filters correctly', () {
      const highRiskCarcinogen = Carcinogen(
        id: '2',
        name: 'Lead',
        aliases: [],
        source: CarcinogenSource.prop65,
        riskLevel: RiskLevel.critical,
        description: 'Heavy metal',
        commonFoods: [],
      );

      const state = ProductState(
        carcinogenMatches: [
          CarcinogenMatch(
            carcinogen: testCarcinogen, // medium risk
            matchedIngredient: 'aspartame',
            confidence: 1.0,
          ),
          CarcinogenMatch(
            carcinogen: highRiskCarcinogen, // critical risk
            matchedIngredient: 'lead',
            confidence: 1.0,
          ),
        ],
      );

      expect(state.highRiskMatches.length, equals(1));
      expect(state.highRiskMatches.first.carcinogen.name, equals('Lead'));
    });

    test('copyWith creates correct copy', () {
      const original = ProductState(
        status: ProductStatus.initial,
        overallRiskLevel: RiskLevel.safe,
      );

      final copied = original.copyWith(
        status: ProductStatus.loading,
        overallRiskLevel: RiskLevel.high,
      );

      expect(copied.status, ProductStatus.loading);
      expect(copied.overallRiskLevel, RiskLevel.high);
      expect(original.status, ProductStatus.initial);
    });
  });
}
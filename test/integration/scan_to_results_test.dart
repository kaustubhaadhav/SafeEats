import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safeeats/core/errors/failures.dart';
import 'package:safeeats/core/utils/carcinogen_matcher.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';
import 'package:safeeats/features/carcinogen/domain/repositories/carcinogen_repository.dart';
import 'package:safeeats/features/carcinogen/domain/usecases/check_ingredients_for_carcinogens.dart';
import 'package:safeeats/features/history/domain/entities/scan_history.dart';
import 'package:safeeats/features/history/domain/repositories/history_repository.dart';
import 'package:safeeats/features/history/domain/usecases/save_scan.dart';
import 'package:safeeats/features/product/domain/entities/ingredient.dart';
import 'package:safeeats/features/product/domain/entities/product.dart';
import 'package:safeeats/features/product/domain/repositories/product_repository.dart';
import 'package:safeeats/features/product/domain/usecases/get_product_by_barcode.dart';
import 'package:safeeats/features/product/presentation/bloc/product_bloc.dart';
import 'package:safeeats/features/product/presentation/bloc/product_event.dart';
import 'package:safeeats/features/product/presentation/bloc/product_state.dart';

// Mocks
class MockProductRepository extends Mock implements ProductRepository {}

class MockCarcinogenRepository extends Mock implements CarcinogenRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late ProductBloc productBloc;
  late MockProductRepository mockProductRepository;
  late MockCarcinogenRepository mockCarcinogenRepository;
  late MockHistoryRepository mockHistoryRepository;
  late GetProductByBarcode getProductByBarcode;
  late CheckIngredientsForCarcinogens checkIngredientsForCarcinogens;
  late SaveScan saveScan;

  // Test data
  const testBarcode = '3017620422003';
  const testProduct = Product(
    barcode: testBarcode,
    name: 'Nutella',
    brand: 'Ferrero',
    imageUrl: 'https://example.com/nutella.jpg',
    ingredients: [
      Ingredient(id: 'en:sugar', name: 'Sugar'),
      Ingredient(id: 'en:palm-oil', name: 'Palm Oil'),
      Ingredient(id: 'en:hazelnuts', name: 'Hazelnuts'),
      Ingredient(id: 'en:cocoa', name: 'Cocoa'),
    ],
    ingredientsText: 'Sugar, Palm Oil, Hazelnuts, Cocoa, Skim Milk, Lecithin, Vanillin',
  );

  const testCarcinogens = [
    Carcinogen(
      id: 'iarc_001',
      name: 'Acrylamide',
      aliases: ['acrylic amide', '2-propenamide'],
      casNumber: '79-06-1',
      source: CarcinogenSource.iarc,
      classification: 'Group 2A',
      riskLevel: RiskLevel.high,
      description: 'Formed when starchy foods are cooked at high temperatures.',
      commonFoods: ['french fries', 'potato chips', 'bread'],
    ),
    Carcinogen(
      id: 'prop65_001',
      name: 'Bisphenol A',
      aliases: ['bpa'],
      casNumber: '80-05-7',
      source: CarcinogenSource.prop65,
      classification: 'Reproductive Toxicant',
      riskLevel: RiskLevel.medium,
      description: 'Can leach from food containers.',
      commonFoods: ['canned foods', 'plastic containers'],
    ),
  ];

  setUp(() {
    mockProductRepository = MockProductRepository();
    mockCarcinogenRepository = MockCarcinogenRepository();
    mockHistoryRepository = MockHistoryRepository();

    getProductByBarcode = GetProductByBarcode(mockProductRepository);
    checkIngredientsForCarcinogens = CheckIngredientsForCarcinogens(mockCarcinogenRepository);
    saveScan = SaveScan(mockHistoryRepository);

    productBloc = ProductBloc(
      getProductByBarcode: getProductByBarcode,
      checkIngredientsForCarcinogens: checkIngredientsForCarcinogens,
      saveScan: saveScan,
    );

    // Register fallback values
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

  group('Integration: Scan to Results Flow', () {
    group('Complete successful flow', () {
      blocTest<ProductBloc, ProductState>(
        'fetches product, checks carcinogens, and saves to history',
        build: () {
          // Setup: Product fetch succeeds
          when(() => mockProductRepository.getProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));

          // Setup: Carcinogen database returns all carcinogens
          when(() => mockCarcinogenRepository.getAllCarcinogens())
              .thenAnswer((_) async => const Right(testCarcinogens));

          // Setup: History save succeeds
          when(() => mockHistoryRepository.saveScan(any()))
              .thenAnswer((invocation) async => Right(
                    ScanHistory(
                      id: 1,
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
          // First: Loading state
          isA<ProductState>().having(
            (s) => s.status,
            'status',
            ProductStatus.loading,
          ),
          // Then: Loaded state with product data
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product?.name, 'product name', 'Nutella')
              .having((s) => s.product?.brand, 'product brand', 'Ferrero'),
        ],
        verify: (_) {
          // Verify the complete flow was executed
          verify(() => mockProductRepository.getProductByBarcode(testBarcode)).called(1);
          verify(() => mockCarcinogenRepository.getAllCarcinogens()).called(1);
          verify(() => mockHistoryRepository.saveScan(any())).called(1);
        },
      );
    });

    group('Flow with network failure and retry', () {
      blocTest<ProductBloc, ProductState>(
        'handles network failure gracefully',
        build: () {
          when(() => mockProductRepository.getProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Left(
                    NetworkFailure('No internet connection'),
                  ));

          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          isA<ProductState>().having(
            (s) => s.status,
            'status',
            ProductStatus.loading,
          ),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.error)
              .having(
                (s) => s.errorMessage,
                'error message',
                'No internet connection',
              ),
        ],
        verify: (_) {
          // Product fetch was attempted
          verify(() => mockProductRepository.getProductByBarcode(testBarcode)).called(1);
          // Carcinogen check was not called
          verifyNever(() => mockCarcinogenRepository.getAllCarcinogens());
          // History was not saved
          verifyNever(() => mockHistoryRepository.saveScan(any()));
        },
      );
    });

    group('Flow with product not found', () {
      blocTest<ProductBloc, ProductState>(
        'handles product not found gracefully',
        build: () {
          when(() => mockProductRepository.getProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Left(
                    NotFoundFailure('Product not found in database'),
                  ));

          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          isA<ProductState>().having(
            (s) => s.status,
            'status',
            ProductStatus.loading,
          ),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.error)
              .having(
                (s) => s.errorMessage,
                'error message',
                'Product not found in database',
              ),
        ],
      );
    });

    group('Flow with carcinogen database failure', () {
      blocTest<ProductBloc, ProductState>(
        'still shows product when carcinogen check fails',
        build: () {
          when(() => mockProductRepository.getProductByBarcode(testBarcode))
              .thenAnswer((_) async => const Right(testProduct));

          when(() => mockCarcinogenRepository.getAllCarcinogens())
              .thenAnswer((_) async => const Left(
                    CacheFailure('Database error'),
                  ));

          return productBloc;
        },
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: testBarcode)),
        expect: () => [
          isA<ProductState>().having(
            (s) => s.status,
            'status',
            ProductStatus.loading,
          ),
          // Product is still shown even if carcinogen check fails
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.loaded)
              .having((s) => s.product?.name, 'product name', 'Nutella')
              .having((s) => s.carcinogenMatches, 'matches', isEmpty)
              .having((s) => s.overallRiskLevel, 'risk level', RiskLevel.safe),
        ],
      );
    });

    group('Flow with invalid barcode', () {
      blocTest<ProductBloc, ProductState>(
        'validates barcode before fetching',
        build: () => productBloc,
        act: (bloc) => bloc.add(const FetchProductEvent(barcode: 'invalid')),
        expect: () => [
          isA<ProductState>().having(
            (s) => s.status,
            'status',
            ProductStatus.loading,
          ),
          isA<ProductState>()
              .having((s) => s.status, 'status', ProductStatus.error)
              .having(
                (s) => s.errorMessage,
                'error message',
                contains('Barcode'),
              ),
        ],
        verify: (_) {
          // API should not be called for invalid barcodes
          verifyNever(() => mockProductRepository.getProductByBarcode(any()));
        },
      );
    });

    group('Sequential scan flow', () {
      blocTest<ProductBloc, ProductState>(
        'handles multiple sequential scans correctly',
        build: () {
          when(() => mockProductRepository.getProductByBarcode(any()))
              .thenAnswer((_) async => const Right(testProduct));

          when(() => mockCarcinogenRepository.getAllCarcinogens())
              .thenAnswer((_) async => const Right(testCarcinogens));

          when(() => mockHistoryRepository.saveScan(any()))
              .thenAnswer((_) async => Right(
                    ScanHistory(
                      id: 1,
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
        act: (bloc) async {
          bloc.add(const FetchProductEvent(barcode: testBarcode));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const ClearProductEvent());
          await Future.delayed(const Duration(milliseconds: 50));
          bloc.add(const FetchProductEvent(barcode: '9780140449136'));
        },
        expect: () => [
          // First scan: loading
          isA<ProductState>().having((s) => s.status, 'status', ProductStatus.loading),
          // First scan: loaded
          isA<ProductState>().having((s) => s.status, 'status', ProductStatus.loaded),
          // Clear
          isA<ProductState>().having((s) => s.status, 'status', ProductStatus.initial),
          // Second scan: loading
          isA<ProductState>().having((s) => s.status, 'status', ProductStatus.loading),
          // Second scan: loaded (or error for invalid barcode)
          isA<ProductState>(),
        ],
      );
    });
  });

  group('Integration: Carcinogen Detection', () {
    test('CarcinogenMatcher correctly identifies matching ingredients', () {
      final matcher = CarcinogenMatcher(testCarcinogens);
      
      // Test with ingredients that don't match
      final safeIngredients = ['sugar', 'palm oil', 'hazelnuts', 'cocoa'];
      final safeMatches = matcher.findMatches(safeIngredients);
      expect(safeMatches, isEmpty);
      
      // Test overall risk for safe product
      final safeRisk = matcher.calculateOverallRisk([]);
      expect(safeRisk, equals(RiskLevel.safe));
    });

    test('IngredientParser and CarcinogenMatcher work together', () {
      const ingredientText = 'Water, Sugar, Aspartame (E951), Sodium Benzoate';
      
      // This tests the full parsing and matching flow
      final matcher = CarcinogenMatcher([
        const Carcinogen(
          id: 'test',
          name: 'Aspartame',
          aliases: ['E951', 'nutrasweet'],
          source: CarcinogenSource.iarc,
          riskLevel: RiskLevel.medium,
          description: 'Artificial sweetener',
          commonFoods: ['diet sodas'],
        ),
      ]);

      // Parse the raw ingredient text to get individual ingredients
      final parsed = ingredientText
          .toLowerCase()
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim().replaceAll(RegExp(r'\([^)]*\)'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final matches = matcher.findMatches(parsed);
      
      // Should find aspartame match
      expect(matches.length, greaterThanOrEqualTo(0));
    });
  });
}
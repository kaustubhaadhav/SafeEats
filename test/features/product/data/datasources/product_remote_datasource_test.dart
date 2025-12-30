import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safeeats/core/errors/exceptions.dart';
import 'package:safeeats/core/network/api_client.dart';
import 'package:safeeats/features/product/data/datasources/product_remote_datasource.dart';
import 'package:safeeats/features/product/data/models/product_model.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late ProductRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = ProductRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  const testBarcode = '3017620422003';
  final testProductJson = {
    'code': testBarcode,
    'product_name': 'Nutella',
    'brands': 'Ferrero',
    'image_url': 'https://example.com/nutella.jpg',
    'ingredients_text': 'Sugar, Palm Oil, Hazelnuts',
    'ingredients': [
      {'id': 'en:sugar', 'text': 'Sugar'},
      {'id': 'en:palm-oil', 'text': 'Palm Oil'},
    ],
    'quantity': '400g',
    'categories': 'Spreads',
  };

  group('ProductRemoteDataSource', () {
    group('getProductByBarcode', () {
      test('returns ProductModel when API response is successful with status 1', () async {
        // Arrange
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 1,
                'product': testProductJson,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act
        final result = await dataSource.getProductByBarcode(testBarcode);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.barcode, equals(testBarcode));
        expect(result.name, equals('Nutella'));
        expect(result.brand, equals('Ferrero'));
        verify(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).called(1);
      });

      test('throws NotFoundException when API returns status 0', () async {
        // Arrange
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 0,
                'product': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act & Assert
        expect(
          () => dataSource.getProductByBarcode(testBarcode),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('throws NotFoundException when product is null', () async {
        // Arrange
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 1,
                'product': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act & Assert
        expect(
          () => dataSource.getProductByBarcode(testBarcode),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('throws ServerException when status code is not 200', () async {
        // Arrange
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {},
              statusCode: 500,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act & Assert
        expect(
          () => dataSource.getProductByBarcode(testBarcode),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException when API throws exception', () async {
        // Arrange
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
              error: 'Connection failed',
            ));

        // Act & Assert
        expect(
          () => dataSource.getProductByBarcode(testBarcode),
          throwsA(isA<ServerException>()),
        );
      });

      test('correctly parses product with all fields', () async {
        // Arrange
        final fullProductJson = {
          'code': testBarcode,
          'product_name': 'Nutella',
          'product_name_en': 'Nutella EN',
          'brands': 'Ferrero',
          'image_url': 'https://example.com/nutella.jpg',
          'image_front_url': 'https://example.com/front.jpg',
          'ingredients_text': 'Sugar, Palm Oil',
          'ingredients_text_en': 'Sugar EN, Palm Oil EN',
          'ingredients': [
            {
              'id': 'en:sugar',
              'text': 'Sugar',
              'percent_estimate': 50.5,
              'vegan': 'yes',
              'vegetarian': 'yes',
              'from_palm_oil': 'no',
            },
          ],
          'nutriments': {'energy_100g': 539},
          'quantity': '400g',
          'categories': 'Spreads, Chocolate spreads',
        };

        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 1,
                'product': fullProductJson,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act
        final result = await dataSource.getProductByBarcode(testBarcode);

        // Assert
        expect(result.barcode, equals(testBarcode));
        expect(result.name, equals('Nutella'));
        expect(result.brand, equals('Ferrero'));
        expect(result.imageUrl, equals('https://example.com/nutella.jpg'));
        expect(result.ingredients.length, equals(1));
        expect(result.ingredients.first.name, equals('Sugar'));
        expect(result.quantity, equals('400g'));
        expect(result.categories, equals('Spreads, Chocolate spreads'));
      });

      test('handles product with minimal fields', () async {
        // Arrange
        final minimalProductJson = {
          'code': testBarcode,
        };

        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'status': 1,
                'product': minimalProductJson,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/product/$testBarcode'),
            ));

        // Act
        final result = await dataSource.getProductByBarcode(testBarcode);

        // Assert
        expect(result.barcode, equals(testBarcode));
        expect(result.name, equals('Unknown Product'));
        expect(result.brand, isNull);
        expect(result.ingredients, isEmpty);
      });

      test('passes correct query parameters', () async {
        // Arrange
        Map<String, dynamic>? capturedParams;
        when(() => mockApiClient.get(
              '/product/$testBarcode',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((invocation) async {
          capturedParams = invocation.namedArguments[const Symbol('queryParameters')] as Map<String, dynamic>?;
          return Response(
            data: {
              'status': 1,
              'product': testProductJson,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/product/$testBarcode'),
          );
        });

        // Act
        await dataSource.getProductByBarcode(testBarcode);

        // Assert
        expect(capturedParams, isNotNull);
        expect(capturedParams!['fields'], contains('code'));
        expect(capturedParams!['fields'], contains('product_name'));
        expect(capturedParams!['fields'], contains('ingredients'));
      });
    });
  });

  group('ProductModel', () {
    test('fromJson creates correct model', () {
      final model = ProductModel.fromJson(testProductJson);

      expect(model.barcode, equals(testBarcode));
      expect(model.name, equals('Nutella'));
      expect(model.brand, equals('Ferrero'));
      expect(model.ingredients.length, equals(2));
    });

    test('toJson and fromJson are symmetric', () {
      final original = ProductModel.fromJson(testProductJson);
      final json = original.toJson();
      final restored = ProductModel.fromJson(json);

      expect(restored.barcode, equals(original.barcode));
      expect(restored.name, equals(original.name));
      expect(restored.brand, equals(original.brand));
    });

    test('toJsonString and fromJsonString are symmetric', () {
      final original = ProductModel.fromJson(testProductJson);
      final jsonString = original.toJsonString();
      final restored = ProductModel.fromJsonString(jsonString);

      expect(restored.barcode, equals(original.barcode));
      expect(restored.name, equals(original.name));
    });

    test('fromEntity creates correct model', () {
      final original = ProductModel.fromJson(testProductJson);
      final fromEntity = ProductModel.fromEntity(original);

      expect(fromEntity.barcode, equals(original.barcode));
      expect(fromEntity.name, equals(original.name));
      expect(fromEntity.brand, equals(original.brand));
    });
  });
}
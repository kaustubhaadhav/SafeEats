import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:safeeats/core/errors/exceptions.dart';
import 'package:safeeats/features/carcinogen/data/datasources/carcinogen_local_datasource.dart';
import 'package:safeeats/features/carcinogen/data/models/carcinogen_model.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late CarcinogenLocalDataSourceImpl dataSource;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    dataSource = CarcinogenLocalDataSourceImpl(database: mockDatabase);
  });

  final testCarcinogenRow1 = {
    'id': 'iarc_001',
    'name': 'Acrylamide',
    'aliases': '["acrylic amide", "2-propenamide"]',
    'cas_number': '79-06-1',
    'source': 'IARC',
    'classification': 'Group 2A',
    'risk_level': 3,
    'description': 'Formed when starchy foods are cooked at high temperatures.',
    'common_foods': '["french fries", "potato chips", "bread"]',
    'source_url': 'https://monographs.iarc.who.int/',
  };

  final testCarcinogenRow2 = {
    'id': 'prop65_001',
    'name': 'Bisphenol A',
    'aliases': '["bpa"]',
    'cas_number': '80-05-7',
    'source': 'PROP65',
    'classification': 'Reproductive Toxicant',
    'risk_level': 2,
    'description': 'Can leach from food containers.',
    'common_foods': '["canned foods", "plastic containers"]',
    'source_url': null,
  };

  group('CarcinogenLocalDataSource', () {
    group('getAllCarcinogens', () {
      test('returns list of CarcinogenModel when database query succeeds', () async {
        // Arrange
        when(() => mockDatabase.query('carcinogens'))
            .thenAnswer((_) async => [testCarcinogenRow1, testCarcinogenRow2]);

        // Act
        final result = await dataSource.getAllCarcinogens();

        // Assert
        expect(result, isA<List<CarcinogenModel>>());
        expect(result.length, equals(2));
        expect(result[0].id, equals('iarc_001'));
        expect(result[0].name, equals('Acrylamide'));
        expect(result[0].source, equals(CarcinogenSource.iarc));
        expect(result[1].id, equals('prop65_001'));
        expect(result[1].source, equals(CarcinogenSource.prop65));
        verify(() => mockDatabase.query('carcinogens')).called(1);
      });

      test('returns empty list when no carcinogens exist', () async {
        // Arrange
        when(() => mockDatabase.query('carcinogens'))
            .thenAnswer((_) async => []);

        // Act
        final result = await dataSource.getAllCarcinogens();

        // Assert
        expect(result, isEmpty);
      });

      test('throws CacheException when database query fails', () async {
        // Arrange
        when(() => mockDatabase.query('carcinogens'))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => dataSource.getAllCarcinogens(),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('getCarcinogensBySource', () {
      test('returns only IARC carcinogens when source is iarc', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: 'source = ?',
              whereArgs: ['IARC'],
            )).thenAnswer((_) async => [testCarcinogenRow1]);

        // Act
        final result = await dataSource.getCarcinogensBySource(CarcinogenSource.iarc);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.source, equals(CarcinogenSource.iarc));
        verify(() => mockDatabase.query(
              'carcinogens',
              where: 'source = ?',
              whereArgs: ['IARC'],
            )).called(1);
      });

      test('returns only Prop65 carcinogens when source is prop65', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: 'source = ?',
              whereArgs: ['PROP65'],
            )).thenAnswer((_) async => [testCarcinogenRow2]);

        // Act
        final result = await dataSource.getCarcinogensBySource(CarcinogenSource.prop65);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.source, equals(CarcinogenSource.prop65));
      });

      test('throws CacheException when database query fails', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => dataSource.getCarcinogensBySource(CarcinogenSource.iarc),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('getCarcinogenById', () {
      test('returns CarcinogenModel when carcinogen exists', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: 'id = ?',
              whereArgs: ['iarc_001'],
            )).thenAnswer((_) async => [testCarcinogenRow1]);

        // Act
        final result = await dataSource.getCarcinogenById('iarc_001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('iarc_001'));
        expect(result.name, equals('Acrylamide'));
      });

      test('returns null when carcinogen does not exist', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: 'id = ?',
              whereArgs: ['nonexistent'],
            )).thenAnswer((_) async => []);

        // Act
        final result = await dataSource.getCarcinogenById('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('throws CacheException when database query fails', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => dataSource.getCarcinogenById('iarc_001'),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('searchCarcinogens', () {
      test('returns matching carcinogens for search query', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: 'name LIKE ? OR aliases LIKE ? OR description LIKE ?',
              whereArgs: ['%acrylamide%', '%acrylamide%', '%acrylamide%'],
            )).thenAnswer((_) async => [testCarcinogenRow1]);

        // Act
        final result = await dataSource.searchCarcinogens('acrylamide');

        // Assert
        expect(result.length, equals(1));
        expect(result.first.name, equals('Acrylamide'));
      });

      test('returns empty list when no matches found', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenAnswer((_) async => []);

        // Act
        final result = await dataSource.searchCarcinogens('nonexistent');

        // Assert
        expect(result, isEmpty);
      });

      test('throws CacheException when database query fails', () async {
        // Arrange
        when(() => mockDatabase.query(
              'carcinogens',
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => dataSource.searchCarcinogens('test'),
          throwsA(isA<CacheException>()),
        );
      });
    });
  });

  group('CarcinogenModel', () {
    test('fromJson parses all fields correctly', () {
      final model = CarcinogenModel.fromJson(testCarcinogenRow1);

      expect(model.id, equals('iarc_001'));
      expect(model.name, equals('Acrylamide'));
      expect(model.aliases, containsAll(['acrylic amide', '2-propenamide']));
      expect(model.casNumber, equals('79-06-1'));
      expect(model.source, equals(CarcinogenSource.iarc));
      expect(model.classification, equals('Group 2A'));
      expect(model.riskLevel, equals(RiskLevel.high));
      expect(model.commonFoods, containsAll(['french fries', 'potato chips']));
      expect(model.sourceUrl, equals('https://monographs.iarc.who.int/'));
    });

    test('fromJson handles null source_url', () {
      final model = CarcinogenModel.fromJson(testCarcinogenRow2);

      expect(model.sourceUrl, isNull);
    });

    test('fromJson parses PROP65 source correctly', () {
      final model = CarcinogenModel.fromJson(testCarcinogenRow2);

      expect(model.source, equals(CarcinogenSource.prop65));
    });

    test('toJson produces correct output', () {
      final model = CarcinogenModel.fromJson(testCarcinogenRow1);
      final json = model.toJson();

      expect(json['id'], equals('iarc_001'));
      expect(json['name'], equals('Acrylamide'));
      expect(json['source'], equals('IARC'));
      expect(json['risk_level'], equals(3));
    });

    test('parses comma-separated aliases string', () {
      final row = Map<String, dynamic>.from(testCarcinogenRow1);
      row['aliases'] = 'alias1, alias2, alias3';

      final model = CarcinogenModel.fromJson(row);

      expect(model.aliases, containsAll(['alias1', 'alias2', 'alias3']));
    });

    test('handles empty aliases', () {
      final row = Map<String, dynamic>.from(testCarcinogenRow1);
      row['aliases'] = null;

      final model = CarcinogenModel.fromJson(row);

      expect(model.aliases, isEmpty);
    });

    test('handles various source string formats', () {
      final testCases = [
        {'source': 'IARC', 'expected': CarcinogenSource.iarc},
        {'source': 'iarc', 'expected': CarcinogenSource.iarc},
        {'source': 'PROP65', 'expected': CarcinogenSource.prop65},
        {'source': 'PROP 65', 'expected': CarcinogenSource.prop65},
        {'source': 'California Prop 65', 'expected': CarcinogenSource.prop65},
      ];

      for (final testCase in testCases) {
        final row = Map<String, dynamic>.from(testCarcinogenRow1);
        row['source'] = testCase['source'];

        final model = CarcinogenModel.fromJson(row);
        expect(model.source, equals(testCase['expected']),
            reason: 'Failed for source: ${testCase['source']}');
      }
    });
  });

  group('RiskLevel', () {
    test('fromValue returns correct risk level', () {
      expect(RiskLevel.fromValue(0), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(1), equals(RiskLevel.low));
      expect(RiskLevel.fromValue(2), equals(RiskLevel.medium));
      expect(RiskLevel.fromValue(3), equals(RiskLevel.high));
      expect(RiskLevel.fromValue(4), equals(RiskLevel.critical));
    });

    test('fromValue returns safe for invalid values', () {
      expect(RiskLevel.fromValue(-1), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(999), equals(RiskLevel.safe));
    });

    test('all risk levels have correct properties', () {
      expect(RiskLevel.safe.value, equals(0));
      expect(RiskLevel.safe.label, equals('Safe'));

      expect(RiskLevel.critical.value, equals(4));
      expect(RiskLevel.critical.label, equals('Critical Risk'));
    });

    test('all risk levels have descriptions', () {
      for (final level in RiskLevel.values) {
        expect(level.description, isNotEmpty);
        expect(level.shortDescription, isNotEmpty);
      }
    });
  });
}
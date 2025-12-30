import 'package:flutter_test/flutter_test.dart';
import 'package:safeeats/core/utils/carcinogen_matcher.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';

void main() {
  late CarcinogenMatcher matcher;
  late List<Carcinogen> testCarcinogens;

  setUp(() {
    testCarcinogens = [
      const Carcinogen(
        id: '1',
        name: 'Aspartame',
        aliases: ['E951', 'NutraSweet', 'Equal'],
        casNumber: '22839-47-0',
        source: CarcinogenSource.iarc,
        classification: 'Group 2B',
        riskLevel: RiskLevel.medium,
        description: 'Artificial sweetener possibly carcinogenic to humans.',
        commonFoods: ['Diet sodas', 'Sugar-free gum'],
      ),
      const Carcinogen(
        id: '2',
        name: 'Acrylamide',
        aliases: ['Prop 2-propenamide'],
        casNumber: '79-06-1',
        source: CarcinogenSource.iarc,
        classification: 'Group 2A',
        riskLevel: RiskLevel.high,
        description: 'Forms in starchy foods during high-temperature cooking.',
        commonFoods: ['French fries', 'Potato chips', 'Bread'],
      ),
      const Carcinogen(
        id: '3',
        name: 'Lead',
        aliases: ['Pb'],
        source: CarcinogenSource.prop65,
        riskLevel: RiskLevel.critical,
        description: 'Heavy metal known to cause cancer and reproductive harm.',
        commonFoods: ['Some candies', 'Imported spices'],
      ),
    ];
    matcher = CarcinogenMatcher(testCarcinogens);
  });

  group('CarcinogenMatcher', () {
    group('findMatches', () {
      test('should find exact matches', () {
        final results = matcher.findMatches(['aspartame', 'water']);
        
        expect(results.length, equals(1));
        expect(results.first.ingredient, equals('aspartame'));
        expect(results.first.matchedCarcinogens.length, equals(1));
        expect(results.first.matchedCarcinogens.first.name, equals('Aspartame'));
      });

      test('should match by E-number alias', () {
        final results = matcher.findMatches(['e951', 'sugar']);
        
        expect(results.length, equals(1));
        expect(results.first.matchedCarcinogens.first.name, equals('Aspartame'));
      });

      test('should return empty list when no matches found', () {
        final results = matcher.findMatches(['water', 'salt', 'sugar']);
        
        expect(results, isEmpty);
      });

      test('should find multiple matches in ingredient list', () {
        final results = matcher.findMatches(['aspartame', 'acrylamide', 'water']);
        
        expect(results.length, equals(2));
      });

      test('should handle empty ingredient list', () {
        final results = matcher.findMatches([]);
        
        expect(results, isEmpty);
      });

      test('should match case-insensitively', () {
        final results = matcher.findMatches(['ASPARTAME']);
        
        expect(results.length, equals(1));
      });
    });

    group('getUniqueCarcinogens', () {
      test('should return unique carcinogens from results', () {
        final results = matcher.findMatches(['aspartame', 'acrylamide']);
        final unique = matcher.getUniqueCarcinogens(results);
        
        expect(unique.length, equals(2));
      });

      test('should return empty list for empty results', () {
        final unique = matcher.getUniqueCarcinogens([]);
        
        expect(unique, isEmpty);
      });
    });

    group('calculateOverallRisk', () {
      test('should return safe for empty carcinogen list', () {
        final risk = matcher.calculateOverallRisk([]);
        
        expect(risk, equals(RiskLevel.safe));
      });

      test('should return highest risk level from carcinogens', () {
        final risk = matcher.calculateOverallRisk([
          testCarcinogens[0], // medium
          testCarcinogens[1], // high
        ]);
        
        expect(risk, equals(RiskLevel.high));
      });

      test('should return critical for critical carcinogens', () {
        final risk = matcher.calculateOverallRisk([
          testCarcinogens[2], // critical
        ]);
        
        expect(risk, equals(RiskLevel.critical));
      });
    });
  });

  group('RiskLevel', () {
    test('should have correct labels', () {
      expect(RiskLevel.safe.label, equals('Safe'));
      expect(RiskLevel.low.label, equals('Low Risk'));
      expect(RiskLevel.medium.label, equals('Medium Risk'));
      expect(RiskLevel.high.label, equals('High Risk'));
      expect(RiskLevel.critical.label, equals('Critical Risk'));
    });

    test('should convert from value correctly', () {
      expect(RiskLevel.fromValue(0), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(1), equals(RiskLevel.low));
      expect(RiskLevel.fromValue(2), equals(RiskLevel.medium));
      expect(RiskLevel.fromValue(3), equals(RiskLevel.high));
      expect(RiskLevel.fromValue(4), equals(RiskLevel.critical));
    });

    test('should return safe for invalid values', () {
      expect(RiskLevel.fromValue(99), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(-1), equals(RiskLevel.safe));
    });

    test('should have descriptions', () {
      expect(RiskLevel.safe.description, isNotEmpty);
      expect(RiskLevel.critical.description, isNotEmpty);
    });

    test('should have short descriptions', () {
      expect(RiskLevel.safe.shortDescription, equals('No concerns found'));
      expect(RiskLevel.critical.shortDescription, equals('Known carcinogen'));
    });
  });
}
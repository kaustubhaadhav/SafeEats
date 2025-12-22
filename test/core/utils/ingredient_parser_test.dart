import 'package:flutter_test/flutter_test.dart';
import 'package:yuko/core/utils/ingredient_parser.dart';

void main() {
  group('IngredientParser', () {
    group('parse', () {
      test('should parse comma-separated ingredients', () {
        const text = 'Water, Sugar, Salt, Flour';
        final result = IngredientParser.parse(text);
        
        expect(result, contains('water'));
        expect(result, contains('sugar'));
        expect(result, contains('salt'));
        expect(result, contains('flour'));
      });

      test('should parse semicolon-separated ingredients', () {
        const text = 'Water; Sugar; Salt';
        final result = IngredientParser.parse(text);
        
        expect(result.length, greaterThanOrEqualTo(3));
        expect(result, contains('water'));
        expect(result, contains('sugar'));
      });

      test('should remove parenthetical information', () {
        const text = 'Sugar (from beets), Salt (sea salt), Water';
        final result = IngredientParser.parse(text);
        
        expect(result, contains('sugar'));
        expect(result, contains('salt'));
        expect(result.join(' ').contains('from beets'), isFalse);
      });

      test('should remove percentages', () {
        const text = 'Water 50%, Sugar 30%, Salt 20%';
        final result = IngredientParser.parse(text);
        
        expect(result, contains('water'));
        expect(result.join(' ').contains('50'), isFalse);
      });

      test('should return empty list for null or empty input', () {
        expect(IngredientParser.parse(''), isEmpty);
        expect(IngredientParser.parse(null), isEmpty);
        expect(IngredientParser.parse('   '), isEmpty);
      });

      test('should handle "and/or" delimiters', () {
        const text = 'Sugar and/or corn syrup, water';
        final result = IngredientParser.parse(text);
        
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('should handle "contains less than" pattern', () {
        const text = 'Water, Sugar, contains less than 2% of: salt, pepper';
        final result = IngredientParser.parse(text);
        
        expect(result, contains('water'));
        expect(result, contains('sugar'));
      });
    });

    group('extractENumbers', () {
      test('should extract E-numbers from text', () {
        const text = 'Water, E211, Sugar, E330, Salt';
        final result = IngredientParser.extractENumbers(text);
        
        expect(result, contains('e211'));
        expect(result, contains('e330'));
      });

      test('should handle E-numbers with spaces', () {
        const text = 'Contains E 211 and E 330';
        final result = IngredientParser.extractENumbers(text);
        
        expect(result, contains('e211'));
        expect(result, contains('e330'));
      });

      test('should handle E-numbers with letter suffixes', () {
        const text = 'Contains E150a and E160b';
        final result = IngredientParser.extractENumbers(text);
        
        expect(result, contains('e150a'));
        expect(result, contains('e160b'));
      });

      test('should return empty list when no E-numbers present', () {
        const text = 'Water, Sugar, Salt';
        final result = IngredientParser.extractENumbers(text);
        
        expect(result, isEmpty);
      });
    });

    group('normalize', () {
      test('should convert to lowercase and trim', () {
        expect(IngredientParser.normalize('  SUGAR  '), equals('sugar'));
      });

      test('should remove special characters', () {
        expect(IngredientParser.normalize('sugar*'), equals('sugar'));
        expect(IngredientParser.normalize('salt**'), equals('salt'));
      });

      test('should preserve hyphens', () {
        expect(
          IngredientParser.normalize('high-fructose corn syrup'),
          equals('high-fructose corn syrup'),
        );
      });
    });

    group('containsPreservatives', () {
      test('should detect preservatives', () {
        expect(IngredientParser.containsPreservatives('Contains sodium benzoate'), isTrue);
        expect(IngredientParser.containsPreservatives('With E211'), isTrue);
        expect(IngredientParser.containsPreservatives('BHA added'), isTrue);
      });

      test('should return false when no preservatives', () {
        expect(IngredientParser.containsPreservatives('Water, Sugar, Salt'), isFalse);
      });
    });

    group('containsArtificialColors', () {
      test('should detect artificial colors', () {
        expect(IngredientParser.containsArtificialColors('Contains Red 40'), isTrue);
        expect(IngredientParser.containsArtificialColors('With E129'), isTrue);
        expect(IngredientParser.containsArtificialColors('FD&C Yellow 5'), isTrue);
      });

      test('should return false when no artificial colors', () {
        expect(IngredientParser.containsArtificialColors('Water, Sugar, Salt'), isFalse);
      });
    });

    group('containsArtificialSweeteners', () {
      test('should detect artificial sweeteners', () {
        expect(IngredientParser.containsArtificialSweeteners('Contains aspartame'), isTrue);
        expect(IngredientParser.containsArtificialSweeteners('With sucralose'), isTrue);
        expect(IngredientParser.containsArtificialSweeteners('E951 added'), isTrue);
      });

      test('should return false when no artificial sweeteners', () {
        expect(IngredientParser.containsArtificialSweeteners('Water, Sugar, Salt'), isFalse);
      });
    });
  });
}
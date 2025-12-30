import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';
import 'package:safeeats/features/product/presentation/widgets/carcinogen_card.dart';
import 'package:safeeats/features/product/presentation/widgets/risk_indicator.dart';

void main() {
  const testCarcinogen = Carcinogen(
    id: 'test_001',
    name: 'Aspartame',
    aliases: ['E951', 'NutraSweet', 'Equal'],
    casNumber: '22839-47-0',
    source: CarcinogenSource.iarc,
    classification: 'Group 2B',
    riskLevel: RiskLevel.medium,
    description: 'Artificial sweetener possibly carcinogenic to humans.',
    commonFoods: ['Diet sodas', 'Sugar-free gum', 'Yogurt'],
    sourceUrl: 'https://monographs.iarc.who.int/',
  );

  const criticalCarcinogen = Carcinogen(
    id: 'test_002',
    name: 'Aflatoxins',
    aliases: ['Aflatoxin B1'],
    casNumber: '1402-68-2',
    source: CarcinogenSource.iarc,
    classification: 'Group 1',
    riskLevel: RiskLevel.critical,
    description: 'Naturally occurring mycotoxins produced by Aspergillus fungi.',
    commonFoods: ['Peanuts', 'Corn', 'Tree nuts'],
  );

  const prop65Carcinogen = Carcinogen(
    id: 'prop65_001',
    name: 'BPA',
    aliases: ['Bisphenol A'],
    casNumber: '80-05-7',
    source: CarcinogenSource.prop65,
    classification: 'Reproductive Toxicant',
    riskLevel: RiskLevel.low,
    description: 'Can leach from food containers.',
    commonFoods: ['Canned foods', 'Plastic containers'],
  );

  group('CarcinogenCard Widget Tests', () {
    testWidgets('displays carcinogen name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Aspartame'), findsOneWidget);
    });

    testWidgets('displays matched ingredient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'artificial sweetener',
                confidence: 0.95,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('artificial sweetener'), findsOneWidget);
    });

    testWidgets('displays confidence percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 0.85,
              ),
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays source information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('IARC'), findsOneWidget);
    });

    testWidgets('displays classification when present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Group 2B'), findsOneWidget);
    });

    testWidgets('displays RiskBadge with correct risk level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RiskBadge), findsOneWidget);
      expect(find.text('Medium Risk'), findsOneWidget);
    });

    testWidgets('displays critical risk correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: criticalCarcinogen,
                matchedIngredient: 'aflatoxin',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Critical Risk'), findsOneWidget);
      expect(find.text('Aflatoxins'), findsOneWidget);
    });

    testWidgets('displays Prop 65 source correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: prop65Carcinogen,
                matchedIngredient: 'bpa',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Prop 65'), findsOneWidget);
    });

    testWidgets('card is tappable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Find the InkWell and verify it exists
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('tapping card opens details bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      // Verify the bottom sheet is shown with detailed information
      expect(find.text('Source'), findsWidgets);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('handles 100% confidence display', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('handles low confidence display', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'sweetener',
                confidence: 0.50,
              ),
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('displays chevron icon indicating more details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('details sheet shows aliases when present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      // Verify aliases are shown
      expect(find.text('Also Known As'), findsOneWidget);
      expect(find.textContaining('E951'), findsOneWidget);
    });

    testWidgets('details sheet shows common foods when present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      // Verify common foods are shown
      expect(find.text('Commonly Found In'), findsOneWidget);
      expect(find.textContaining('Diet sodas'), findsOneWidget);
    });

    testWidgets('details sheet shows disclaimer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      // Verify disclaimer is shown
      expect(find.textContaining('educational purposes'), findsOneWidget);
    });
  });

  group('CarcinogenCard IARC Classification Tests', () {
    testWidgets('displays Group 1 classification description', (tester) async {
      const group1Carcinogen = Carcinogen(
        id: 'group1',
        name: 'Test Group 1',
        aliases: [],
        source: CarcinogenSource.iarc,
        classification: 'Group 1',
        riskLevel: RiskLevel.critical,
        description: 'Test description',
        commonFoods: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: group1Carcinogen,
                matchedIngredient: 'test',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      expect(find.textContaining('Carcinogenic to humans'), findsOneWidget);
    });

    testWidgets('displays Group 2A classification description', (tester) async {
      const group2aCarcinogen = Carcinogen(
        id: 'group2a',
        name: 'Test Group 2A',
        aliases: [],
        source: CarcinogenSource.iarc,
        classification: 'Group 2A',
        riskLevel: RiskLevel.high,
        description: 'Test description',
        commonFoods: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: group2aCarcinogen,
                matchedIngredient: 'test',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      expect(find.textContaining('Probably carcinogenic'), findsOneWidget);
    });

    testWidgets('displays Group 2B classification description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarcinogenCard(
                carcinogen: testCarcinogen,
                matchedIngredient: 'aspartame',
                confidence: 1.0,
              ),
            ),
          ),
        ),
      );

      // Open details sheet
      await tester.tap(find.byType(CarcinogenCard));
      await tester.pumpAndSettle();

      expect(find.textContaining('Possibly carcinogenic'), findsOneWidget);
    });
  });
}
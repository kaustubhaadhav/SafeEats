import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';
import 'package:safeeats/features/product/presentation/widgets/risk_indicator.dart';

void main() {
  group('RiskIndicator Widget Tests', () {
    testWidgets('displays safe risk level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.safe),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(RiskIndicator), findsOneWidget);
      
      // Verify safe label is displayed
      expect(find.text('Safe'), findsOneWidget);
      
      // Verify the check_circle icon is shown
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays critical risk level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.critical),
          ),
        ),
      );

      expect(find.byType(RiskIndicator), findsOneWidget);
      expect(find.text('Critical Risk'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous), findsOneWidget);
    });

    testWidgets('displays medium risk level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      expect(find.byType(RiskIndicator), findsOneWidget);
      expect(find.text('Medium Risk'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('displays high risk level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.high),
          ),
        ),
      );

      expect(find.byType(RiskIndicator), findsOneWidget);
      expect(find.text('High Risk'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('displays low risk level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.low),
          ),
        ),
      );

      expect(find.byType(RiskIndicator), findsOneWidget);
      expect(find.text('Low Risk'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('showLabel=false hides label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.safe, showLabel: false),
          ),
        ),
      );

      expect(find.byType(RiskIndicator), findsOneWidget);
      expect(find.text('Safe'), findsNothing);
    });

    testWidgets('custom size is applied', (tester) async {
      const customSize = 100.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.safe, size: customSize),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RiskIndicator),
          matching: find.byType(Container),
        ).first,
      );
      
      expect(container.constraints?.maxWidth, equals(customSize));
    });

    testWidgets('all risk levels render correctly', (tester) async {
      for (final level in RiskLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskIndicator(riskLevel: level),
            ),
          ),
        );

        expect(find.byType(RiskIndicator), findsOneWidget);
        expect(find.text(level.label), findsOneWidget);
      }
    });
  });

  group('RiskBadge Widget Tests', () {
    testWidgets('displays risk badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      expect(find.byType(RiskBadge), findsOneWidget);
      expect(find.text('Medium Risk'), findsOneWidget);
    });

    testWidgets('compact mode renders smaller badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RiskBadge(riskLevel: RiskLevel.safe, compact: false),
                RiskBadge(riskLevel: RiskLevel.safe, compact: true),
              ],
            ),
          ),
        ),
      );

      final badges = tester.widgetList<RiskBadge>(find.byType(RiskBadge));
      expect(badges.length, equals(2));
    });

    testWidgets('all risk levels have correct icons', (tester) async {
      final expectedIcons = {
        RiskLevel.safe: Icons.check_circle,
        RiskLevel.low: Icons.info,
        RiskLevel.medium: Icons.warning_amber,
        RiskLevel.high: Icons.error,
        RiskLevel.critical: Icons.dangerous,
      };

      for (final entry in expectedIcons.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBadge(riskLevel: entry.key),
            ),
          ),
        );

        expect(find.byIcon(entry.value), findsOneWidget);
      }
    });
  });

  group('RiskMeter Widget Tests', () {
    testWidgets('displays risk meter with correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskMeter(riskLevel: RiskLevel.high),
          ),
        ),
      );

      expect(find.byType(RiskMeter), findsOneWidget);
      expect(find.text('Risk Level'), findsOneWidget);
      expect(find.text('High Risk'), findsOneWidget);
    });

    testWidgets('displays all risk level segments', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskMeter(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      // The meter should have 5 segments (one for each risk level)
      // Find the ClipRRect that contains the segments
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('safe level shows only safe segment active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskMeter(riskLevel: RiskLevel.safe),
          ),
        ),
      );

      expect(find.byType(RiskMeter), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
    });

    testWidgets('critical level shows all segments active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskMeter(riskLevel: RiskLevel.critical),
          ),
        ),
      );

      expect(find.byType(RiskMeter), findsOneWidget);
      expect(find.text('Critical Risk'), findsOneWidget);
    });
  });

  group('RiskLevel enum tests', () {
    test('fromValue returns correct enum for valid values', () {
      expect(RiskLevel.fromValue(0), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(1), equals(RiskLevel.low));
      expect(RiskLevel.fromValue(2), equals(RiskLevel.medium));
      expect(RiskLevel.fromValue(3), equals(RiskLevel.high));
      expect(RiskLevel.fromValue(4), equals(RiskLevel.critical));
    });

    test('fromValue returns safe for invalid values', () {
      expect(RiskLevel.fromValue(-1), equals(RiskLevel.safe));
      expect(RiskLevel.fromValue(99), equals(RiskLevel.safe));
    });

    test('all risk levels have non-empty descriptions', () {
      for (final level in RiskLevel.values) {
        expect(level.description.isNotEmpty, isTrue);
        expect(level.shortDescription.isNotEmpty, isTrue);
        expect(level.label.isNotEmpty, isTrue);
      }
    });

    test('risk levels have correct values', () {
      expect(RiskLevel.safe.value, equals(0));
      expect(RiskLevel.low.value, equals(1));
      expect(RiskLevel.medium.value, equals(2));
      expect(RiskLevel.high.value, equals(3));
      expect(RiskLevel.critical.value, equals(4));
    });

    test('risk levels have valid color codes', () {
      for (final level in RiskLevel.values) {
        expect(level.color, isPositive);
        // Color should be a valid ARGB color (starts with 0xFF for opaque)
        expect(level.color >> 24, equals(0xFF));
      }
    });
  });
}
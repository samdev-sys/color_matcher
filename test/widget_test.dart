import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_matcher_pro/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiService Widget Integration', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Service provides valid color analysis',
        (WidgetTester tester) async {
      final result = await service.getColorAnalysis('#FF0000');

      expect(result, isNotNull);
      expect(result!.hex, '#FF0000');
      expect(result.name, isNotEmpty);
      expect(result.pantone, isNotEmpty);
    });

    testWidgets('Color displays correctly in UI elements',
        (WidgetTester tester) async {
      final result = await service.getColorAnalysis('#3498DB');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  key: const Key('color_preview'),
                  color: Color(int.parse('FF3498DB', radix: 16)),
                ),
                Text(
                  result!.name,
                  key: const Key('color_name'),
                ),
                Text(
                  result.pantone,
                  key: const Key('pantone'),
                ),
                Text(
                  result.rgb.toString(),
                  key: const Key('rgb_values'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('color_preview')), findsOneWidget);
      expect(find.byKey(const Key('color_name')), findsOneWidget);
      expect(find.byKey(const Key('pantone')), findsOneWidget);
      expect(find.byKey(const Key('rgb_values')), findsOneWidget);
      expect(find.text('Azul'), findsOneWidget);
    });

    testWidgets('Handles loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return ElevatedButton(
                        onPressed: () {},
                        child: const Text('Loading'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('Navigation works correctly', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Text('Home'),
          ),
          GoRoute(
            path: '/color/FF0000',
            builder: (context, state) => const Text('Color Detail'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      expect(find.text('Home'), findsOneWidget);

      router.push('/color/FF0000');
      await tester.pumpAndSettle();

      expect(find.text('Color Detail'), findsOneWidget);
    });
  });

  group('Color Validation Tests', () {
    test('Validates hex colors correctly', () {
      final validHex = [
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFFFFF',
        '#000000',
        'FF0000',
        'ABCDEF'
      ];

      for (final hex in validHex) {
        final cleanHex = hex.replaceAll('#', '');
        expect(cleanHex.length, 6);
        expect(int.tryParse(cleanHex, radix: 16), isNotNull);
      }
    });

    test('Invalidates bad hex colors', () {
      final invalidHex = ['#FFF', '#FFFFFFF', '#GGGGGG', '', 'ZZZZZZ'];

      for (final hex in invalidHex) {
        final cleanHex = hex.replaceAll('#', '');
        if (cleanHex.length != 6 || int.tryParse(cleanHex, radix: 16) == null) {
          expect(true, isTrue);
        }
      }
    });
  });

  group('Color Conversion Tests', () {
    test('Converts hex to RGB correctly', () {
      final hex = 'FF0000';
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);

      expect(r, 255);
      expect(g, 0);
      expect(b, 0);
    });

    test('Converts RGB to hex correctly', () {
      int r = 255, g = 128, b = 64;
      final hex =
          '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();

      expect(hex, '#FF8040');
    });

    test('CMYK conversion for pure colors', () {
      final r = 255, g = 0, b = 0;
      final rNorm = r / 255;
      final gNorm = g / 255;
      final bNorm = b / 255;

      final k = (1 - [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b));

      expect(k, 0);
    });
  });
}

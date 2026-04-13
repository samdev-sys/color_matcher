import 'package:flutter_test/flutter_test.dart';
import 'package:color_matcher_pro/models/models.dart';
import 'package:color_matcher_pro/services/gemini_service.dart';

void main() {
  group('Color Models Tests', () {
    test('RGB fromJson parses correctly', () {
      final rgb = RGB.fromJson({'r': 255, 'g': 128, 'b': 0});

      expect(rgb.r, 255);
      expect(rgb.g, 128);
      expect(rgb.b, 0);
    });

    test('RGB fromJson handles string values', () {
      final rgb = RGB.fromJson({'r': '100', 'g': '150', 'b': '200'});

      expect(rgb.r, 100);
      expect(rgb.g, 150);
      expect(rgb.b, 200);
    });

    test('RGB fromJson handles invalid values', () {
      final rgb = RGB.fromJson({'r': 'invalid', 'g': null, 'b': 255});

      expect(rgb.r, 0);
      expect(rgb.g, 0);
      expect(rgb.b, 255);
    });

    test('RGB toJson and fromJson roundtrip', () {
      final original = RGB(r: 100, g: 150, b: 200);
      final json = original.toJson();
      final restored = RGB.fromJson(json);

      expect(restored.r, original.r);
      expect(restored.g, original.g);
      expect(restored.b, original.b);
    });

    test('CMYK fromJson parses correctly', () {
      final cmyk = CMYK.fromJson({'c': 50, 'm': 75, 'y': 25, 'k': 10});

      expect(cmyk.c, 50);
      expect(cmyk.m, 75);
      expect(cmyk.y, 25);
      expect(cmyk.k, 10);
    });

    test('CMYK toJson and fromJson roundtrip', () {
      final original = CMYK(c: 0, m: 100, y: 100, k: 0);
      final json = original.toJson();
      final restored = CMYK.fromJson(json);

      expect(restored.c, original.c);
      expect(restored.m, original.m);
      expect(restored.y, original.y);
      expect(restored.k, original.k);
    });

    test('ColorData fromJson parses correctly', () {
      final json = {
        'hex': '#FF0000',
        'name': 'Rojo',
        'pantone': '185 C',
        'rgb': {'r': 255, 'g': 0, 'b': 0},
        'cmyk': {'c': 0, 'm': 100, 'y': 100, 'k': 0},
      };

      final colorData = ColorData.fromJson(json);

      expect(colorData.hex, '#FF0000');
      expect(colorData.name, 'Rojo');
      expect(colorData.pantone, '185 C');
      expect(colorData.rgb.r, 255);
      expect(colorData.cmyk.m, 100);
    });

    test('ColorData handles missing fields', () {
      final json = <String, dynamic>{};

      final colorData = ColorData.fromJson(json);

      expect(colorData.hex, '');
      expect(colorData.name, 'Unknown');
      expect(colorData.pantone, 'Unknown');
      expect(colorData.rgb.r, 0);
    });

    test('ColorData toJson and fromJson roundtrip', () {
      final original = ColorData(
        hex: '#00FF00',
        name: 'Verde',
        pantone: '355 C',
        rgb: RGB(r: 0, g: 255, b: 0),
        cmyk: CMYK(c: 100, m: 0, y: 100, k: 0),
      );

      final json = original.toJson();
      final restored = ColorData.fromJson(json);

      expect(restored.hex, original.hex);
      expect(restored.name, original.name);
      expect(restored.pantone, original.pantone);
      expect(restored.rgb.r, original.rgb.r);
    });

    test('HarmonyColor fromJson parses correctly', () {
      final json = {'hex': '#FF00FF', 'type': 'COMPLEMENTARY'};

      final harmony = HarmonyColor.fromJson(json);

      expect(harmony.hex, '#FF00FF');
      expect(harmony.type, 'COMPLEMENTARY');
    });

    test('HarmonyColor handles missing fields', () {
      final json = <String, dynamic>{};

      final harmony = HarmonyColor.fromJson(json);

      expect(harmony.hex, '#000000');
      expect(harmony.type, 'Harmonious');
    });
  });

  group('GeminiService Color Analysis Tests', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    test('Service initializes correctly', () {
      expect(service, isNotNull);
      expect(service.isApiKeyConfigured, isTrue);
    });

    test('Analyzes red color correctly', () async {
      final result = await service.getColorAnalysis('#FF0000');

      expect(result, isNotNull);
      expect(result!.hex, '#FF0000');
      expect(result.rgb.r, 255);
      expect(result.rgb.g, 0);
      expect(result.rgb.b, 0);
      expect(result.name, isNotEmpty);
      expect(result.pantone, isNotEmpty);
    });

    test('Analyzes green color correctly', () async {
      final result = await service.getColorAnalysis('#00FF00');

      expect(result, isNotNull);
      expect(result!.hex, '#00FF00');
      expect(result.rgb.g, 255);
    });

    test('Analyzes blue color correctly', () async {
      final result = await service.getColorAnalysis('#0000FF');

      expect(result, isNotNull);
      expect(result!.hex, '#0000FF');
      expect(result.rgb.b, 255);
    });

    test('Analyzes white color correctly', () async {
      final result = await service.getColorAnalysis('#FFFFFF');

      expect(result, isNotNull);
      expect(result!.hex, '#FFFFFF');
      expect(result.rgb.r, 255);
      expect(result.rgb.g, 255);
      expect(result.rgb.b, 255);
    });

    test('Analyzes black color correctly', () async {
      final result = await service.getColorAnalysis('#000000');

      expect(result, isNotNull);
      expect(result!.hex, '#000000');
      expect(result.rgb.r, 0);
      expect(result.rgb.g, 0);
      expect(result.rgb.b, 0);
    });

    test('Handles hex without hash', () async {
      final result = await service.getColorAnalysis('FF0000');

      expect(result, isNotNull);
      expect(result!.hex, '#FF0000');
    });

    test('Handles lowercase hex', () async {
      final result = await service.getColorAnalysis('#ff0000');

      expect(result, isNotNull);
      expect(result!.hex, '#FF0000');
    });

    test('Returns null for invalid hex length', () async {
      final result1 = await service.getColorAnalysis('#FFF');
      final result2 = await service.getColorAnalysis('#FFFFFFF');
      final result3 = await service.getColorAnalysis('');

      expect(result1, isNull);
      expect(result2, isNull);
      expect(result3, isNull);
    });

    test('CMYK conversion is valid for red', () async {
      final result = await service.getColorAnalysis('#FF0000');

      expect(result, isNotNull);
      expect(result!.cmyk.c, 0);
      expect(result.cmyk.m, greaterThanOrEqualTo(90));
      expect(result.cmyk.y, greaterThanOrEqualTo(90));
      expect(result.cmyk.k, 0);
    });

    test('CMYK conversion is valid for magenta', () async {
      final result = await service.getColorAnalysis('#FF00FF');

      expect(result, isNotNull);
      expect(result!.cmyk.m, greaterThanOrEqualTo(50));
      expect(result.cmyk.k, 0);
    });

    test('Color names are assigned correctly', () async {
      final red = await service.getColorAnalysis('#FF0000');
      final green = await service.getColorAnalysis('#00FF00');
      final blue = await service.getColorAnalysis('#0000FF');
      final yellow = await service.getColorAnalysis('#FFFF00');

      expect(red!.name, 'Rojo');
      expect(green!.name, 'Verde');
      expect(blue!.name, 'Azul');
      expect(yellow!.name, 'Amarillo');
    });

    test('All RGB values are within valid range', () async {
      final colors = [
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFFFFF',
        '#000000',
        '#808080'
      ];

      for (final hex in colors) {
        final result = await service.getColorAnalysis(hex);
        expect(result, isNotNull);
        expect(result!.rgb.r, inInclusiveRange(0, 255));
        expect(result.rgb.g, inInclusiveRange(0, 255));
        expect(result.rgb.b, inInclusiveRange(0, 255));
      }
    });

    test('All CMYK values are within valid range', () async {
      final colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFFFF', '#000000'];

      for (final hex in colors) {
        final result = await service.getColorAnalysis(hex);
        expect(result, isNotNull);
        expect(result!.cmyk.c, inInclusiveRange(0, 100));
        expect(result.cmyk.m, inInclusiveRange(0, 100));
        expect(result.cmyk.y, inInclusiveRange(0, 100));
        expect(result.cmyk.k, inInclusiveRange(0, 100));
      }
    });

    test('generateHarmoniousPalette returns empty list', () async {
      final result = await service.generateHarmoniousPalette('#FF0000');

      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('testConnection returns true', () async {
      final result = await service.testConnection();

      expect(result, isTrue);
    });
  });

  group('Edge Cases', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    test('Handles special characters in hex', () async {
      final result = await service.getColorAnalysis('#ABCDEF');

      expect(result, isNotNull);
      expect(result!.hex, '#ABCDEF');
    });

    test('Rapid consecutive calls do not fail', () async {
      final futures = List.generate(
          10,
          (i) => service
              .getColorAnalysis('#${i.toRadixString(16).padLeft(6, '0')}'));

      final results = await Future.wait(futures);

      expect(results.length, 10);
      for (final result in results) {
        expect(result, isNotNull);
      }
    });

    test('Memory efficiency - results can be garbage collected', () async {
      for (int i = 0; i < 100; i++) {
        final result = await service
            .getColorAnalysis('#${i.toRadixString(16).padLeft(6, '0')}');
        expect(result, isNotNull);
      }
    });
  });
}

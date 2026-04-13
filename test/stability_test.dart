import 'package:flutter_test/flutter_test.dart';
import 'package:color_matcher_pro/models/models.dart';
import 'package:color_matcher_pro/services/gemini_service.dart';

void main() {
  group('Stability Tests', () {
    test('GeminiService initializes without errors', () {
      final service = GeminiService();
      expect(service, isNotNull);
      expect(service.isApiKeyConfigured, isTrue);
    });

    test('Service can analyze multiple colors consecutively', () async {
      final service = GeminiService();

      for (int i = 0; i < 20; i++) {
        final hex = '#${i.toRadixString(16).padLeft(6, '0').toUpperCase()}';
        final result = await service.getColorAnalysis(hex);
        expect(result, isNotNull, reason: 'Failed for $hex');
      }
    });

    test('JSON serialization roundtrip for all models', () {
      final rgb = RGB(r: 100, g: 150, b: 200);
      final rgbRestored = RGB.fromJson(rgb.toJson());
      expect(rgbRestored.r, rgb.r);
      expect(rgbRestored.g, rgb.g);
      expect(rgbRestored.b, rgb.b);

      final cmyk = CMYK(c: 50, m: 75, y: 25, k: 10);
      final cmykRestored = CMYK.fromJson(cmyk.toJson());
      expect(cmykRestored.c, cmyk.c);

      final colorData = ColorData(
        hex: '#FF0000',
        name: 'Rojo',
        pantone: '185 C',
        rgb: RGB(r: 255, g: 0, b: 0),
        cmyk: CMYK(c: 0, m: 100, y: 100, k: 0),
      );
      final colorRestored = ColorData.fromJson(colorData.toJson());
      expect(colorRestored.hex, colorData.hex);
    });

    test('All color models handle edge case values', () {
      final black = RGB(r: 0, g: 0, b: 0);
      final white = RGB(r: 255, g: 255, b: 255);

      expect(black.toJson()['r'], 0);
      expect(white.toJson()['r'], 255);

      final cmykBlack = CMYK(c: 0, m: 0, y: 0, k: 100);
      final cmykWhite = CMYK(c: 0, m: 0, y: 0, k: 0);

      expect(cmykBlack.toJson()['k'], 100);
      expect(cmykWhite.toJson()['k'], 0);
    });

    test('HarmonyColor model works correctly', () {
      final harmony = HarmonyColor(hex: '#FF00FF', type: 'COMPLEMENTARY');
      expect(harmony.hex, '#FF00FF');
      expect(harmony.type, 'COMPLEMENTARY');

      final fromJson =
          HarmonyColor.fromJson({'hex': '#00FF00', 'type': 'ANALOGOUS'});
      expect(fromJson.hex, '#00FF00');
    });
  });

  group('Performance Tests', () {
    test('Color analysis completes within acceptable time', () async {
      final service = GeminiService();
      final stopwatch = Stopwatch()..start();

      await service.getColorAnalysis('#FF0000');
      await service.getColorAnalysis('#00FF00');
      await service.getColorAnalysis('#0000FF');

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('Can handle rapid sequential analysis', () async {
      final service = GeminiService();
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await service.getColorAnalysis(
            '#${i.toRadixString(16).padLeft(6, '0').toUpperCase()}');
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });

  group('Integration Tests', () {
    test('Full workflow: analyze -> serialize -> deserialize', () async {
      final service = GeminiService();

      final original = await service.getColorAnalysis('#3366FF');
      expect(original, isNotNull);

      final json = original!.toJson();
      expect(json['hex'], '#3366FF');
      expect(json['name'], isNotEmpty);

      final restored = ColorData.fromJson(json);
      expect(restored.hex, original.hex);
      expect(restored.name, original.name);
      expect(restored.pantone, original.pantone);
    });

    test('Multiple colors maintain data integrity', () async {
      final service = GeminiService();
      final colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF'];

      for (final hex in colors) {
        final result = await service.getColorAnalysis(hex);
        expect(result, isNotNull);
        expect(result!.hex.toUpperCase(), hex.toUpperCase());
        expect(result.rgb.r, inInclusiveRange(0, 255));
        expect(result.rgb.g, inInclusiveRange(0, 255));
        expect(result.rgb.b, inInclusiveRange(0, 255));
      }
    });
  });
}

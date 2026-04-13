import 'dart:math';
import '../models/models.dart';

class GeminiService {
  bool get isApiKeyConfigured => true;

  Future<ColorData?> getColorAnalysis(String hex) async {
    hex = hex.replaceAll('#', '').toUpperCase();

    if (hex.length != 6) return null;

    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);

    final colorInfo = _getColorInfo(r, g, b);

    return ColorData(
      hex: '#$hex',
      name: colorInfo['name']!,
      pantone: colorInfo['pantone']!,
      rgb: RGB(r: r, g: g, b: b),
      cmyk: _rgbToCmyk(r, g, b),
    );
  }

  Future<List<HarmonyColor>> generateHarmoniousPalette(String baseHex) async {
    return [];
  }

  Future<bool> testConnection() async {
    return true;
  }

  CMYK _rgbToCmyk(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) {
      return CMYK(c: 0, m: 0, y: 0, k: 100);
    }

    if (r == 255 && g == 255 && b == 255) {
      return CMYK(c: 0, m: 0, y: 0, k: 0);
    }

    final double rNorm = r / 255.0;
    final double gNorm = g / 255.0;
    final double bNorm = b / 255.0;

    final double k = 1.0 - max(rNorm, max(gNorm, bNorm));
    final double denom = 1.0 - k;

    int c = denom > 0 ? ((1.0 - rNorm - k) / denom * 100).round() : 0;
    int m = denom > 0 ? ((1.0 - gNorm - k) / denom * 100).round() : 0;
    int y = denom > 0 ? ((1.0 - bNorm - k) / denom * 100).round() : 0;
    int kPercent = (k * 100).round();

    c = c.clamp(0, 100);
    m = m.clamp(0, 100);
    y = y.clamp(0, 100);

    return CMYK(c: c, m: m, y: y, k: kPercent);
  }

  List<double> _rgbToHsl(int r, int g, int b) {
    double rNorm = r / 255;
    double gNorm = g / 255;
    double bNorm = b / 255;

    double maxVal = max(rNorm, max(gNorm, bNorm));
    double minVal = min(rNorm, min(gNorm, bNorm));
    double h = 0, s = 0, l = (maxVal + minVal) / 2;

    if (maxVal != minVal) {
      double d = maxVal - minVal;
      s = l > 0.5 ? d / (2 - maxVal - minVal) : d / (maxVal + minVal);

      if (maxVal == rNorm) {
        h = ((gNorm - bNorm) / d + (gNorm < bNorm ? 6 : 0)) * 60;
      } else if (maxVal == gNorm) {
        h = ((bNorm - rNorm) / d + 2) * 60;
      } else {
        h = ((rNorm - gNorm) / d + 4) * 60;
      }
    }

    return [h, s * 100, l * 100];
  }

  Map<String, String> _getColorInfo(int r, int g, int b) {
    final hue = _rgbToHsl(r, g, b)[0];
    final saturation = _rgbToHsl(r, g, b)[1];
    final lightness = _rgbToHsl(r, g, b)[2];

    String name;
    String pantone;

    if (saturation < 10) {
      if (lightness < 20) {
        name = 'Negro';
        pantone = 'Black 6 C';
      } else if (lightness > 80) {
        name = 'Blanco';
        pantone = 'White C';
      } else {
        name = 'Gris';
        pantone = 'Cool Gray 7 C';
      }
    } else if (hue < 15 || hue >= 345) {
      name = 'Rojo';
      pantone = '185 C';
    } else if (hue < 45) {
      name = 'Naranja';
      pantone = '021 C';
    } else if (hue < 70) {
      name = 'Amarillo';
      pantone = '102 C';
    } else if (hue < 160) {
      name = 'Verde';
      pantone = '355 C';
    } else if (hue < 200) {
      name = 'Cyan';
      pantone = 'Process Cyan C';
    } else if (hue < 260) {
      name = 'Azul';
      pantone = '286 C';
    } else if (hue < 290) {
      name = 'Violeta';
      pantone = 'Violet C';
    } else {
      name = 'Rosa';
      pantone = 'Rhodamine Red C';
    }

    return {'name': name, 'pantone': pantone};
  }
}

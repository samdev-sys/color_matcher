import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/models.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  // Helper function to extract JSON from a string
  String _extractJson(String str) {
    final jsonStart = str.indexOf('{');
    final jsonEnd = str.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1) {
      return str.substring(jsonStart, jsonEnd + 1);
    }
    final arrayStart = str.indexOf('[');
    final arrayEnd = str.lastIndexOf(']');
    if (arrayStart != -1 && arrayEnd != -1) {
      return str.substring(arrayStart, arrayEnd + 1);
    }
    return str; // Return original if no JSON structure is found
  }

  Future<ColorData?> getColorAnalysis(String hex) async {
    if (dotenv.env['GEMINI_API_KEY'] == null) return null;

    final prompt = '''
    For the hex color $hex, provide:
    1. A common name.
    2. An approximate Pantone code.
    3. RGB values (r, g, b).
    4. CMYK values (c, m, y, k).
    5. A brief description of the color's psychology (max 2 sentences).
    6. 3 professional usage tips for this color in design.

    Respond ONLY with a valid JSON object with these exact keys: 
    "name", "pantone", "rgb" (object), "cmyk" (object), "psychology" (string), "usageTips" (array of strings).
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final jsonString = _extractJson(response.text!); 
        final json = jsonDecode(jsonString);
        return ColorData.fromJson({
          ...json,
          'hex': hex,
        });
      }
    } catch (e) {
      print('Error parsing color analysis JSON: $e');
    }
    return null;
  }

  Future<List<HarmonyColor>> generateHarmoniousPalette(String baseHex) async {
    if (dotenv.env['GEMINI_API_KEY'] == null) return [];

    final prompt = 'Based on the color $baseHex, generate a professional 4-color palette including complementary, analogous, and monochromatic variations. Return ONLY a JSON array of objects with keys: hex, type (COMPLEMENTARY, ANALOGOUS, MONOCHROME, etc).';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
       if (response.text != null) {
        final jsonString = _extractJson(response.text!);
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((j) => HarmonyColor.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error getting palette: $e');
    }
    return [];
  }
}

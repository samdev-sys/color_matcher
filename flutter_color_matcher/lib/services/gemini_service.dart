import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/models.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Using a standard available model alias
      apiKey: apiKey,
    );
  }

  Future<ColorData?> getColorAnalysis(String hex) async {
    if (dotenv.env['GEMINI_API_KEY'] == null) return null;

    final prompt = 'Analyze the color $hex. Provide its common name, a matching Pantone code (approximate), and a brief 2-sentence psychological meaning or usage recommendation. Respond in JSON with keys: name, pantone, description, rgb (object with r, g, b).';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      print('Gemini Response: ${response.text}');
      
      if (response.text != null) {
        final json = jsonDecode(response.text!);
        // Ensure hex is passed back or attached
        final data = ColorData.fromJson(json);
        // We might want to construct a new object to include the hex if it wasn't in JSON
        return ColorData(
          hex: hex, 
          name: data.name, 
          pantone: data.pantone, 
          rgb: data.rgb, 
          description: data.description
        );
      }
    } catch (e) {
      print('Error calling Gemini: $e');
    }
    return null;
  }

  Future<List<HarmonyColor>> generateHarmoniousPalette(String baseHex) async {
    if (dotenv.env['GEMINI_API_KEY'] == null) return [];

    final prompt = 'Based on the color $baseHex, generate a professional 4-color palette including complementary, analogous, and monochromatic variations. Return ONLY a JSON array of objects with keys: hex, type (COMPLEMENTARY, ANALOGOUS, MONOCHROME, etc).';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
       if (response.text != null) {
        final List<dynamic> jsonList = jsonDecode(response.text!);
        return jsonList.map((j) => HarmonyColor.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error getting palette: $e');
    }
    return [];
  }
}

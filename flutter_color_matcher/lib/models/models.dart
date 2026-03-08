class ColorData {
  final String hex;
  final String name;
  final String pantone;
  final RGB rgb;
  final String? description;

  ColorData({
    required this.hex,
    required this.name,
    required this.pantone,
    required this.rgb,
    this.description,
  });

  factory ColorData.fromJson(Map<String, dynamic> json) {
    return ColorData(
      hex: json['hex'] ?? '', // Sometimes hex is not in the root response from Gemini if we don't ask for it, handling carefully
      name: json['name'] ?? 'Unknown',
      pantone: json['pantone'] ?? 'Unknown',
      rgb: RGB.fromJson(json['rgb'] ?? {'r': 0, 'g': 0, 'b': 0}),
      description: json['description'],
    );
  }
}

class RGB {
  final int r;
  final int g;
  final int b;

  RGB({required this.r, required this.g, required this.b});

  factory RGB.fromJson(Map<String, dynamic> json) {
    return RGB(
      r: json['r'] is int ? json['r'] : int.tryParse(json['r'].toString()) ?? 0,
      g: json['g'] is int ? json['g'] : int.tryParse(json['g'].toString()) ?? 0,
      b: json['b'] is int ? json['b'] : int.tryParse(json['b'].toString()) ?? 0,
    );
  }
  
  @override
  String toString() => '$r, $g, $b';
}

class Palette {
  final String id;
  final String name;
  final List<String> colors; // hex codes
  final String createdAt;

  Palette({
    required this.id,
    required this.name,
    required this.colors,
    required this.createdAt,
  });
}

class HarmonyColor {
  final String hex;
  final String type;

  HarmonyColor({required this.hex, required this.type});

  factory HarmonyColor.fromJson(Map<String, dynamic> json) {
    return HarmonyColor(
      hex: json['hex'] ?? '#000000',
      type: json['type'] ?? 'Harmonious',
    );
  }
}

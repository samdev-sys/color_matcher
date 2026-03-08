class ColorData {
  final String hex;
  final String name;
  final String pantone;
  final RGB rgb;
  final CMYK cmyk;
  final String? psychology;
  final List<String>? usageTips;

  ColorData({
    required this.hex,
    required this.name,
    required this.pantone,
    required this.rgb,
    required this.cmyk,
    this.psychology,
    this.usageTips,
  });

  factory ColorData.fromJson(Map<String, dynamic> json) {
    return ColorData(
      hex: json['hex'] ?? '',
      name: json['name'] ?? 'Unknown',
      pantone: json['pantone'] ?? 'Unknown',
      rgb: RGB.fromJson(json['rgb'] ?? {'r': 0, 'g': 0, 'b': 0}),
      cmyk: CMYK.fromJson(json['cmyk'] ?? {'c': 0, 'm': 0, 'y': 0, 'k': 0}),
      psychology: json['psychology'],
      usageTips: json['usageTips'] != null ? List<String>.from(json['usageTips']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'hex': hex,
    'name': name,
    'pantone': pantone,
    'rgb': rgb.toJson(),
    'cmyk': cmyk.toJson(),
    'psychology': psychology,
    'usageTips': usageTips,
  };
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

  Map<String, dynamic> toJson() => {
    'r': r,
    'g': g,
    'b': b,
  };
  
  @override
  String toString() => '$r, $g, $b';
}

class CMYK {
  final int c;
  final int m;
  final int y;
  final int k;

  CMYK({required this.c, required this.m, required this.y, required this.k});

  factory CMYK.fromJson(Map<String, dynamic> json) {
    return CMYK(
      c: json['c'] is int ? json['c'] : int.tryParse(json['c'].toString()) ?? 0,
      m: json['m'] is int ? json['m'] : int.tryParse(json['m'].toString()) ?? 0,
      y: json['y'] is int ? json['y'] : int.tryParse(json['y'].toString()) ?? 0,
      k: json['k'] is int ? json['k'] : int.tryParse(json['k'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'c': c,
    'm': m,
    'y': y,
    'k': k,
  };

  @override
  String toString() => '$c, $m, $y, $k';
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

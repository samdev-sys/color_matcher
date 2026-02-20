import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ColorDetectorScreen extends StatefulWidget {
  const ColorDetectorScreen({super.key});

  @override
  State<ColorDetectorScreen> createState() => _ColorDetectorScreenState();
}

class _ColorDetectorScreenState extends State<ColorDetectorScreen> {
  // 1. Variable para guardar los colores una vez cargados
  List<dynamic> pantoneList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 2. Llamamos a la función de carga al iniciar la pantalla
    initDatabase();
  }

  Future<void> initDatabase() async {
    try {
      final String response = await rootBundle.loadString('assets/pantone_db.json');
      final data = json.decode(response);
      setState(() {
        pantoneList = data; // Guardamos la lista del JSON
        isLoading = false;  // Ya terminó de cargar
      });
    } catch (e) {
      print("Error cargando el JSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pantone Detector")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Muestra carga
          : ListView.builder(
        itemCount: pantoneList.length,
        itemBuilder: (context, index) {
          final item = pantoneList[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              color: Color(int.parse(item['hex'].replaceFirst('#', '0xFF'))),
            ),
            title: Text(item['pantone']),
            subtitle: Text(item['hex']),
          );
        },
      ),
    );
  }
}
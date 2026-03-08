import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/history_service.dart';
import '../theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  late Future<List<ColorData>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.getHistory();
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all saved colors?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      setState(() {
        _historyFuture = _historyService.getHistory(); // Refresh the list
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: FutureBuilder<List<ColorData>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No colors saved yet.', style: TextStyle(fontSize: 18, color: Colors.grey))
                ],
              ),
            );
          } else {
            final history = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final colorData = history[index];
                // Safe parsing of hex to color
                Color displayColor = Colors.grey;
                try {
                  final hexStr = colorData.hex.replaceAll('#', '');
                  if (hexStr.length == 6) {
                    displayColor = Color(int.parse('FF$hexStr', radix: 16));
                  }
                } catch (e) {
                  print('Error parsing color: $e');
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 40, height: 40, color: displayColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(colorData.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(colorData.hex, style: const TextStyle(color: Colors.grey))
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 10),
                        _buildInfoRow('Pantone', colorData.pantone),
                        _buildInfoRow('RGB', colorData.rgb.toString()),
                        _buildInfoRow('CMYK', colorData.cmyk.toString()),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(value, style: const TextStyle(fontSize: 16))
        ],
      ),
    );
  }
}

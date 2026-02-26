import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  final String? colorHex;
  final String? pantoneName;

  const DashboardPage({super.key, this.colorHex, this.pantoneName});

  @override
  Widget build(BuildContext context) {
    final Color displayColor = colorHex != null
        ? Color(int.parse(colorHex!.substring(0, 6), radix: 16) + 0xFF000000)
        : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Dashboard'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pantoneName ?? 'N/A',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '#${colorHex?.toUpperCase() ?? ''}',
               style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.go('/scanner'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

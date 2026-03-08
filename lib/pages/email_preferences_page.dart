import 'package:flutter/material.dart';

class EmailPreferencesPage extends StatelessWidget {
  const EmailPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Preferences')),
      body: const Center(
        child: Text('Email preference options will be here.'),
      ),
    );
  }
}

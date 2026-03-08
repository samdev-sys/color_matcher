import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/logger_service.dart';
import '../theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          // Profile picture section
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'), // Placeholder
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // TextFields for user info
          TextFormField(
            initialValue: 'User Name',
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: 'user@example.com',
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 40),

          // Dark mode switch
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable or disable dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
                LoggerService.logger.i("Dark mode toggled: $value");
                // TODO: Add logic to change theme and save preference
              });
            },
            secondary: const Icon(Icons.dark_mode_outlined),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              LoggerService.logger.i("User saved profile changes.");
              // TODO: Add save logic
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

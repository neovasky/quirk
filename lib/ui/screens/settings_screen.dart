import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return ListTile(
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeService.themeMode,
                  onChanged: (ThemeMode? mode) {
                    if (mode != null) {
                      themeService.setThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Add more settings here
        ],
      ),
    );
  }
}
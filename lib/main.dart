import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/task_service.dart';
import 'core/services/theme_service.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Quirk',
            themeMode: themeService.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              listTileTheme: const ListTileThemeData(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                horizontalTitleGap: 8,
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                shadowColor: Colors.black.withOpacity(0.4),
              ),
              listTileTheme: const ListTileThemeData(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                horizontalTitleGap: 8,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
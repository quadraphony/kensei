import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/profile_service.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await ProfileService().initialize();
  final themeService = ThemeService();

  
  runApp(
    ChangeNotifierProvider<ThemeService>(
      create: (context) => themeService,
      child: const KenseiTunnelApp(),
    ),
  );
}

class KenseiTunnelApp extends StatelessWidget {
  const KenseiTunnelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kensei Tunnel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: Provider.of<ThemeService>(context).themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


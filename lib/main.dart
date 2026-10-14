import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kustomisasi Status Bar & Navigation Bar agar serasi dengan Dark Mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppConfig.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LumajangNetworkApp());
}

class LumajangNetworkApp extends StatelessWidget {
  const LumajangNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConfig.backgroundDark,
        primaryColor: AppConfig.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: AppConfig.primaryColor,
          surface: AppConfig.surfaceDark,
          onPrimary: Colors.white,
          onSurface: AppConfig.textLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConfig.backgroundDark,
          elevation: 0,
          foregroundColor: AppConfig.textLight,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

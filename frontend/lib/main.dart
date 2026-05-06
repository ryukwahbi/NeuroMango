import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'theme.dart';
import 'globals.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera error: $e');
  }
  runApp(const MangoTrackApp());
}

class MangoTrackApp extends StatelessWidget {
  const MangoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroMango',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: mangoBackground,
        primaryColor: mangoPrimary,
        colorScheme: const ColorScheme.light(
          primary: mangoPrimary,
          secondary: mangoAccent,
          surface: mangoSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: mangoText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: mangoPrimary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: mangoPrimary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

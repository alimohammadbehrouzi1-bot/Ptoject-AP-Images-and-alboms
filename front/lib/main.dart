import 'package:flutter/material.dart';
import 'auth_screens.dart';

void main() {
  runApp(const PhotoSocialApp());
}

class PhotoSocialApp extends StatelessWidget {
  const PhotoSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Social',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          primary: const Color(0xFF1A73E8),
          secondary: const Color(0xFF00C853),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

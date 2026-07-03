import 'package:flutter/material.dart';
import 'data_service.dart';
import 'auth_screens.dart';
import 'user_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService().init();
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
      ),
      // Check if someone is already logged in (for simulation)
      home: DataService().currentUsername != null
        ? MainNavigation(username: DataService().currentUsername!) 
        : const LoginScreen(),
    );
  }
}

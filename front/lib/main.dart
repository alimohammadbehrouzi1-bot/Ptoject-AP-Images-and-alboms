import 'package:flutter/material.dart';
import 'data_service.dart';
import 'auth_screens.dart';
import 'user_screens.dart';
import 'admin_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService().init();
  runApp(const PhotoSocialApp());
}

class PhotoSocialApp extends StatelessWidget {
  const PhotoSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DataService().themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Photo Social',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: mode,
          // Persistent Login Logic using static variable simulation
          home: DataService().currentUsername != null
            ? (DataService().currentUsername == 'admin'
                ? const AdminDashboard()
                : MainNavigation(username: DataService().currentUsername!))
            : const LoginScreen(),
        );
      },
    );
  }
}

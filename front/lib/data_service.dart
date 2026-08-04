import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_request.dart';
import 'core/network/api_response.dart';
import 'core/network/api_routes.dart';
import 'core/network/socket_client.dart';
import 'user_screens.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<dynamic> rawUsers = [];
  List<dynamic> rawAdmins = [];
  String? currentUsername;
  bool isAdminLoggedIn = false;

  final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? savedTheme = prefs.getString('theme_mode');
      if (savedTheme == 'dark') themeNotifier.value = ThemeMode.dark;
      if (savedTheme == 'light') themeNotifier.value = ThemeMode.light;

      final String? savedUser = prefs.getString('saved_session_user');
      if (savedUser != null) {
        currentUsername = savedUser;
        isAdminLoggedIn = (savedUser == 'admin');
      }
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    final request = ApiRequest(
      route: ApiRoutes.loginUser,
      payload: {'username': username, 'password': password},
    );

    try {
      final response = await SocketClient().sendRequest(request);

      if (response.isSuccess) {
        currentUsername = username;
        isAdminLoggedIn = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_session_user', currentUsername!);
        return {'username': username};
      } else if (response.statusCode == 403) {
        return {'error': 'BANNED'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return null;
  }

  Future<bool> loginAdmin(String username, String password) async {
    final request = ApiRequest(
      route: ApiRoutes.loginAdmin,
      payload: {'username': username, 'password': password},
    );

    try {
      final response = await SocketClient().sendRequest(request);

      if (response.isSuccess) {
        currentUsername = 'admin';
        isAdminLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_session_user', 'admin');
        return true;
      }
    } catch (e) {
      debugPrint('Admin login error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    currentUsername = null;
    isAdminLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_session_user');
    await SocketClient().disconnect();
  }

  Future<bool> registerUser({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    final request = ApiRequest(
      route: ApiRoutes.register,
      payload: {
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
      },
    );

    try {
      final response = await SocketClient().sendRequest(request);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  bool changeUsername(String oldName, String newName) {
    if (currentUsername == oldName) {
      currentUsername = newName;
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString('saved_session_user', newName),
      );
    }
    return true;
  }

  // Stubs for remaining methods - these will be connected to Socket in future phases
  List<FileItem> getAllPhotos() => [];
  List<FileItem> getVaultItems(String username) => [];
  Map<String, int> getUserStats(String username) => {'photos': 0, 'albums': 0};
  void deleteItem(int id) {}
  void movePhotos(List<int> photoIds, int? targetAlbumId) {}
  void addAlbum(String username, String name) {}
  void addImage(String username, Map<String, dynamic> data) {}
  void updatePhoto(int id, String? caption, List<String>? tags) {}
  void toggleLike(int photoId) {}
  void addComment(int photoId, String username, String text) {}
  void deleteAccount(String username) {}
  void toggleBan(String username) {}

  void toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }
}

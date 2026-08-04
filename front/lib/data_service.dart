import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/server_config.dart';
import 'core/network/api_request.dart';
import 'core/network/api_response.dart';
import 'core/network/api_routes.dart';
import 'user_screens.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  String? currentUsername;
  bool isAdminLoggedIn = false;

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  Socket? _socket;

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

  Future<Socket> _getSocket() async {
    if (_socket == null) {
      _socket = await Socket.connect(ServerConfig.host, ServerConfig.port);
    }
    return _socket!;
  }

  Future<ApiResponse> _sendRequest(ApiRequest request) async {
    try {
      final socket = await _getSocket();
      socket.write(request.encode());
      
      final responseStr = await utf8.decoder.bind(socket).transform(const LineSplitter()).first;
      return ApiResponse.fromJson(jsonDecode(responseStr));
    } catch (e) {
      _socket = null;
      return ApiResponse.error(e.toString());
    }
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final request = ApiRequest(
      route: ApiRoutes.loginUser,
      payload: {'username': username, 'password': password},
    );

    final response = await _sendRequest(request);

    if (response.isSuccess) {
      currentUsername = username;
      isAdminLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_session_user', currentUsername!);
      return {'username': username};
    } else if (response.statusCode == 403) {
      return {'error': 'BANNED'};
    }
    return null;
  }

  Future<bool> loginAdmin(String username, String password) async {
    final request = ApiRequest(
      route: ApiRoutes.loginAdmin,
      payload: {'username': username, 'password': password},
    );

    final response = await _sendRequest(request);

    if (response.isSuccess) {
      currentUsername = 'admin';
      isAdminLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_session_user', 'admin');
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    currentUsername = null;
    isAdminLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_session_user');
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
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

    final response = await _sendRequest(request);
    return response.isSuccess;
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

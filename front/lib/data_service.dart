import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_request.dart';
import 'core/network/api_routes.dart';
import 'core/network/socket_client.dart';
import 'user_screens.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

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

  Future<List<FileItem>> getAllPhotos() async {
    final request = ApiRequest(
      route: ApiRoutes.getAllImages,
      payload: {},
    );

    try {
      final response = await SocketClient().sendRequest(request);
      if (response.isSuccess && response.data != null) {
        final List<dynamic> images = response.data['images'] ?? [];
        return images.map((img) {
          // imageData is Base64 from server
          return FileItem(
            id: (img['id'] as num).toInt(),
            name: img['name'] ?? 'Untitled',
            isFolder: false,
            ownerName: img['owner'] ?? 'Unknown',
            caption: img['caption'],
            tags: List<String>.from(img['tags'] ?? []),
            date: DateTime.now(), // Server should provide date ideally
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getting photos: $e');
    }
    return [];
  }

  Future<void> addImage(String username, Map<String, dynamic> data) async {
    final File? file = data['imageFile'];
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final request = ApiRequest(
      route: ApiRoutes.uploadImage,
      payload: {
        'username': username,
        'imageName': data['name'],
        'imageData': base64Image,
        'caption': data['caption'],
        'tags': data['tags'],
      },
    );

    try {
      await SocketClient().sendRequest(request);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
  }

  Future<void> addAlbum(String username, String name) async {
    final request = ApiRequest(
      route: ApiRoutes.createAlbum,
      payload: {
        'username': username,
        'albumName': name,
      },
    );

    try {
      await SocketClient().sendRequest(request);
    } catch (e) {
      debugPrint('Error creating album: $e');
    }
  }

  Future<void> toggleLike(int photoId) async {
    if (currentUsername == null) return;
    
    final request = ApiRequest(
      route: ApiRoutes.likeImage,
      payload: {
        'username': currentUsername!,
        'imageId': photoId,
      },
    );

    try {
      await SocketClient().sendRequest(request);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> addComment(int photoId, String username, String text) async {
    final request = ApiRequest(
      route: ApiRoutes.addComment,
      payload: {
        'username': username,
        'imageId': photoId,
        'text': text,
      },
    );

    try {
      await SocketClient().sendRequest(request);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> toggleBan(String username) async {
    final request = ApiRequest(
      route: ApiRoutes.toggleBan,
      payload: {
        'username': username,
      },
    );

    try {
      await SocketClient().sendRequest(request);
    } catch (e) {
      debugPrint('Error toggling ban: $e');
    }
  }

  Future<List<Map<String, dynamic>>> adminGetUsersList() async {
    final request = ApiRequest(
      route: ApiRoutes.adminUsersList,
      payload: {},
    );

    try {
      final response = await SocketClient().sendRequest(request);
      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
      }
    } catch (e) {
      debugPrint('Error getting admin users list: $e');
    }
    return [];
  }

  // Temporary stubs for remaining items (can be implemented as needed)
  List<FileItem> getVaultItems(String username) => [];
  Map<String, int> getUserStats(String username) => {'photos': 0, 'albums': 0};
  void deleteItem(int id) {}
  void movePhotos(List<int> photoIds, int? targetAlbumId) {}
  void updatePhoto(int id, String? caption, List<String>? tags) {}
  void deleteAccount(String username) {}

  void toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/server_config.dart';
import 'core/network/api_request.dart';
import 'core/network/api_response.dart';
import 'core/network/api_routes.dart';
import 'core/network/socket_client.dart';
import 'user_screens.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  String? currentUsername;
  bool isAdminLoggedIn = false;
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

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

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final response = await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.loginUser,
      payload: {'username': username, 'password': password},
    ));

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
    final response = await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.loginAdmin,
      payload: {'username': username, 'password': password},
    ));

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
    await SocketClient().disconnect();
  }

  Future<ApiResponse> registerUser({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    return await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.register,
      payload: {
        'username': username,
        'password': password,
        'email': (email != null && email.isNotEmpty) ? email : null,
        'phone': (phone != null && phone.isNotEmpty) ? phone : null,
      },
    ));
  }

  Future<bool> changeUsername(String oldName, String newName) async {
    final response = await SocketClient().sendRequest(ApiRequest(
      username: oldName,
      route: ApiRoutes.updateProfile,
      payload: {'username': newName},
    ));
    if (response.isSuccess) {
      currentUsername = newName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_session_user', newName);
      return true;
    }
    return false;
  }

  Future<List<FileItem>> getAllPhotos() async {
    try {
      final response = await SocketClient().sendRequest(ApiRequest(
        route: ApiRoutes.getAllImages,
        payload: {},
      ));
      if (response.isSuccess && response.data != null) {
        final List<dynamic> images = response.data['images'] ?? [];
        return images.map((img) => _mapToItem(img, img['owner'] ?? 'Unknown', null)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<FileItem>> getVaultItems(String username) async {
    try {
      final response = await SocketClient().sendRequest(ApiRequest(
        username: username,
        route: ApiRoutes.getUserVault,
        payload: {'username': username},
      ));
      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((i) => i['isFolder'] ? _mapToFolder(i) : _mapToItem(i, username, null)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<Map<String, int>> getUserStats(String username) async {
    // We can infer stats from getVaultItems or have a dedicated route
    final items = await getVaultItems(username);
    int photos = items.where((i) => !i.isFolder).length;
    int albums = items.where((i) => i.isFolder).length;
    return {'photos': photos, 'albums': albums};
  }

  Future<void> deleteItem(int id) async {
    await SocketClient().sendRequest(ApiRequest(
      username: currentUsername,
      route: ApiRoutes.deleteImage,
      payload: {'id': id},
    ));
  }

  Future<void> movePhotos(List<int> photoIds, int? targetAlbumId) async {
    // This requires a route like ApiRoutes.moveImages
    await SocketClient().sendRequest(ApiRequest(
      username: currentUsername,
      route: "albums/move-images",
      payload: {'photoIds': photoIds, 'targetAlbumId': targetAlbumId},
    ));
  }

  Future<void> addAlbum(String username, String name) async {
    await SocketClient().sendRequest(ApiRequest(
      username: username,
      route: ApiRoutes.createAlbum,
      payload: {'albumName': name, 'username': username},
    ));
  }

  Future<void> addImage(String username, Map<String, dynamic> data) async {
    final File? file = data['imageFile'];
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.uploadImage,
      payload: {
        'username': username,
        'imageName': data['name'],
        'imageData': base64Image,
        'caption': data['caption'],
        'tags': data['tags'],
      },
    ));
  }

  Future<void> updatePhoto(int id, String? caption, List<String>? tags) async {
    await SocketClient().sendRequest(ApiRequest(
      username: currentUsername,
      route: "images/update",
      payload: {'id': id, 'caption': caption, 'tags': tags},
    ));
  }

  Future<void> toggleLike(int photoId) async {
    await SocketClient().sendRequest(ApiRequest(
      username: currentUsername,
      route: ApiRoutes.likeImage,
      payload: {'imageId': photoId, 'username': currentUsername},
    ));
  }

  Future<void> addComment(int photoId, String username, String text) async {
    await SocketClient().sendRequest(ApiRequest(
      username: username,
      route: ApiRoutes.addComment,
      payload: {'imageId': photoId, 'text': text, 'username': username},
    ));
  }

  Future<void> deleteAccount(String username) async {
    final response = await SocketClient().sendRequest(ApiRequest(
      username: username,
      route: ApiRoutes.deleteAccount,
      payload: {},
    ));
    if (response.isSuccess) await logout();
  }

  Future<void> toggleBan(String username) async {
    await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.toggleBan,
      payload: {'username': username},
    ));
  }

  Future<List<Map<String, dynamic>>> adminGetUsersList() async {
    final response = await SocketClient().sendRequest(ApiRequest(
      route: ApiRoutes.adminUsersList,
      payload: {},
    ));
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
    }
    return [];
  }

  FileItem _mapToItem(Map<String, dynamic> img, String owner, int? parentId) {
    return FileItem(
      id: (img['id'] as num).toInt(),
      name: img['name'] ?? '',
      isFolder: false,
      ownerName: owner,
      parentId: parentId,
      caption: img['caption'],
      likes: (img['likes'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(img['date'] ?? '') ?? DateTime.now(),
      tags: img['tags'] != null ? List<String>.from(img['tags']) : [],
    );
  }

  FileItem _mapToFolder(Map<String, dynamic> folder) {
    return FileItem(
      id: (folder['id'] as num).toInt(),
      name: folder['name'] ?? '',
      isFolder: true,
      ownerName: folder['ownerName'] ?? '',
      date: DateTime.now(),
    );
  }

  Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }
}

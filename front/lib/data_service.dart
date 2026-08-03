import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_screens.dart';
import 'package:flutter/material.dart';


class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<dynamic> rawUsers = [];
  List<dynamic> rawAdmins = [];
  String? currentUsername;
  bool isAdminLoggedIn = false;

  // Theme Management
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  Future<void> init() async {
    try {
      // 1. Load the mock database
      final String response = await rootBundle.loadString(
        'assets/mock_data.json',
      );
      final data = json.decode(response);
      rawUsers = data['users'] ?? [];
      rawAdmins = data['admins'] ?? [];

      // 2. Load the persistent session and theme from device storage
      final prefs = await SharedPreferences.getInstance();

      // Load Theme
      final String? savedTheme = prefs.getString('theme_mode');
      if (savedTheme == 'dark') themeNotifier.value = ThemeMode.dark;
      if (savedTheme == 'light') themeNotifier.value = ThemeMode.light;

      final String? savedUser = prefs.getString('saved_session_user');

      if (savedUser != null) {
        if (savedUser == 'admin') {
          currentUsername = 'admin';
          isAdminLoggedIn = true;
        } else {
          // Verify user exists and is not banned
          final user = rawUsers.firstWhere(
            (u) => u['username'] == savedUser,
            orElse: () => null,
          );

          if (user != null && user['isBanned'] != true) {
            currentUsername = savedUser;
            isAdminLoggedIn = false;
          } else {
            // Clean up invalid session
            await prefs.remove('saved_session_user');
            currentUsername = null;
          }
        }
      }
    } catch (e) {
      rawUsers = [];
    }
  }

  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    try {
      final user = rawUsers.firstWhere(
        (u) =>
            u['username'].toString().toLowerCase() == username.toLowerCase() &&
            u['password'].toString() == password,
        orElse: () => null,
      );

      if (user == null) return null;
      if (user['isBanned'] == true) return {'error': 'BANNED'};

      currentUsername = user['username'];
      isAdminLoggedIn = false;

      // CRITICAL: Save to persistent storage and wait for it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_session_user', currentUsername!);

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<bool> loginAdmin(String username, String password) async {
    try {
      final admin = rawAdmins.firstWhere(
        (a) =>
            a['username'].toString().toLowerCase() == username.toLowerCase() &&
            a['password'].toString() == password,
        orElse: () => null,
      );

      if (admin == null) return false;

      currentUsername = 'admin';
      isAdminLoggedIn = true;

      // CRITICAL: Save to persistent storage and wait for it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_session_user', 'admin');

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    currentUsername = null;
    isAdminLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_session_user');
  }

  bool registerUser({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) {
    // Check if user already exists
    if (rawUsers.any((u) => u['username'].toString().toLowerCase() == username.toLowerCase())) {
      return false;
    }

    final newUser = {
      'username': username,
      'password': password,
      'email': email ?? "",
      'phoneNumber': phone ?? "",
      'isBanned': false,
      'albums': [],
      'standaloneImages': []
    };

    rawUsers.add(newUser);
    return true;
  }

  void deleteAccount(String username) {
    rawUsers.removeWhere((u) => u['username'] == username);
    if (currentUsername == username) logout();
  }

  bool changeUsername(String oldName, String newName) {
    if (rawUsers.any((u) => u['username'] == newName)) return false;
    final index = rawUsers.indexWhere((u) => u['username'] == oldName);
    if (index != -1) {
      rawUsers[index]['username'] = newName;
      if (currentUsername == oldName) {
        currentUsername = newName;
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString('saved_session_user', newName),
        );
      }
      return true;
    }
    return false;
  }

  void toggleBan(String username) {
    final index = rawUsers.indexWhere((u) => u['username'] == username);
    if (index != -1) {
      rawUsers[index]['isBanned'] = !rawUsers[index]['isBanned'];
      // If currently logged in user gets banned, clear their session
      if (rawUsers[index]['isBanned'] && currentUsername == username) {
        logout();
      }
    }
  }

  List<FileItem> getAllPhotos() {
    List<FileItem> photos = [];
    for (var user in rawUsers) {
      String owner = user['username'];
      for (var album in user['albums']) {
        for (var img in album['images']) {
          photos.add(_mapToItem(img, owner, album['id']));
        }
      }
      for (var img in user['standaloneImages']) {
        photos.add(_mapToItem(img, owner, null));
      }
    }
    return photos;
  }

  List<FileItem> getVaultItems(String username) {
    List<FileItem> items = [];
    final user = rawUsers.firstWhere(
      (u) => u['username'] == username,
      orElse: () => null,
    );
    if (user == null) return [];

    for (var album in user['albums']) {
      items.add(
        FileItem(
          id: album['id'],
          name: album['name'],
          isFolder: true,
          ownerName: username,
          date: DateTime.now(),
        ),
      );
      for (var img in album['images']) {
        items.add(_mapToItem(img, username, album['id']));
      }
    }
    for (var img in user['standaloneImages']) {
      items.add(_mapToItem(img, username, null));
    }
    return items;
  }

  Map<String, int> getUserStats(String username) {
    final user = rawUsers.firstWhere(
      (u) => u['username'] == username,
      orElse: () => null,
    );
    if (user == null) return {'photos': 0, 'albums': 0};
    int photoCount = (user['standaloneImages'] as List).length;
    for (var album in user['albums']) {
      photoCount += (album['images'] as List).length;
    }
    return {'photos': photoCount, 'albums': (user['albums'] as List).length};
  }

  void deleteItem(int id) {
    for (var user in rawUsers) {
      user['albums'].removeWhere((a) => a['id'] == id);
      for (var album in user['albums']) {
        album['images'].removeWhere((img) => img['id'] == id);
      }
      user['standaloneImages'].removeWhere((img) => img['id'] == id);
    }
  }

  void movePhotos(List<int> photoIds, int? targetAlbumId) {
    for (var user in rawUsers) {
      List<Map<String, dynamic>> allUserPhotos = [];
      for (var album in user['albums']) {
        var toMove = (album['images'] as List)
            .where((img) => photoIds.contains(img['id']))
            .toList();
        album['images'].removeWhere((img) => photoIds.contains(img['id']));
        for (var m in toMove) {
          allUserPhotos.add(m as Map<String, dynamic>);
        }
      }
      var standaloneToMove = (user['standaloneImages'] as List)
          .where((img) => photoIds.contains(img['id']))
          .toList();
      user['standaloneImages'].removeWhere(
        (img) => photoIds.contains(img['id']),
      );
      for (var m in standaloneToMove) {
        allUserPhotos.add(m as Map<String, dynamic>);
      }

      if (targetAlbumId == null) {
        user['standaloneImages'].addAll(allUserPhotos);
      } else {
        final albumIndex = user['albums'].indexWhere(
          (a) => a['id'] == targetAlbumId,
        );
        if (albumIndex != -1) {
          user['albums'][albumIndex]['images'].addAll(allUserPhotos);
        } else {
          user['standaloneImages'].addAll(allUserPhotos);
        }
      }
    }
  }

  void addAlbum(String username, String name) {
    final index = rawUsers.indexWhere((u) => u['username'] == username);
    if (index != -1) {
      rawUsers[index]['albums'].add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': name,
        'images': [],
      });
    }
  }

  void addImage(String username, Map<String, dynamic> data) {
    final index = rawUsers.indexWhere((u) => u['username'] == username);
    if (index == -1) return;
    final user = rawUsers[index];
    final newImg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': data['name'],
      'caption': data['caption'],
      'tags': data['tags'] ?? [],
      'likes': 0,
      'isLiked': false,
      'date': DateTime.now().toIso8601String(),
      'comments': [],
    };

    int? targetId = data['albumId'];
    if (targetId == null) {
      user['standaloneImages'].add(newImg);
    } else {
      final albumIndex = user['albums'].indexWhere((a) => a['id'] == targetId);
      if (albumIndex != -1) {
        user['albums'][albumIndex]['images'].add(newImg);
      } else {
        user['standaloneImages'].add(newImg);
      }
    }
  }

  void updatePhoto(int id, String? caption, List<String>? tags) {
    for (var user in rawUsers) {
      for (var album in user['albums']) {
        for (var img in album['images']) {
          if (img['id'] == id) {
            img['caption'] = caption;
            img['tags'] = tags ?? [];
            return;
          }
        }
      }
      for (var img in user['standaloneImages']) {
        if (img['id'] == id) {
          img['caption'] = caption;
          img['tags'] = tags ?? [];
          return;
        }
      }
    }
  }

  void toggleLike(int photoId) {
    for (var user in rawUsers) {
      for (var album in user['albums']) {
        for (var img in album['images']) {
          if (img['id'] == photoId) {
            img['isLiked'] = !(img['isLiked'] ?? false);
            img['likes'] += (img['isLiked'] ? 1 : -1);
            return;
          }
        }
      }
      for (var img in user['standaloneImages']) {
        if (img['id'] == photoId) {
          img['isLiked'] = !(img['isLiked'] ?? false);
          img['likes'] += (img['isLiked'] ? 1 : -1);
          return;
        }
      }
    }
  }

  void addComment(int photoId, String username, String text) {
    for (var user in rawUsers) {
      for (var album in user['albums']) {
        for (var img in album['images']) {
          if (img['id'] == photoId) {
            img['comments'].add({
              'username': username,
              'text': text,
              'likes': 0,
              'isLiked': false,
            });
            return;
          }
        }
      }
      for (var img in user['standaloneImages']) {
        if (img['id'] == photoId) {
          img['comments'].add({
            'username': username,
            'text': text,
            'likes': 0,
            'isLiked': false,
          });
          return;
        }
      }
    }
  }

  void toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }

  FileItem _mapToItem(Map<String, dynamic> img, String owner, int? parentId) {
    return FileItem(
      id: img['id'],
      name: img['name'],
      isFolder: false,
      ownerName: owner,
      parentId: parentId,
      caption: img['caption'],
      tags: List<String>.from(img['tags'] ?? []),
      likes: img['likes'] ?? 0,
      isLiked: img['isLiked'] ?? false,
      date: DateTime.parse(img['date']),
      comments: (img['comments'] as List? ?? [])
          .map(
            (c) => CommentData(
              username: c['username'],
              text: c['text'],
              likes: c['likes'] ?? 0,
              isLiked: c['isLiked'] ?? false,
            ),
          )
          .toList(),
    );
  }
}

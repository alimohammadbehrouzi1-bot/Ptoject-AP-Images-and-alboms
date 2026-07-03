import 'dart:convert';
import 'package:flutter/services.dart';
import 'user_screens.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<dynamic> rawUsers = [];
  List<dynamic> rawAdmins = [];
  String? currentUsername;
  bool isAdminLoggedIn = false;

  Future<void> init() async {
    final String response = await rootBundle.loadString('assets/mock_data.json');
    final data = json.decode(response);
    rawUsers = data['users'];
    rawAdmins = data['admins'];
  }

  Map<String, dynamic>? loginUser(String username, String password) {
    try {
      final user = rawUsers.firstWhere(
        (u) => u['username'] == username && u['password'] == password,
      );
      if (user['isBanned'] == true) return {'error': 'BANNED'};
      currentUsername = username;
      isAdminLoggedIn = false;
      return user;
    } catch (e) {
      return null;
    }
  }

  bool loginAdmin(String username, String password) {
    try {
      rawAdmins.firstWhere(
        (a) => a['username'] == username && a['password'] == password,
      );
      currentUsername = 'Admin';
      isAdminLoggedIn = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    currentUsername = null;
    isAdminLoggedIn = false;
  }

  void deleteAccount(String username) {
    rawUsers.removeWhere((u) => u['username'] == username);
    if (currentUsername == username) logout();
  }

  bool changeUsername(String oldName, String newName) {
    if (rawUsers.any((u) => u['username'] == newName)) return false;
    final user = rawUsers.firstWhere((u) => u['username'] == oldName, orElse: () => null);
    if (user != null) {
      user['username'] = newName;
      if (currentUsername == oldName) currentUsername = newName;
      return true;
    }
    return false;
  }

  void toggleBan(String username) {
    final index = rawUsers.indexWhere((u) => u['username'] == username);
    if (index != -1) {
      rawUsers[index]['isBanned'] = !rawUsers[index]['isBanned'];
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
    final user = rawUsers.firstWhere((u) => u['username'] == username, orElse: () => null);
    if (user == null) return [];
    
    for (var album in user['albums']) {
      items.add(FileItem(
        id: album['id'],
        name: album['name'],
        isFolder: true,
        ownerName: username,
        date: DateTime.now(),
      ));
      for (var img in album['images']) {
        items.add(_mapToItem(img, username, album['id']));
      }
    }
    for (var img in user['standaloneImages']) {
      items.add(_mapToItem(img, username, null));
    }
    return items;
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
        var toMove = (album['images'] as List).where((img) => photoIds.contains(img['id'])).toList();
        album['images'].removeWhere((img) => photoIds.contains(img['id']));
        for (var m in toMove) {
          allUserPhotos.add(m as Map<String, dynamic>);
        }
      }
      var standaloneToMove = (user['standaloneImages'] as List).where((img) => photoIds.contains(img['id'])).toList();
      user['standaloneImages'].removeWhere((img) => photoIds.contains(img['id']));
      for (var m in standaloneToMove) {
        allUserPhotos.add(m as Map<String, dynamic>);
      }

      if (targetAlbumId == null) {
        user['standaloneImages'].addAll(allUserPhotos);
      } else {
        final album = user['albums'].firstWhere((a) => a['id'] == targetAlbumId, orElse: () => null);
        if (album != null) {
          album['images'].addAll(allUserPhotos);
        } else {
           user['standaloneImages'].addAll(allUserPhotos);
        }
      }
    }
  }

  void addAlbum(String username, String name) {
    final user = rawUsers.firstWhere((u) => u['username'] == username);
    user['albums'].add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'images': []
    });
  }

  void addImage(String username, Map<String, dynamic> data) {
    final user = rawUsers.firstWhere((u) => u['username'] == username);
    final newImg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': data['name'],
      'caption': data['caption'],
      'tags': data['tags'] ?? [],
      'likes': 0,
      'isLiked': false,
      'date': DateTime.now().toIso8601String(),
      'comments': []
    };
    
    int? targetId = data['albumId'];
    if (targetId == null) {
      user['standaloneImages'].add(newImg);
    } else {
      final album = user['albums'].firstWhere((a) => a['id'] == targetId, orElse: () => null);
      if (album != null) {
        album['images'].add(newImg);
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
            img['comments'].add({'username': username, 'text': text, 'likes': 0, 'isLiked': false});
            return;
          }
        }
      }
      for (var img in user['standaloneImages']) {
        if (img['id'] == photoId) {
          img['comments'].add({'username': username, 'text': text, 'likes': 0, 'isLiked': false});
          return;
        }
      }
    }
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
      comments: (img['comments'] as List? ?? []).map((c) => CommentData(
        username: c['username'],
        text: c['text'],
        likes: c['likes'] ?? 0,
        isLiked: c['isLiked'] ?? false,
      )).toList(),
    );
  }
}

import 'dart:convert';
import 'dart:io';
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

  String? currentUsername;
  bool isAdminLoggedIn = false;

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

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
    } catch (e) {
      debugPrint('Error initializing DataService: $e');
    }
  }

  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.loginUser,
          payload: {'username': username, 'password': password},
        ),
      );

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
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.loginAdmin,
          payload: {'username': username, 'password': password},
        ),
      );

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
    try {
      currentUsername = null;
      isAdminLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_session_user');
      await SocketClient().disconnect();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<ApiResponse> registerUser({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.register,
          payload: {
            'username': username,
            'password': password,
            'email': (email != null && email.isNotEmpty) ? email : null,
            'phone': (phone != null && phone.isNotEmpty) ? phone : null,
          },
        ),
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.changePassword,
          payload: {
            'username': username,
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          },
        ),
      );
    } catch (e) {
      debugPrint('Change password error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> changeAdminPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.changeAdminPassword,
          payload: {
            'username': 'admin',
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          },
        ),
      );
    } catch (e) {
      debugPrint('Admin change password error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> updateProfile({
    required String oldUsername,
    required String newUsername,
    required String currentPassword,
  }) async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.updateProfile,
          payload: {
            'oldUsername': oldUsername,
            'newUsername': newUsername,
            'currentPassword': currentPassword,
          },
        ),
      );

      if (response.isSuccess) {
        currentUsername = newUsername;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_session_user', newUsername);
      }
      return response;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<List<FileItem>> getAllPhotos() async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.getAllImages,
          payload: {'viewerUsername': currentUsername},
        ),
      );
      if (response.isSuccess && response.data != null) {
        final List<dynamic> images = response.data['images'] ?? [];
        return images
            .map((img) => _mapToItem(img, img['ownerName'] ?? 'Unknown', null))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting photos in getAllPhotos: $e');
    }
    return [];
  }

  Future<List<FileItem>> getVaultItems(String username) async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.getUserVault,
          payload: {'username': username, 'viewerUsername': currentUsername},
        ),
      );
      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items
            .map(
              (i) => i['isFolder']
                  ? _mapToFolder(i)
                  : _mapToItem(i, username, (i['parentId'] as num?)?.toInt()),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting vault items in getVaultItems: $e');
    }
    return [];
  }

  Future<Map<String, int>> getUserStats(String username) async {
    try {
      final items = await getVaultItems(username);
      int photos = items.where((i) => !i.isFolder).length;
      int albums = items.where((i) => i.isFolder).length;
      return {'photos': photos, 'albums': albums};
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {'photos': 0, 'albums': 0};
    }
  }

  Future<ApiResponse> toggleCommentLike(int commentId) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.likeComment,
          payload: {'username': currentUsername, 'commentId': commentId},
        ),
      );
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> deleteComment(int commentId) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.deleteComment,
          payload: {'username': currentUsername, 'commentId': commentId},
        ),
      );
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> moveImages({
    required List<int> imageIds,
    int? sourceAlbumId,
    int? targetAlbumId,
  }) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    if (imageIds.isEmpty) return ApiResponse.error('No images selected');

    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.moveImages,
          payload: {
            'username': currentUsername,
            'imageIds': imageIds,
            'sourceAlbumId': sourceAlbumId,
            'targetAlbumId': targetAlbumId,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error moving images: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> addAlbum(String name) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    final trimmedName = name.trim();
    if (trimmedName.isEmpty)
      return ApiResponse.error('Album name cannot be empty');

    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.createAlbum,
          payload: {'albumName': trimmedName, 'username': currentUsername},
        ),
      );
    } catch (e) {
      debugPrint('Error creating album in addAlbum: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> renameAlbum({
    required int albumId,
    required String newName,
  }) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty)
      return ApiResponse.error('New name cannot be empty');

    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.renameAlbum,
          payload: {
            'username': currentUsername,
            'albumId': albumId,
            'newName': trimmedName,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error renaming album: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> deleteAlbum(int albumId) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.deleteAlbum,
          payload: {'username': currentUsername, 'albumId': albumId},
        ),
      );
    } catch (e) {
      debugPrint('Error deleting album: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> addImage(String username, Map<String, dynamic> data) async {
    try {
      final File? file = data['imageFile'];
      if (file == null) return ApiResponse.error('No image selected');
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.uploadImage,
          payload: {
            'username': username,
            'imageName': data['name'],
            'originalFileName': data['originalFileName'],
            'imageData': base64Image,
            'caption': data['caption'],
            'tags': data['tags'],
            'albumId': data['albumId'],
          },
        ),
      );
    } catch (e) {
      debugPrint('Error uploading image in addImage: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> updatePhoto({
    required int imageId,
    String? caption,
    List<String>? tags,
  }) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    try {
      debugPrint('Updating image tags: imageId=$imageId tags=$tags');
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.updateImage,
          payload: {
            'username': currentUsername,
            'imageId': imageId,
            'caption': caption,
            'tags': tags,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error updating photo in updatePhoto: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> deleteImage(int imageId) async {
    if (currentUsername == null) return ApiResponse.error('Not logged in');
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.deleteImage,
          payload: {'username': currentUsername, 'imageId': imageId},
        ),
      );
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> toggleLike(int photoId) async {
    try {
      return await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.likeImage,
          payload: {'imageId': photoId, 'username': currentUsername},
        ),
      );
    } catch (e) {
      debugPrint('Error toggling like in toggleLike: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<CommentData?> addComment(
    int photoId,
    String username,
    String text,
  ) async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.addComment,
          payload: {'imageId': photoId, 'text': text, 'username': username},
        ),
      );

      if (response.isSuccess && response.data != null) {
        final comment = response.data['comment'];
        return CommentData(
          id: (comment['id'] as num?)?.toInt() ?? 0,
          username: comment['username'] ?? 'Unknown',
          text: comment['text'] ?? '',
          date: DateTime.tryParse(comment['date'] ?? '') ?? DateTime.now(),
          likes: (comment['likes'] as num?)?.toInt() ?? 0,
          isLiked: comment['isLiked'] == true,
        );
      } else {
        debugPrint(
          'Add comment failed: ${response.statusCode} - ${response.message}',
        );
      }
    } catch (e) {
      debugPrint('Error adding comment in addComment: $e');
    }
    return null;
  }

  Future<void> deleteAccount(String username) async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(
          route: ApiRoutes.deleteAccount,
          payload: {'username': username},
        ),
      );
      if (response.isSuccess) await logout();
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }

  Future<void> toggleBan(String username) async {
    try {
      await SocketClient().sendRequest(
        ApiRequest(route: ApiRoutes.toggleBan, payload: {'username': username}),
      );
    } catch (e) {
      debugPrint('Error toggling ban: $e');
    }
  }

  Future<List<Map<String, dynamic>>> adminGetUsersList() async {
    try {
      final response = await SocketClient().sendRequest(
        ApiRequest(route: ApiRoutes.adminUsersList, payload: {}),
      );
      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
      }
    } catch (e) {
      debugPrint('Error getting admin users list: $e');
    }
    return [];
  }

  FileItem _mapToItem(Map<String, dynamic> img, String owner, int? parentId) {
    final String? encodedImage = img['imageData'] as String?;
    final List<dynamic> rawComments = img['comments'] ?? [];

    return FileItem(
      id: (img['id'] as num).toInt(),
      name: img['name'] ?? '',
      isFolder: false,
      ownerName: owner,
      parentId: parentId,
      caption: img['caption'],
      likes: (img['likes'] as num?)?.toInt() ?? 0,
      isLiked: img['isLiked'] == true,
      date: DateTime.tryParse(img['date'] ?? '') ?? DateTime.now(),
      tags: img['tags'] != null ? List<String>.from(img['tags']) : [],
      comments: rawComments.map((comment) {
        return CommentData(
          id: (comment['id'] as num?)?.toInt() ?? 0,
          username: comment['username'] ?? 'Unknown',
          text: comment['text'] ?? '',
          date: DateTime.tryParse(comment['date'] ?? '') ?? DateTime.now(),
          likes: (comment['likes'] as num?)?.toInt() ?? 0,
          isLiked: comment['isLiked'] == true,
        );
      }).toList(),
      imageBytes: encodedImage == null || encodedImage.isEmpty
          ? null
          : base64Decode(encodedImage),
    );
  }

  FileItem _mapToFolder(Map<String, dynamic> folder) {
    return FileItem(
      id: (folder['id'] as num).toInt(),
      name: folder['name'] ?? '',
      isFolder: true,
      ownerName: folder['owner'] ?? '',
      date: DateTime.now(),
    );
  }

  Future<void> toggleTheme(bool isDark) async {
    try {
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }
}

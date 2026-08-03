class AppUser {
  String username;
  String? email;
  String? phoneNumber;
  bool isBanned;
  List<AlbumModel> albums;

  AppUser({
    required this.username,
    this.email,
    this.phoneNumber,
    this.isBanned = false,
    this.albums = const [],
  });
}

class ImageModel {
  final int id;
  final String name;
  final String path;
  final String ownerUsername;
  final String? caption;
  final List<String> tags;
  final List<CommentModel> comments;
  int likes;
  bool isLiked;

  ImageModel({
    required this.id,
    required this.name,
    required this.path,
    required this.ownerUsername,
    this.caption,
    this.tags = const [],
    this.comments = const [],
    this.likes = 0,
    this.isLiked = false,
  });
}

class AlbumModel {
  final int id;
  final String name;
  final List<ImageModel> images;

  AlbumModel({required this.id, required this.name, this.images = const []});
}

class CommentModel {
  final String ownerUsername;
  final String text;
  final DateTime date;

  CommentModel({
    required this.ownerUsername,
    required this.text,
    required this.date,
  });
}

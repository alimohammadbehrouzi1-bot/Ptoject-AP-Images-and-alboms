/// This file contains all the routes used for communicating with the Backend.
/// These routes are synchronized with the Java Backend implementation.
abstract final class ApiRoutes {
  static const loginUser = 'auth/login';
  static const loginAdmin = 'admin/login';
  static const register = 'auth/register';
  static const logout = 'auth/logout';

  static const getAllImages = 'image/get-all';
  static const uploadImage = 'image/upload';
  
  static const createAlbum = 'album/create';

  static const likeImage = 'interaction/like';
  static const addComment = 'interaction/comment';

  static const adminUsersList = 'admin/users-list';
  static const toggleBan = 'admin/toggle-ban';
}

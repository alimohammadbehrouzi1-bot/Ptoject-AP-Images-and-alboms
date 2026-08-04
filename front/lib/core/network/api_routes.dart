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
  static const getAllUsers = 'admin/users-list';
  static const toggleBan = 'admin/toggle-ban';
  
  // Routes not yet implemented in backend
  static const getFeed = 'images/feed';
  static const getUserVault = 'images/user-vault';
  static const updateImage = 'images/update';
  static const deleteImage = 'images/delete';
  static const likeComment = 'comments/like';
  static const deleteAlbum = 'albums/delete';
  static const moveImages = 'albums/move-images';
  static const searchUser = 'users/search';
  static const updateProfile = 'users/update';
  static const deleteAccount = 'users/delete';
  static const changePassword = 'users/change-password';
  static const getBannedUsers = 'admin/banned-users';
  static const changeAdminPassword = 'admin/change-password';
}

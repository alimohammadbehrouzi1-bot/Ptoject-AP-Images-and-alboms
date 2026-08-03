/// This file contains all the routes used for communicating with the Backend.
/// Note: These routes are based on initial assumptions and should be synchronized
/// with the actual Backend implementation.
abstract final class ApiRoutes {
  static const loginUser = 'auth/login';
  static const loginAdmin = 'admin/login';
  static const register = 'auth/register';
  static const logout = 'auth/logout';

  static const getFeed = 'images/feed';
  static const getUserVault = 'images/user-vault';
  static const uploadImage = 'images/upload';
  static const updateImage = 'images/update';
  static const deleteImage = 'images/delete';
  static const likeImage = 'images/like';

  static const addComment = 'comments/add';
  static const likeComment = 'comments/like';

  static const createAlbum = 'albums/create';
  static const deleteAlbum = 'albums/delete';
  static const moveImages = 'albums/move-images';

  static const searchUser = 'users/search';
  static const updateProfile = 'users/update';
  static const deleteAccount = 'users/delete';
  static const changePassword = 'users/change-password';

  static const getAllUsers = 'admin/users';
  static const getBannedUsers = 'admin/banned-users';
  static const toggleBan = 'admin/toggle-ban';
  static const changeAdminPassword = 'admin/change-password';
}

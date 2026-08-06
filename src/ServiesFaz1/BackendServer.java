package ServiesFaz1;

import com.google.gson.Gson;
import Faz1.User;
import Faz1.Admin;
import Faz1.Image;
import Faz1.Album;
import Faz1.Comment;
import java.io.*;
import java.lang.reflect.Field;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class BackendServer {
    private static final int PORT = 8081;

    public void start() {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Server started on port " + PORT);
            while (true) {
                Socket clientSocket = serverSocket.accept();
                new Thread(new ClientHandler(clientSocket)).start();
            }
        } catch (IOException e) {
            System.err.println("Server error: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        DatabaseManager.load();
        new BackendServer().start();
    }
}

class ClientHandler implements Runnable {
    private final Socket socket;
    private final Gson gson = new Gson();

    public ClientHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        try (
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true)
        ) {
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                try {
                    Request request = gson.fromJson(inputLine, Request.class);
                    Response response = handleRouting(request);
                    out.println(gson.toJson(response));
                    out.flush();
                } catch (Exception e) {
                    Response errorResponse = new Response(null, 500, "Internal Server Error: " + e.getMessage(), null);
                    out.println(gson.toJson(errorResponse));
                    out.flush();
                }
            }
        } catch (IOException e) {
            System.err.println("Handler error: " + e.getMessage());
        } finally {
            try {
                if (!socket.isClosed()) {
                    socket.close();
                }
            } catch (IOException e) {
                System.err.println("Socket close error: " + e.getMessage());
            }
        }
    }

    private Response handleRouting(Request request) {
        String route = request.getRoute();
        switch (route) {
            case "auth/login": return handleLogin(request);
            case "auth/register": return handleRegister(request);
            case "admin/login": return handleAdminLogin(request);
            case "image/upload": return handleImageUpload(request);
            case "image/get-all": return handleImageGetAll(request);
            case "album/create": return handleAlbumCreate(request);
            case "albums/move-images": return handleMoveImages(request);
            case "interaction/like": return handleInteractionLike(request);
            case "interaction/comment": return handleInteractionComment(request);
            case "comments/like": return handleCommentLike(request);
            case "comments/delete": return handleCommentDelete(request);
            case "admin/users-list": return handleAdminUsersList(request);
            case "admin/toggle-ban": return handleAdminToggleBan(request);
            case "images/user-vault": return handleImageGetUserVault(request);
            case "images/update": return handleImageUpdate(request);
            case "images/delete": return handleImageDelete(request);
            case "users/change-password": return handleUserChangePassword(request);
            case "users/update": return handleUserUpdate(request);
            case "users/delete": return handleDeleteAccount(request);
            default: return new Response(request.getRequestId(), 404, "Route Not Found", null);
        }
    }

    private Response handleLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        User user = findUser(username);

        if (user != null) {
            if (user.isBanned()) {
                return new Response(request.getRequestId(), 403, "Forbidden: User is Banned", null);
            }
            if (user.passwordMatches(password)) {
                user.logIn(username, password);
                return new Response(request.getRequestId(), 200, "Login Success", new HashMap<>());
            }
        }
        return new Response(request.getRequestId(), 401, "Unauthorized: Invalid credentials", null);
    }

    private Response handleAdminLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        try {
            Admin.Login(username, password);
            return new Response(request.getRequestId(), 200, "Admin Login Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 401, "Unauthorized: Invalid admin credentials", null);
        }
    }

    private Response handleRegister(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");
        String email = (String) request.getPayload().get("email");
        Object phoneRaw = request.getPayload().get("phone");
        Long phone = (phoneRaw != null) ? Long.parseLong(phoneRaw.toString()) : null;

        try {
            if (email != null && !email.isEmpty() && phone != null) new User(username, password, email, phone);
            else if (email != null && !email.isEmpty()) new User(username, password, email);
            else if (phone != null) new User(username, password, phone);
            else new User(username, password);

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Registration Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 400, "Registration Failed: " + e.getMessage(), null);
        }
    }

    private Response handleImageUpload(Request request) {
        String username = (String) request.getPayload().get("username");
        String imageName = (String) request.getPayload().get("imageName");
        String originalFileName = (String) request.getPayload().get("originalFileName");
        String imageData = (String) request.getPayload().get("imageData"); // Base64
        String caption = (String) request.getPayload().get("caption");
        List<String> tagsList = (List<String>) request.getPayload().get("tags");
        Object albumIdRaw = request.getPayload().get("albumId");
        Long albumId = (albumIdRaw != null) ? ((Double) albumIdRaw).longValue() : null;
        Set<String> tags = new HashSet<>(tagsList != null ? tagsList : new ArrayList<>());

        User user = findUserAndEnsureLoggedIn(username);

        if (user == null) {
            return new Response(request.getRequestId(), 404, "User Not Found", null);
        }

        try {
            String extension = "";
            int i = originalFileName.lastIndexOf('.');
            if (i > 0) {
                extension = originalFileName.substring(i + 1).toLowerCase();
            }

            List<String> allowedExtensions = Arrays.asList("jpg", "jpeg", "png", "webp", "gif");
            if (!allowedExtensions.contains(extension)) {
                return new Response(request.getRequestId(), 400, "Invalid File Extension", null);
            }

            File dir = new File("storage/images");
            if (!dir.exists()) dir.mkdirs();

            String uniqueName = UUID.randomUUID().toString() + "." + extension;
            String filePath = "storage/images/" + uniqueName;
            byte[] imageBytes = Base64.getDecoder().decode(imageData);
            Files.write(Paths.get(filePath), imageBytes);

            user.uploadImage(imageName, filePath, caption, tags);
            
            // Find the newly created image to add it to album
            Image newImage = user.getImages().get(user.getImages().size() - 1);
            
            if (albumId != null) {
                Album targetAlbum = user.getAlbums().stream()
                    .filter(a -> a.getId() == albumId)
                    .findFirst()
                    .orElse(null);
                if (targetAlbum != null) {
                    targetAlbum.addImageToAlbum(newImage);
                }
            }

            DatabaseManager.save();

            return new Response(request.getRequestId(), 200, "Image Uploaded Successfully", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Upload Failed: " + e.getMessage(), null);
        }
    }

    private Response handleImageGetAll(Request request) {
        try {
            String viewerUsername = (String) request.getPayload().get("viewerUsername");
            User viewer = viewerUsername != null ? findUser(viewerUsername) : null;

            List<Map<String, Object>> imageList = new ArrayList<>();
            for (User user : Admin.allUsers) {
                for (Image img : user.getImages()) {
                    imageList.add(_imageToMap(img, user.getUsername(), viewer));
                }
            }
            Map<String, Object> data = new HashMap<>();
            data.put("images", imageList);
            return new Response(request.getRequestId(), 200, "Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleImageGetUserVault(Request request) {
        String username = (String) request.getPayload().get("username");
        String viewerUsername = (String) request.getPayload().get("viewerUsername");

        User user = findUser(username);
        User viewer = findUser(viewerUsername);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        try {
            List<Map<String, Object>> items = new ArrayList<>();

            // Map Albums
            for (Album alb : user.getAlbums()) {
                Map<String, Object> aMap = new HashMap<>();
                aMap.put("id", alb.getId());
                aMap.put("name", alb.getName());
                aMap.put("owner", username);
                aMap.put("isFolder", true);
                items.add(aMap);
            }

            // Map Images
            for (Image img : user.getImages()) {
                Map<String, Object> iMap = _imageToMap(img, username, viewer);
                iMap.put("isFolder", false);
                
                // Find parent album id
                Long parentId = null;
                for (Album a : user.getAlbums()) {
                    if (a.getImages().contains(img)) {
                        parentId = a.getId();
                        break;
                    }
                }
                iMap.put("parentId", parentId);
                items.add(iMap);
            }

            Map<String, Object> data = new HashMap<>();
            data.put("items", items);
            return new Response(request.getRequestId(), 200, "Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleAlbumCreate(Request request) {
        String username = (String) request.getPayload().get("username");
        String albumName = (String) request.getPayload().get("albumName");

        User user = findUserAndEnsureLoggedIn(username);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        try {
            user.makeNewAlbum(albumName);
            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Album Created Successfully", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleInteractionLike(Request request) {
        String username = (String) request.getPayload().get("username");
        Object rawId = request.getPayload().get("imageId");
        if (rawId == null) return new Response(request.getRequestId(), 400, "Missing imageId", null);
        long imageId = ((Number) rawId).longValue();

        User user = findUserAndEnsureLoggedIn(username);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image targetImage = findImage(imageId);

        if (targetImage == null) return new Response(request.getRequestId(), 404, "Image Not Found", null);

        try {
            user.addOrRemoveLikeImage(targetImage);
            DatabaseManager.save();
            
            Map<String, Object> data = new HashMap<>();
            data.put("likes", targetImage.getLikeCount());
            data.put("isLiked", targetImage.isLikedBy(user));
            
            return new Response(request.getRequestId(), 200, "Like Interaction Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleInteractionComment(Request request) {
        String username = (String) request.getPayload().get("username");
        Object imageIdRaw = request.getPayload().get("imageId");
        String text = (String) request.getPayload().get("text");

        if (username == null || imageIdRaw == null || text == null) {
            return new Response(request.getRequestId(), 400, "Missing required fields", null);
        }

        text = text.trim();
        if (text.isEmpty()) {
            return new Response(request.getRequestId(), 400, "Comment cannot be empty", null);
        }
        if (text.length() > 1000) {
            return new Response(request.getRequestId(), 400, "Comment too long (max 1000 chars)", null);
        }

        long imageId = ((Number) imageIdRaw).longValue();

        User user = findUserAndEnsureLoggedIn(username);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image targetImage = findImage(imageId);

        if (targetImage == null) return new Response(request.getRequestId(), 404, "Image Not Found", null);

        try {
            Comment createdComment = user.writeComment(targetImage, text);
            DatabaseManager.save();

            Map<String, Object> commentData = new HashMap<>();
            commentData.put("id", createdComment.getId());
            commentData.put("username", createdComment.getOwnerUsername());
            commentData.put("text", createdComment.getComment());
            commentData.put("date", createdComment.getDate().toString());
            commentData.put("likes", createdComment.getLikes());
            commentData.put("isLiked", false);

            Map<String, Object> data = new HashMap<>();
            data.put("comment", commentData);

            return new Response(request.getRequestId(), 200, "Comment Added Successfully", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleCommentLike(Request request) {
        String username = (String) request.getPayload().get("username");
        Object rawCid = request.getPayload().get("commentId");
        if (username == null || rawCid == null) return new Response(request.getRequestId(), 400, "Missing fields", null);
        long commentId = ((Number) rawCid).longValue();

        User user = findUserAndEnsureLoggedIn(username);
        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Comment target = findCommentGlobally(commentId);
        if (target == null) return new Response(request.getRequestId(), 404, "Comment Not Found", null);

        try {
            user.addOrRemoveLikeComment(target);
            DatabaseManager.save();
            
            Map<String, Object> data = new HashMap<>();
            Map<String, Object> cData = new HashMap<>();
            cData.put("id", target.getId());
            cData.put("likes", target.getLikes());
            cData.put("isLiked", target.isLikedBy(user));
            data.put("comment", cData);
            return new Response(request.getRequestId(), 200, "Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, e.getMessage(), null);
        }
    }

    private Response handleCommentDelete(Request request) {
        String username = (String) request.getPayload().get("username");
        Object rawCid = request.getPayload().get("commentId");
        if (username == null || rawCid == null) return new Response(request.getRequestId(), 400, "Missing fields", null);
        long commentId = ((Number) rawCid).longValue();

        User user = findUserAndEnsureLoggedIn(username);
        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Comment targetComment = findCommentGlobally(commentId);
        if (targetComment == null) return new Response(request.getRequestId(), 404, "Comment Not Found", null);

        try {
            User commentOwner = getPrivateField(targetComment, "owner");
            if (!commentOwner.equals(user)) {
                return new Response(request.getRequestId(), 403, "Forbidden: Only author can delete", null);
            }

            Image targetImage = null;
            outer: for (User u : Admin.allUsers) {
                for (Image img : u.getImages()) {
                    if (img.getComments().contains(targetComment)) {
                        targetImage = img;
                        break outer;
                    }
                }
            }

            if (targetImage != null) {
                targetImage.getComments().remove(targetComment);
            }

            Set<Comment> ownerComments = getPrivateField(commentOwner, "yourComments");
            ownerComments.remove(targetComment);

            for (User u : Admin.allUsers) {
                u.getLikedComment().remove(targetComment);
            }

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Comment Deleted", Map.of("deletedCommentId", commentId));
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, e.getMessage(), null);
        }
    }

    private Response handleAdminUsersList(Request request) {
        try {
            List<Map<String, Object>> userList = new ArrayList<>();
            for (User u : Admin.allUsers) {
                Map<String, Object> uMap = new HashMap<>();
                uMap.put("username", u.getUsername());
                uMap.put("isBanned", u.isBanned());
                uMap.put("photoCount", u.getImages().size());
                uMap.put("albumCount", u.getAlbums().size());
                userList.add(uMap);
            }
            Map<String, Object> data = new HashMap<>();
            data.put("users", userList);
            return new Response(request.getRequestId(), 200, "Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleAdminToggleBan(Request request) {
        String targetUsername = (String) request.getPayload().get("username");

        User user = findUser(targetUsername);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        try {
            user.setBanned(!user.isBanned());
            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "User Ban Status Toggled", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleUserChangePassword(Request request) {
        String username = (String) request.getPayload().get("username");
        String oldPassword = (String) request.getPayload().get("oldPassword");
        String newPassword = (String) request.getPayload().get("newPassword");

        User user = findUserAndEnsureLoggedIn(username);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        if (!user.passwordMatches(oldPassword)) {
            return new Response(request.getRequestId(), 401, "Invalid Old Password", null);
        }

        try {
            user.setPassword(newPassword);
            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Password Changed Successfully", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 400, e.getMessage(), null);
        }
    }

    private Response handleUserUpdate(Request request) {
        String oldUsername = (String) request.getPayload().get("oldUsername");
        String newUsername = (String) request.getPayload().get("newUsername");
        String currentPassword = (String) request.getPayload().get("currentPassword");

        User user = findUserAndEnsureLoggedIn(oldUsername);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        if (!user.passwordMatches(currentPassword)) {
            return new Response(request.getRequestId(), 401, "Invalid Password", null);
        }

        if (newUsername == null || newUsername.trim().isEmpty()) {
            return new Response(request.getRequestId(), 400, "New Username cannot be empty", null);
        }

        if (!oldUsername.equals(newUsername) && Admin.allUsers.stream().anyMatch(u -> u.getUsername().equals(newUsername))) {
            return new Response(request.getRequestId(), 400, "Username already in use", null);
        }

        try {
            List<Set<User>> userSets = new ArrayList<>();
            userSets.add(Admin.allUsers);

            for (User u : Admin.allUsers) {
                for (Image img : u.getImages()) {
                    userSets.add(getPrivateField(img, "usersWhoLiked"));
                    userSets.add(getPrivateField(img, "userWhoComment"));
                    for (Comment c : img.getComments()) {
                        userSets.add(getPrivateField(c, "usersWhoLiked"));
                    }
                }
            }

            List<Set<User>> setsContainingUser = new ArrayList<>();
            for (Set<User> set : userSets) {
                if (set.remove(user)) {
                    setsContainingUser.add(set);
                }
            }

            user.updateUsername(newUsername);

            for (Set<User> set : setsContainingUser) {
                set.add(user);
            }

            DatabaseManager.save();
            Map<String, Object> data = new HashMap<>();
            data.put("username", newUsername);
            return new Response(request.getRequestId(), 200, "Username Updated Successfully", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleImageUpdate(Request request) {
        String username = (String) request.getPayload().get("username");
        Object rawImageId = request.getPayload().get("imageId");
        if (username == null || username.isEmpty() || rawImageId == null) {
            return new Response(request.getRequestId(), 400, "Invalid Request", null);
        }

        long imageId = ((Number) rawImageId).longValue();
        String caption = (String) request.getPayload().get("caption");
        Object rawTags = request.getPayload().get("tags");

        User user = findUserAndEnsureLoggedIn(username);
        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image img = findImage(imageId);
        if (img == null) return new Response(request.getRequestId(), 404, "Image Not Found", null);

        try {
            User imageOwner = getPrivateField(img, "owner");
            if (!imageOwner.equals(user)) {
                return new Response(request.getRequestId(), 403, "Forbidden", null);
            }

            if (caption != null) img.addOrEditCaption(caption);

            if (rawTags != null && rawTags instanceof List<?>) {
                List<String> parsedTags = new ArrayList<>();
                for (Object value : (List<?>) rawTags) {
                    if (value != null) parsedTags.add(value.toString());
                }
                img.addOrEditTags(new LinkedHashSet<>(parsedTags));
            }

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Image Updated", null);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleImageDelete(Request request) {
        String username = (String) request.getPayload().get("username");
        Object rawImageId = request.getPayload().get("imageId");
        if (username == null || username.isEmpty() || rawImageId == null) {
            return new Response(request.getRequestId(), 400, "Invalid Request", null);
        }

        long imageId = ((Number) rawImageId).longValue();
        User user = findUserAndEnsureLoggedIn(username);
        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image img = findImage(imageId);
        if (img == null) return new Response(request.getRequestId(), 404, "Image Not Found", null);

        try {
            User imageOwner = getPrivateField(img, "owner");
            if (!imageOwner.equals(user)) {
                return new Response(request.getRequestId(), 403, "Forbidden", null);
            }

            for (User u : Admin.allUsers) {
                for (Album a : u.getAlbums()) {
                    a.removeImageFromAlbumViaImage(img);
                }
            }

            for (User u : Admin.allUsers) {
                u.getLikedImages().remove(img);
            }

            List<Comment> imageComments = new ArrayList<>(img.getComments());
            for (Comment c : imageComments) {
                User cOwner = getPrivateField(c, "owner");
                Set<Comment> ownerYourComments = getPrivateField(cOwner, "yourComments");
                ownerYourComments.remove(c);

                for (User u : Admin.allUsers) {
                    u.getLikedComment().remove(c);
                }
            }
            img.getComments().clear();

            user.getImages().remove(img);

            Files.deleteIfExists(Paths.get(img.getPath()));

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Deleted Successfully", null);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }

    private Response handleMoveImages(Request request) {
        String username = (String) request.getPayload().get("username");
        List<?> rawIds = (List<?>) request.getPayload().get("imageIds");
        Object targetAlbumIdRaw = request.getPayload().get("targetAlbumId");
        Long targetAlbumId = (targetAlbumIdRaw != null) ? ((Number) targetAlbumIdRaw).longValue() : null;

        User user = findUserAndEnsureLoggedIn(username);
        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        try {
            List<Image> imagesToMove = new ArrayList<>();
            if (rawIds != null) {
                for (Object rawId : rawIds) {
                    long id = ((Number) rawId).longValue();
                    Image img = user.getImages().stream().filter(i -> i.getId() == id).findFirst().orElse(null);
                    if (img != null) imagesToMove.add(img);
                }
            }

            if (imagesToMove.isEmpty()) {
                return new Response(request.getRequestId(), 400, "No valid images found to move", null);
            }

            Image[] imagesArray = imagesToMove.toArray(new Image[0]);

            if (targetAlbumId == null) {
                for (Image img : imagesArray) {
                    for (Album a : new ArrayList<>(user.getAlbums())) {
                        a.removeImageFromAlbumViaImage(img);
                    }
                }
            } else {
                Album dest = user.getAlbums().stream().filter(a -> a.getId() == targetAlbumId).findFirst().orElse(null);
                if (dest == null) return new Response(request.getRequestId(), 404, "Target Album Not Found", null);

                for (Image img : imagesArray) {
                    boolean foundInAny = false;
                    for (Album source : new ArrayList<>(user.getAlbums())) {
                        if (source.getImages().contains(img)) {
                            source.moveImagesToAnotherAlbum(dest, img);
                            foundInAny = true;
                        }
                    }
                    if (!foundInAny) {
                        dest.addImageToAlbum(img);
                    }
                }
            }

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Images moved successfully", null);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Move failed: " + e.getMessage(), null);
        }
    }

    private Response handleDeleteAccount(Request request) {
        String username = (String) request.getPayload().get("username");
        if (username == null || username.isEmpty()) {
            return new Response(request.getRequestId(), 400, "Bad Request: username missing", null);
        }

        User user = findUser(username);
        if (user == null) {
            return new Response(request.getRequestId(), 404, "User not found", null);
        }

        try {
            // 1. Ensure user is logged in to perform Phase 1 deletions
            setPrivateField(user, "isLogged", true);

            // 2. Clean up physical image files and references in other users' data
            List<Image> ownedImages = new ArrayList<>(user.getImages());
            for (Image img : ownedImages) {
                // Remove physical file
                Files.deleteIfExists(Paths.get(img.getPath()));
                
                // Remove from everyone's likedImages
                for (User u : Admin.allUsers) {
                    u.getLikedImages().remove(img);
                }

                // Remove from ALL albums in the system (not just owner's)
                for (User u : Admin.allUsers) {
                    for (Album a : u.getAlbums()) {
                        a.removeImageFromAlbumViaImage(img);
                    }
                }
            }
            // Clear owner's image list (Phase 1)
            user.getImages().clear();

            // 3. Clean up Albums
            user.getAlbums().clear();

            // 4. Clean up Comments and Likes on comments
            for (User u : Admin.allUsers) {
                for (Image img : u.getImages()) {
                    img.getComments().removeIf(c -> c.getOwnerUsername().equals(username));
                }
                u.getLikedComment().removeIf(c -> c.getOwnerUsername().equals(username));
            }

            // 5. Remove user's likes from other images/comments
            for (User u : Admin.allUsers) {
                for (Image img : u.getImages()) {
                    // Accessing private usersWhoLiked set via reflection to remove this user
                    Set<User> imageLikes = getPrivateField(img, "usersWhoLiked");
                    imageLikes.remove(user);
                }
            }

            // 6. Remove the user from the global system set
            if (Admin.allUsers.remove(user)) {
                // Invalidate session state
                try {
                    user.logOut();
                } catch (Exception ignored) {}

                // Persist the change to database.json
                DatabaseManager.save();
                return new Response(request.getRequestId(), 200, "Account deleted successfully", null);
            } else {
                return new Response(request.getRequestId(), 500, "Internal error: user removal failed", null);
            }
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error during deletion: " + e.getMessage(), null);
        }
    }

    private User findUser(String username) {
        if (username == null) return null;
        for (User u : Admin.allUsers) {
            if (u.getUsername().equals(username)) return u;
        }
        return null;
    }

    private User findUserAndEnsureLoggedIn(String username) {
        User u = findUser(username);
        if (u != null) {
            try {
                setPrivateField(u, "isLogged", true);
            } catch (Exception ignored) {}
        }
        return u;
    }

    private Image findImage(long id) {
        for (User u : Admin.allUsers) {
            for (Image img : u.getImages()) {
                if (img.getId() == id) return img;
            }
        }
        return null;
    }

    private Comment findCommentGlobally(long commentId) {
        for (User u : Admin.allUsers) {
            for (Image img : u.getImages()) {
                for (Comment c : img.getComments()) {
                    if (c.getId() == commentId) return c;
                }
            }
        }
        return null;
    }

    private List<Map<String, Object>> mapComments(Image image, User viewer) {
        List<Map<String, Object>> commentList = new ArrayList<>();
        for (Comment c : image.getComments()) {
            Map<String, Object> cMap = new HashMap<>();
            cMap.put("id", c.getId());
            cMap.put("username", c.getOwnerUsername());
            cMap.put("text", c.getComment());
            cMap.put("date", c.getDate().toString());
            cMap.put("likes", c.getLikes());
            cMap.put("isLiked", c.isLikedBy(viewer));
            commentList.add(cMap);
        }
        return commentList;
    }

    private Map<String, Object> _imageToMap(Image img, String owner, User viewer) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", img.getId());
        map.put("name", img.getName());
        map.put("ownerName", owner);
        map.put("caption", img.getCaption());
        map.put("likes", img.getLikeCount());
        map.put("isLiked", img.isLikedBy(viewer));
        map.put("date", img.getDate().toString());
        map.put("tags", new ArrayList<>(img.getTags()));
        
        String path = img.getPath();
        String base64Image = null;
        if (path != null) {
            try {
                File file = new File(path);
                if (file.exists()) {
                    byte[] fileContent = Files.readAllBytes(file.toPath());
                    base64Image = Base64.getEncoder().encodeToString(fileContent);
                }
            } catch (IOException e) {
                System.err.println("Error reading image file: " + path + " - " + e.getMessage());
            }
        }
        map.put("imageData", base64Image);

        map.put("comments", mapComments(img, viewer));
        return map;
    }

    private static void setPrivateField(Object obj, String fieldName, Object value) throws Exception {
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
    }

    private <T> T getPrivateField(Object obj, String fieldName) throws Exception {
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        return (T) field.get(obj);
    }
}

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
    private static final int PORT = 8080;

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
    private static final Map<String, String> routes = new HashMap<>();

    static {
        routes.put("auth/login", "auth");
        routes.put("auth/register", "auth");
        routes.put("admin/login", "admin");
        routes.put("album/create", "album");
        routes.put("interaction/like", "interaction");
        routes.put("interaction/comment", "interaction");
        routes.put("admin/users-list", "admin");
        routes.put("admin/toggle-ban", "admin");
        routes.put("images/user-vault", "images");
        routes.put("users/change-password", "users");
        routes.put("users/update", "users");
    }

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
                } catch (Exception e) {
                    Response errorResponse = new Response(null, 500, "Internal Server Error: " + e.getMessage(), null);
                    out.println(gson.toJson(errorResponse));
                }
            }
        } catch (IOException e) {
            System.err.println("Handler error: " + e.getMessage());
        } finally {
            try {
                socket.close();
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
            case "interaction/like": return handleInteractionLike(request);
            case "interaction/comment": return handleInteractionComment(request);
            case "admin/users-list": return handleAdminUsersList(request);
            case "admin/toggle-ban": return handleAdminToggleBan(request);
            case "images/user-vault": return handleImageGetUserVault(request);
            case "users/change-password": return handleUserChangePassword(request);
            case "users/update": return handleUserUpdate(request);
            default: return new Response(request.getRequestId(), 404, "Route Not Found", null);
        }
    }

    private Response handleLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

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
            User viewer = viewerUsername != null ? Admin.allUsers.stream()
                    .filter(u -> u.getUsername().equals(viewerUsername))
                    .findFirst()
                    .orElse(null) : null;

            List<Map<String, Object>> imageList = new ArrayList<>();
            for (User user : Admin.allUsers) {
                for (Image img : user.getImages()) {
                    Map<String, Object> imgMap = new HashMap<>();
                    imgMap.put("id", img.getId());
                    imgMap.put("name", img.getName());
                    imgMap.put("owner", user.getUsername());
                    imgMap.put("caption", img.getCaption());
                    imgMap.put("tags", img.getTags());
                    imgMap.put("likes", img.getLikeCount());
                    imgMap.put("isLiked", img.isLikedBy(viewer));

                    String path = img.getPath();
                    if (path != null) {
                        try {
                            byte[] bytes = Files.readAllBytes(Paths.get(path));
                            imgMap.put("imageData", Base64.getEncoder().encodeToString(bytes));
                        } catch (IOException e) {
                            imgMap.put("imageData", null);
                        }
                    }
                    imageList.add(imgMap);
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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

        User viewer = viewerUsername != null ? Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(viewerUsername))
                .findFirst()
                .orElse(null) : null;

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
                Map<String, Object> iMap = new HashMap<>();
                iMap.put("id", img.getId());
                iMap.put("name", img.getName());
                iMap.put("owner", username);
                iMap.put("caption", img.getCaption());
                iMap.put("tags", img.getTags());
                iMap.put("date", img.getDate().toString());
                iMap.put("likes", img.getLikeCount());
                iMap.put("isLiked", img.isLikedBy(viewer));
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

                String path = img.getPath();
                if (path != null) {
                    try {
                        byte[] bytes = Files.readAllBytes(Paths.get(path));
                        iMap.put("imageData", Base64.getEncoder().encodeToString(bytes));
                    } catch (IOException e) {
                        iMap.put("imageData", null);
                    }
                }
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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

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
        long imageId = ((Double) request.getPayload().get("imageId")).longValue();

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image targetImage = null;
        for (User u : Admin.allUsers) {
            for (Image img : u.getImages()) {
                if (img.getId() == imageId) {
                    targetImage = img;
                    break;
                }
            }
            if (targetImage != null) break;
        }

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
        long imageId = ((Double) request.getPayload().get("imageId")).longValue();
        String text = (String) request.getPayload().get("text");

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

        if (user == null) return new Response(request.getRequestId(), 404, "User Not Found", null);

        Image targetImage = null;
        for (User u : Admin.allUsers) {
            for (Image img : u.getImages()) {
                if (img.getId() == imageId) {
                    targetImage = img;
                    break;
                }
            }
            if (targetImage != null) break;
        }

        if (targetImage == null) return new Response(request.getRequestId(), 404, "Image Not Found", null);

        try {
            user.writeComment(targetImage, text);
            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Comment Added Successfully", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(targetUsername))
                .findFirst()
                .orElse(null);

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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

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

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(oldUsername))
                .findFirst()
                .orElse(null);

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
            // Safely change username avoiding HashSet corruption
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

    private <T> T getPrivateField(Object obj, String fieldName) throws Exception {
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        return (T) field.get(obj);
    }
}

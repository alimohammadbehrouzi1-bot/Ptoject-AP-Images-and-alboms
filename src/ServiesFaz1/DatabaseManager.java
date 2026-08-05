package ServiesFaz1;

import com.google.gson.*;
import Faz1.*;
import java.io.*;
import java.lang.reflect.Field;
import java.time.LocalDateTime;
import java.util.*;

public class DatabaseManager {
    private static final String FILE_PATH = "storage/database.json";
    
    private static final Gson gson = new GsonBuilder()
            .registerTypeAdapter(
                    LocalDateTime.class,
                    (JsonSerializer<LocalDateTime>) (value, type, context) ->
                            new JsonPrimitive(value.toString())
            )
            .registerTypeAdapter(
                    LocalDateTime.class,
                    (JsonDeserializer<LocalDateTime>) (json, type, context) ->
                            LocalDateTime.parse(json.getAsString())
            )
            .setPrettyPrinting()
            .create();

    // --- DTO Classes for Flattened JSON Structure (to avoid circular references) ---

    private static class UserDTO {
        String username;
        String password;
        String email;
        Long phoneNumber;
        boolean banned;
        List<Long> likedImageIds = new ArrayList<>();
    }

    private static class AlbumDTO {
        long id;
        String name;
        String ownerUsername;
        List<Long> imageIds = new ArrayList<>();
    }

    private static class ImageDTO {
        long id;
        String name;
        String path;
        LocalDateTime date;
        String caption;
        Set<String> tags;
        String ownerUsername;
        List<String> usersWhoLikedUsernames = new ArrayList<>();
        List<CommentDTO> comments = new ArrayList<>();
    }

    private static class CommentDTO {
        long id;
        String comment;
        LocalDateTime date;
        String ownerUsername;
        List<String> usersWhoLikedUsernames = new ArrayList<>();
        long likes;
    }

    private static class AdminDTO {
        String username;
        String password;
    }

    private static class DatabaseDTO {
        List<UserDTO> users = new ArrayList<>();
        List<AdminDTO> admins = new ArrayList<>();
        List<AlbumDTO> albums = new ArrayList<>();
        List<ImageDTO> images = new ArrayList<>();
    }

    public synchronized static boolean save() {
        try {
            File directory = new File("storage");
            if (!directory.exists()) directory.mkdirs();

            DatabaseDTO db = new DatabaseDTO();

            // 1. Map Admins
            for (Admin admin : Admin.allAdmins) {
                AdminDTO dto = new AdminDTO();
                dto.username = getPrivateField(admin, "username");
                dto.password = getPrivateField(admin, "password");
                db.admins.add(dto);
            }

            // 2. Map Users and their related objects
            for (User user : Admin.allUsers) {
                UserDTO uDto = new UserDTO();
                uDto.username = user.getUsername();
                uDto.password = getPrivateField(user, "password");
                uDto.email = user.getEmail();
                uDto.phoneNumber = user.getPhoneNumber();
                uDto.banned = user.isBanned();
                
                Set<Image> likedImages = getPrivateField(user, "likedImages");
                if (likedImages != null) {
                    for (Image img : likedImages) uDto.likedImageIds.add(img.getId());
                }
                db.users.add(uDto);

                // 3. Map Images owned by this user
                for (Image img : user.getImages()) {
                    ImageDTO iDto = new ImageDTO();
                    iDto.id = img.getId();
                    iDto.name = img.getName();
                    iDto.path = getPrivateField(img, "path");
                    iDto.date = (LocalDateTime) img.getDate();
                    iDto.caption = img.getCaption();
                    iDto.tags = img.getTags();
                    iDto.ownerUsername = user.getUsername();
                    
                    Set<User> usersWhoLiked = getPrivateField(img, "usersWhoLiked");
                    if (usersWhoLiked != null) {
                        for (User u : usersWhoLiked) iDto.usersWhoLikedUsernames.add(u.getUsername());
                    }

                    // 4. Map Comments for this image
                    for (Comment c : img.getComments()) {
                        CommentDTO cDto = new CommentDTO();
                        cDto.id = c.getId();
                        cDto.comment = c.getComment();
                        cDto.date = getPrivateField(c, "date");
                        User commentOwner = getPrivateField(c, "owner");
                        cDto.ownerUsername = commentOwner.getUsername();
                        cDto.likes = getPrivateField(c, "likes");
                        
                        Set<User> cLikedBy = getPrivateField(c, "usersWhoLiked");
                        if (cLikedBy != null) {
                            for (User u : cLikedBy) cDto.usersWhoLikedUsernames.add(u.getUsername());
                        }
                        iDto.comments.add(cDto);
                    }
                    db.images.add(iDto);
                }

                // 5. Map Albums owned by this user
                for (Album alb : user.getAlbums()) {
                    AlbumDTO aDto = new AlbumDTO();
                    aDto.id = alb.getId();
                    aDto.name = alb.getName();
                    aDto.ownerUsername = user.getUsername();
                    for (Image img : alb.getImages()) aDto.imageIds.add(img.getId());
                    db.albums.add(aDto);
                }
            }

            try (FileWriter writer = new FileWriter(FILE_PATH)) {
                gson.toJson(db, writer);
            }
            return true;
        } catch (Exception e) {
            System.err.println("Save error: " + e.getMessage());
            return false;
        }
    }

    public synchronized static void load() {
        File file = new File(FILE_PATH);
        if (file.exists()) {
            try (FileReader reader = new FileReader(file)) {
                DatabaseDTO db = gson.fromJson(reader, DatabaseDTO.class);
                if (db != null) {
                    Admin.allUsers.clear();
                    Admin.allAdmins.clear();

                    Map<String, User> userMap = new HashMap<>();
                    Map<Long, Image> imageMap = new HashMap<>();

                    // 1. Reconstruct Admins
                    for (AdminDTO aDto : db.admins) {
                        new Admin(aDto.username, aDto.password);
                    }

                    // 2. Reconstruct Users
                    for (UserDTO uDto : db.users) {
                        User user = new User(uDto.username, uDto.password, uDto.email, uDto.phoneNumber);
                        user.setBanned(uDto.banned);
                        userMap.put(uDto.username, user);
                    }

                    // 3. Reconstruct Images
                    for (ImageDTO iDto : db.images) {
                        User owner = userMap.get(iDto.ownerUsername);
                        if (owner == null) continue;
                        
                        Image img = new Image(owner, iDto.path, iDto.name, iDto.caption, iDto.tags);
                        setPrivateField(img, "id", iDto.id);
                        setPrivateField(img, "date", iDto.date);
                        imageMap.put(iDto.id, img);
                        Faz1.Image.registerId(iDto.id);

                        owner.getImages().add(img);
                    }

                    // 4. Reconstruct Albums
                    for (AlbumDTO aDto : db.albums) {
                        User owner = userMap.get(aDto.ownerUsername);
                        if (owner == null) continue;

                        Album album = new Album(owner, aDto.name);
                        setPrivateField(album, "id", aDto.id);
                        
                        for (Long imgId : aDto.imageIds) {
                            Image img = imageMap.get(imgId);
                            if (img != null) {
                                album.addImageToAlbumViaImage(img);
                                img.addNewAlbumViaAlbum(album);
                            }
                        }
                        owner.getAlbums().add(album);
                    }

                    // 5. Restore Image details (likes/comments)
                    for (ImageDTO iDto : db.images) {
                        Image img = imageMap.get(iDto.id);
                        if (img == null) continue;

                        Set<User> usersWhoLiked = getPrivateField(img, "usersWhoLiked");
                        for (String username : iDto.usersWhoLikedUsernames) {
                            User u = userMap.get(username);
                            if (u != null) usersWhoLiked.add(u);
                        }

                        for (CommentDTO cDto : iDto.comments) {
                            User cOwner = userMap.get(cDto.ownerUsername);
                            if (cOwner == null) continue;
                            
                            Comment comment = new Comment(cOwner, img, cDto.comment);
                            if (cDto.id != 0) {
                                setPrivateField(comment, "id", cDto.id);
                                Faz1.Comment.registerId(cDto.id);
                            }
                            setPrivateField(comment, "date", cDto.date);
                            setPrivateField(comment, "likes", cDto.likes);
                            
                            Set<User> cLikedBy = getPrivateField(comment, "usersWhoLiked");
                            for (String username : cDto.usersWhoLikedUsernames) {
                                User u = userMap.get(username);
                                if (u != null) {
                                    cLikedBy.add(u);
                                    u.getLikedComment().add(comment);
                                }
                            }
                            img.getComments().add(comment);
                            
                            Set<Comment> userComments = getPrivateField(cOwner, "yourComments");
                            userComments.add(comment);
                        }
                    }

                    // 6. Restore User Liked Images
                    for (UserDTO uDto : db.users) {
                        User user = userMap.get(uDto.username);
                        if (user == null) continue;
                        for (Long imgId : uDto.likedImageIds) {
                            Image img = imageMap.get(imgId);
                            if (img != null) user.getLikedImages().add(img);
                        }
                    }

                    System.out.println("Database loaded successfully.");
                }
            } catch (Exception e) {
                System.err.println("Load error: " + e.getMessage());
                e.printStackTrace();
            }
        }

        ensureDefaultAdmin();
    }

    private static void ensureDefaultAdmin() {
        if (Admin.allAdmins.isEmpty()) {
            new Admin("admin", "admin");
            save();
            System.out.println("Default admin created.");
        }
    }

    private static void setPrivateField(Object obj, String fieldName, Object value) throws Exception {
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
    }

    @SuppressWarnings("unchecked")
    private static <T> T getPrivateField(Object obj, String fieldName) throws Exception {
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        return (T) field.get(obj);
    }
}

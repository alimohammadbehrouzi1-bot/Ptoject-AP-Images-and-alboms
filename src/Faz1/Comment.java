package Faz1;

import java.time.LocalDateTime;
import java.util.*;

public class Comment {
    private final long id;
    private String comment;
    private Image image;
    private User owner;
    private Set<User> usersWhoLiked = new HashSet<>();
    private long likes;
    private LocalDateTime date;

    private static final Set<Long> allUsedIds = new HashSet<>();

    public Comment(User user, Image image, String comment) throws Exception {
        owner = user;
        this.image = image;
        if (comment.length() > 1000)
            throw new Exception("caption should be under 1000 charecter");
        else this.comment = comment;
        date = LocalDateTime.now();
        this.id = generateGlobalUniqueId();
    }

    private static synchronized long generateGlobalUniqueId() {
        Random random = new Random();
        long idCreated;
        do {
            idCreated = 100000L + random.nextInt(900000);
        } while (allUsedIds.contains(idCreated));
        allUsedIds.add(idCreated);
        return idCreated;
    }

    public static void registerId(long id) {
        allUsedIds.add(id);
    }

    public long getId() {
        return id;
    }

    public void addLikeAndRemoveComment(User user) {
        if (usersWhoLiked.contains(user)) {
            likes--;
            usersWhoLiked.remove(user);
            user.getLikedComment().remove(this);
        } else {
            usersWhoLiked.add(user);
            likes++;
            user.getLikedComment().add(this);
        }
    }

    public String getComment() {
        return comment;
    }

    public String getOwnerUsername() {
        return owner.getUsername();
    }

    public LocalDateTime getDate() {
        return date;
    }

    public long getLikes() {
        return likes;
    }

    public boolean isLikedBy(User user) {
        return user != null && usersWhoLiked.contains(user);
    }
}

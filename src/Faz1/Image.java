package Faz1;

import java.util.*;


public class Image {
    private User owner ;
    private final long id ;
    private String path;
    private  String date;
    private  String name;
    private String caption;
    private Set <String> tags ;
    private Set <Long> albumIds = new HashSet<>() ;
    private Set <User> usersWhoLiked = new HashSet<>();
    private long likes;


    public Image( User owner , String name, String caption, String date , Set<String> tags) {
        this.owner = owner ;
        this.name = name;
        this.caption = caption;
        this.date = date;
        this.tags = new HashSet<>(tags);
        this.id = makeRandomId();
        this.likes= 0;
    }
    public long makeRandomId() {
        Random random = new Random();
        long idCreated;
        boolean exists;

        do {
            idCreated = random.nextInt(90000) + 10000;
            exists = false;

            for (Image img : owner.getImages()) {
                if (img.getId() == idCreated) {
                    exists = true;
                    break;
                }
            }

        } while (exists);

        return idCreated;
    }




    public void addNewAlbum(Album album) {
        albumIds.add(album.getId());
        album.addImageToAlbum(this);
    }
    public void removeFromAlbum(Album album){
        albumIds.remove(album.getId());
        album.removeImageFromAlbum(this);
    }
    public void addLikeAndRimoveLike(User user){
        if(usersWhoLiked.contains(user)){
            likes--;
            usersWhoLiked.remove(user);
        }
        else{
            usersWhoLiked.add(user);
            likes++;
        }
    }

    public long getId() {
        return id;
    }
}

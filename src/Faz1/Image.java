package Faz1;

import java.util.*;
import java.util.stream.Collectors;


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

    private ArrayList<Comment>  comments = new ArrayList<>() ;


    public Image( User owner ,String path, String name, String date ) throws Exception{
        this.owner = owner ;
        this.path = path;
        this.name = name;
        this.date = date;
        this.id = makeRandomId();
        this.likes= 0;
    }
    public Image( User owner ,String path, String name, String date , String caption) throws Exception{
        super();
        this.id = makeRandomId();
        this.caption =caption ;
    }
    public Image( User owner ,String path, String name, String date ,Set<String> tags){
        super();
        this.id = makeRandomId();
        this.tags =new HashSet<>(tags);
    }
    public Image( User owner ,String path, String name, String date,String caption , Set<String> tags) throws Exception{
        super();
        this.id = makeRandomId();
        this.caption = caption ;
        this.tags =new HashSet<>(tags);
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
    public void addOrEditCaption(String caption) throws Exception {
        this.caption = caption ;
    }
    public void addOrEditTags(Set<String> tags){
        this.tags = tags ;
    }


    public void addNewAlbum(Album... albums) {
        List<Album> list = Arrays.stream(albums).distinct().collect(Collectors.toList());
        list.forEach(a -> albumIds.add(a.getId()));
        list.forEach(a -> a.addImageToAlbumViaImage(this));
    }
    public void removeFromAlbum(Album... albums){
        List<Album> list = Arrays.stream(albums).distinct().collect(Collectors.toList());
        list.forEach(a-> albumIds.remove(a.getId()));
        list.forEach(a->a.removeImageFromAlbumViaImage(this));
    }
    public void addNewAlbumViaAlbum(Album album){
        albumIds.add(album.getId());
    }
    public void removeAlbumViaAlbum(Album album){
        albumIds.remove(album.getId());
    }

    public void addComment(User user,Comment comment){
        comments.add(comment);
    }

    public void addLikeAndRemoveLike(User user){
        if(usersWhoLiked.contains(user)){
            likes--;
            usersWhoLiked.remove(user);
            user.getLikedImageIds().remove(this.id);
        }
        else{
            usersWhoLiked.add(user);
            likes++;
            user.getLikedImageIds().add(this.id);
        }
    }

    public long getId() {
        return id;
    }
}

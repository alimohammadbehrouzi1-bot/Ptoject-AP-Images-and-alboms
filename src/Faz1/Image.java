package Faz1;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;


public class Image {
    private User owner ;
    private final long id ;
    private String path;
    private LocalDateTime date;
    private  String name;
    private String caption;
    private Set <String> tags = new HashSet<>() ;
    private Set <Album> albums = new HashSet<>() ;
    private Set <User> usersWhoLiked = new HashSet<>();
    private Set <User> userWhoComment = new HashSet<>();

    private ArrayList<Comment>  comments = new ArrayList<>() ;


    public Image( User owner ,String path, String name ) throws Exception{
        this.owner = owner ;
        this.path = path;
        this.name = name;
        this.date = LocalDateTime.now();
        this.id = makeRandomId();
    }
    public Image( User owner ,String path, String name , String caption) throws Exception{
        this(owner, path, name);
        this.caption =caption ;
    }
    public Image( User owner ,String path, String name ,Set<String> tags)throws Exception{
        this(owner, path, name);
        this.tags =tags;
    }
    public Image( User owner ,String path, String name,String caption , Set<String> tags) throws Exception{
        this(owner, path, name);
        this.caption = caption ;
        this.tags =tags;
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


    public void addNewAlbum(Album... albumss) {
        List<Album> list = Arrays.stream(albumss).distinct().collect(Collectors.toList());
        list.forEach(a -> albums.add(a));
        list.forEach(a -> a.addImageToAlbumViaImage(this));
    }
    public void removeFromAlbum(Album... albumss){
        List<Album> list = Arrays.stream(albumss).distinct().collect(Collectors.toList());
        list.forEach(a-> albums.remove(a));
        list.forEach(a->a.removeImageFromAlbumViaImage(this));
    }
    public void addNewAlbumViaAlbum(Album album){
        albums.add(album);
    }
    public void removeAlbumViaAlbum(Album album){
        albums.remove(album);
    }

    public void addComment(User user,Comment comment){
        comments.add(comment);
        userWhoComment.add(user);
    }

    public void addLikeAndRemoveLike(User user){
        if(usersWhoLiked.contains(user)){
            usersWhoLiked.remove(user);
            user.getLikedImages().remove(this);
        }
        else{
            usersWhoLiked.add(user);
            user.getLikedImages().add(this);
        }
    }

    public String getPath() {
        return path;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getCaption() {
        return caption;
    }

    public ArrayList<Comment> getComments() {
        return comments;
    }

    public Set<String> getTags() {
        return tags;
    }

    public Set<Album> getAlbums() {
        return albums;
    }

    public LocalDateTime getDate() {
        return date;
    }
}

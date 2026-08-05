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
    private Set <String> tags = new LinkedHashSet<>() ;
    private Set <Album> albums = new HashSet<>() ;
    private Set <User> usersWhoLiked = new HashSet<>();
    private Set <User> userWhoComment = new HashSet<>();

    private ArrayList<Comment>  comments = new ArrayList<>() ;


    private static final Set<Long> allUsedIds = new HashSet<>();

    public Image( User owner ,String path, String name ) throws Exception{
        this.owner = owner ;
        this.path = path;
        this.name = name;
        this.date = LocalDateTime.now();
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
    public Image( User owner ,String path, String name , String caption) throws Exception{
        this(owner, path, name);
        this.caption =caption ;
    }
    public Image( User owner ,String path, String name ,Set<String> tags)throws Exception{
        this(owner, path, name);
        if (tags != null) this.tags.addAll(tags);
    }
    public Image( User owner ,String path, String name,String caption , Set<String> tags) throws Exception{
        this(owner, path, name);
        this.caption = caption ;
        if (tags != null) this.tags.addAll(tags);
    }
    public void addOrEditCaption(String caption) throws Exception {
        this.caption = caption ;
    }
    public void addOrEditTags(Set<String> newTags) {
        this.tags.clear();
        if (newTags != null) {
            this.tags.addAll(newTags);
        }
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

    public int getLikeCount() {
        return usersWhoLiked.size();
    }

    public boolean isLikedBy(User user) {
        return user != null && usersWhoLiked.contains(user);
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

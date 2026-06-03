package Faz1;

import java.util.*;


public class Image {
    private final long id ;
    private String path;
    private  String date;
    private  String name;
    private String caption;
    private Set <String> tags ;
    private Set <Long> albumIds ;

    public Image( String caption, String date, long id, String name, String path, Set<String> tags) {
        this.name = name;
        this.caption = caption;
        this.date = date;
        this.id = id;
        this.path = path;
        this.tags = new HashSet<>(tags);
    }
    public void addNewAlbum(Album album) {
        albumIds.add(album.getId());
        album.addImageToAlbum(this);
    }
    public void removeFromAlbum(Album album){
        albumIds.remove(album.getId());
        album.removeImageFromAlbum(this);
    }

    public long getId() {
        return id;
    }
}

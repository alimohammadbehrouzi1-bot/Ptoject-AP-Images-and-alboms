package Faz1;

import java.util.*;


public class Image {
    private long id ;
    private String path;
    private  String date;
    private  String name;
    private String caption;
    private Set <String> tags ;
    private Set <Long> albumsid ;

    public Image(Set<Long> albumsid, String caption, String date, long id, String name, String path, Set<String> tags) {
        this.albumsid = new HashSet<>();
        this.caption = caption;
        this.date = date;
        this.id = id;
        this.name = name;
        this.path = path;
        this.tags = new HashSet<>();
    }
    public void addnewalbom(Album album) {
        albumsid.add(album.id);
        album.addImageId(this.id);
    }
    public void removeFromAlbum(Album album){
        albumsid.remove(album.id);
        album.removeImageFromAlbum(this.id);
    }

}

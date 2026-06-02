package Faz1;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Album {
    long id;
    private Set<Long> imagesid;


    public Album(long id, Set<Long> imagesid) {
        this.id = id;
        this.imagesid = new HashSet<>();
    }
    public void addImageId(long imageid){
        imagesid.add(imageid);

    }
    public void removeImageFromAlbum(long imageid){
        imagesid.remove(imageid);
    }
}


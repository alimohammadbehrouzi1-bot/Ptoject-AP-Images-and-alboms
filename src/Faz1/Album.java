package Faz1;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Album {
    private final long id;
    private Set<Long> imagesId;


    public Album(long id, Set<Image> images) {
        this.id = id;
        this.imagesId= new HashSet<>(images.stream().map(a->a.getId()).toList());
    }

    public void addImageToAlbum (Image image){
        imagesId.add(image.getId());

    }
    public void removeImageFromAlbum(Image image){
        imagesId.remove(image.getId());
    }

    public long getId() {
        return id;
    }
}

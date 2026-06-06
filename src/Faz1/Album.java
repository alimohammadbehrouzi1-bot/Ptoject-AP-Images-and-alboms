package Faz1;

import java.util.*;
import java.util.stream.Collectors;

public class Album {
    private final User owner ;
    private String name;
    private final long id ;
    private Set<Image> images;

    public Album(User owner,String name) {
        this.owner = owner;
        this.name=name;
        this.images = new HashSet<>();
        this.id = makeRandomId();
    }


    public Album(User owner,String name, Set<Image> images) {
        this.owner = owner;
        this.name = name;
        this.images = new HashSet<>();
        this.id = makeRandomId();

        for (Image img : images) {
            img.addNewAlbum(this);
        }
    }

    public void addImageToAlbumViaImage(Image image){
        images.add(image);

    }
    public void removeImageFromAlbumViaImage(Image image){
        images.remove(image);
    }
    public void addImageToAlbum(Image... imagess){
        List<Image> list = Arrays.stream(imagess).distinct().collect(Collectors.toList());
        list.forEach(a->images.add(a));
        list.forEach(a->a.addNewAlbumViaAlbum(this));
    }
    public void removeImageFromAlbum(Image... imagess){
        List<Image> list = Arrays.stream(imagess).distinct().collect(Collectors.toList());
        list.forEach(a->images.remove(a));
        list.forEach(a->a.removeAlbumViaAlbum(this));
    }

    public boolean moveImagesToAnotherAlbum(Album destAlbum, Image... images) {
        List<Image> list = Arrays.stream(images).distinct().collect(Collectors.toList());
        boolean check = list.stream().allMatch(a -> this.images.contains(a));
        if (check) {
            list.forEach(a -> a.removeFromAlbum(this));
            list.forEach(a -> a.addNewAlbum(destAlbum));
        }
        return check ;
    }
    public long getId() {
        return id;
    }

    public Set<Image> getImages() {
        return images;
    }

    public long makeRandomId() {
        Random random = new Random();
        long idCreated;
        boolean exists;

        do {
            idCreated = random.nextInt(90000) + 10000;
            exists = false;

            for (Album album : owner.getAlbums()) {
                if (album.getId() == idCreated) {
                    exists = true;
                    break;
                }
            }

        } while (exists);

        return idCreated;
    }
}

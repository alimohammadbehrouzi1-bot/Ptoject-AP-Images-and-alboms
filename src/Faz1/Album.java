package Faz1;

import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Set;

public class Album {
    private final User owner ;
    private String name;
    private final long id ;
    private Set<Long> imagesId;

    public Album(User owner,String name) {
        this.owner = owner;
        this.name=name;
        this.imagesId = new HashSet<>();
        this.id = makeRandomId();
    }


    public Album(User owner,String name, Set<Image> images) {
        this.owner = owner;
        this.name = name;
        this.imagesId = new HashSet<>();
        this.id = makeRandomId();

        for (Image img : images) {
            img.addNewAlbum(this);
        }
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

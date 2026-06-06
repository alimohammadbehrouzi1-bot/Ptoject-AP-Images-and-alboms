package Faz1;

import java.util.*;
import java.util.stream.Collectors;

public class Album {
    private final User owner;
    private String name;
    private final long id;
    private Set<Long> imagesId;

    public Album(User owner, String name) {
        this.owner = owner;
        this.name = name;
        this.imagesId = new HashSet<>();
        this.id = makeRandomId();
    }


    public Album(User owner, String name, Set<Image> images) {
        this.owner = owner;
        this.name = name;
        this.imagesId = new HashSet<>();
        this.id = makeRandomId();

        for (Image img : images) {
            img.addNewAlbum(this);
        }
    }

    public void addImageToAlbumViaImage(Image image) {
        imagesId.add(image.getId());

    }
    public void removeImageFromAlbumViaImage(Image image) {
        imagesId.remove(image.getId());
    }
    public void addImageToAlbum(Image... images) {
        List<Image> list = Arrays.stream(images).distinct().collect(Collectors.toList());
        list.forEach(a -> imagesId.add(a.getId()));
        list.forEach(a -> a.addNewAlbumViaAlbum(this));
    }
    public void removeImageFromAlbum(Image... images) {
        List<Image> list = Arrays.stream(images).distinct().collect(Collectors.toList());
        list.forEach(a -> imagesId.remove(a.getId()));
        list.forEach(a -> a.removeAlbumViaAlbum(this));
    }

    public boolean moveImagesToAnotherAlbum(Album destAlbum, Image... images) {
        List<Image> list = Arrays.stream(images).distinct().collect(Collectors.toList());
        boolean check = list.stream().allMatch(a -> this.imagesId.contains(a.getId()));
        if (check) {
            list.forEach(a -> a.removeFromAlbum(this));
            list.forEach(a -> a.addNewAlbum(destAlbum));
        }
        return check;
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
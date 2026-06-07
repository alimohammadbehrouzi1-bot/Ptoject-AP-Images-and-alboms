package Faz1;

import static org.junit.Assert.*;
import org.junit.*;
import java.util.Set;
import java.util.HashSet;

public class AlbumAndImageTest {

    User user1;
    User user2;
    Image image1;
    Image image2;
    Album album1;
    Album album2;

    @Before
    public void initialize() throws Exception {
        Admin.allUsers.clear();

        user1 = new User("ali", "Password1");
        user2 = new User("mahan", "Password2");

        image1 = new Image(user1, "path1", "image1");
        image2 = new Image(user1, "path2", "image2");

        album1 = new Album(user1, "album1");
        album2 = new Album(user1, "album2");
    }


    // Image

    @Test
    public void imageNameAndCaption() throws Exception {
        assertEquals("image1", image1.getName());
        image1.addOrEditCaption("caption1");
        assertEquals("caption1", image1.getCaption());
        image1.addOrEditCaption("caption2");
        assertEquals("caption2", image1.getCaption());
    }

    @Test
    public void imageTagsAddAndEdit() {
        Set<String> tags = new HashSet<>();
        tags.add("tag1");
        tags.add("tag2");
        image1.addOrEditTags(tags);
        assertTrue(image1.getTags().contains("tag1"));
        assertTrue(image1.getTags().contains("tag2"));
    }

    @Test
    public void imageIdIsUnique() {
        assertNotEquals(image1.getId(), image2.getId());
    }

    @Test
    public void imageConstructors() throws Exception {
        Set<String> tags = new HashSet<>();
        tags.add("tag1");
        Image img = new Image(user1, "path3", "image3", "caption1", tags);
        assertEquals("caption1", img.getCaption());
        assertEquals(tags,img.getTags());
    }

    @Test
    public void addAndRemoveAlbumViaImage() {
        image1.addNewAlbum(album1, album2);
        assertTrue(image1.getAlbums().contains(album1));
        assertTrue(image1.getAlbums().contains(album2));
        assertTrue(album1.getImages().contains(image1));
        assertTrue(album2.getImages().contains(image1));

        image1.removeFromAlbum(album1);
        assertFalse(image1.getAlbums().contains(album1));
        assertFalse(album1.getImages().contains(image1));
        assertTrue(image1.getAlbums().contains(album2));
    }

    @Test
    public void likeAndUnlikeImage() {
        image1.addLikeAndRemoveLike(user2);
        assertTrue(user2.getLikedImages().contains(image1));

        image1.addLikeAndRemoveLike(user2);
        assertFalse(user2.getLikedImages().contains(image1));
    }

    @Test
    public void addCommentToImage() throws Exception {
        Comment comment = new Comment(user2, image1, "comment1");
        image1.addComment(user2, comment);
        assertEquals("comment1", image1.getComments().get(0).getComment());
    }

    // Albums

    @Test
    public void albumName() {
        assertEquals("album1", album1.getName());
    }
    @Test
    public void albumsIdBeingUnique() {
        assertNotEquals(album1.getId(), album2.getId());
    }

    @Test
    public void addAndRemoveImageViaAlbum() {
        album1.addImageToAlbum(image1, image2);
        assertTrue(album1.getImages().contains(image1));
        assertTrue(album1.getImages().contains(image2));
        assertTrue(image1.getAlbums().contains(album1));

        album1.removeImageFromAlbum(image1);
        assertFalse(album1.getImages().contains(image1));
        assertFalse(image1.getAlbums().contains(album1));
        assertTrue(album1.getImages().contains(image2));
    }

    @Test
    public void albumConstructorWithImages() {
        Set<Image> images = new HashSet<>();
        images.add(image1);
        images.add(image2);
        Album album = new Album(user1, "album3", images);
        assertTrue(album.getImages().contains(image1));
        assertTrue(image1.getAlbums().contains(album));
    }

    @Test
    public void moveImagesToAnotherAlbum() {
        album1.addImageToAlbum(image1, image2);
        boolean result = album1.moveImagesToAnotherAlbum(album2, image1, image2);
        assertTrue(result);
        assertFalse(album1.getImages().contains(image1));
        assertTrue(album2.getImages().contains(image1));
        assertTrue(album2.getImages().contains(image2));
    }

}
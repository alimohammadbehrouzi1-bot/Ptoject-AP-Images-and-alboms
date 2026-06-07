package Faz1;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class UserTest {

    private User user;

    @BeforeEach
    void initialize() throws Exception {
        Admin.allUsers.clear();
        user = new User("Ali", "Password1");
    }

    @Test
    void constructorTest() {
        assertEquals("Ali", user.getUsername());
        assertNull(user.getEmail());
        assertNull(user.getPhoneNumber());
        assertFalse(user.isBanned());
    }

    @Test
    void constructorWithEmailTest() throws Exception {
        User user2 = new User("Reza", "Password2", "reza@gmail.com");

        assertEquals("reza@gmail.com", user2.getEmail());
        assertEquals("Reza", user2.getUsername());
    }

    @Test
    void setEmailTest() throws Exception {
        user.setEmail("ali@gmail.com");

        assertEquals("ali@gmail.com", user.getEmail());
    }

    @Test
    void invalidEmailTest() {
        Exception exception = assertThrows(Exception.class,
                () -> user.setEmail("ali@yahoo.com"));

        assertEquals("Email is not valid", exception.getMessage());
    }

    @Test
    void setPhoneNumberTest() throws Exception {
        user.setPhoneNumber(989121234567L);

        assertEquals(Long.valueOf(989121234567L), user.getPhoneNumber());
    }

    @Test
    void invalidPhoneNumberTest() {
        assertThrows(Exception.class,
                () -> user.setPhoneNumber(9121234567L));
    }

    @Test
    void changePasswordTest() throws Exception {
        user.changePassword("Ali", "Password1", "NewPass12");

        assertDoesNotThrow(() ->
                user.logIn("Ali", "NewPass12"));
    }

    @Test
    void weakPasswordTest() {
        assertThrows(Exception.class,
                () -> new User("Sara", "weak"));
    }

    @Test
    void duplicateUsernameTest() {
        assertThrows(Exception.class,
                () -> new User("Ali", "Password2"));
    }

    @Test
    void uploadImageTest() throws Exception {
        int sizeBefore = user.getImages().size();

        user.uploadImage("img1", "/path/image.jpg");

        assertEquals(sizeBefore + 1, user.getImages().size());
    }

    @Test
    void makeAlbumTest() throws Exception {
        int sizeBefore = user.getAlbums().size();

        user.makeNewAlbum("Travel");

        assertEquals(sizeBefore + 1, user.getAlbums().size());
    }

    @Test
    void searchAllNullTest() {
        NullPointerException exception =
                assertThrows(NullPointerException.class,
                        () -> user.searchAll(null));

        assertEquals("String is null", exception.getMessage());
    }

    @Test
    void banUserTest() {
        user.setBanned(true);

        assertTrue(user.isBanned());
    }

    @Test
    void equalsTest() {
        User user2 = user;

        assertEquals(user, user2);
    }

    @Test
    void hashCodeTest() {
        assertEquals(user.hashCode(), user.hashCode());
    }

    @Test
    void toStringTest() {
        assertNotNull(user.toString());
        assertTrue(user.toString().contains("Ali"));
    }
    @Test
    void bannedUserCanNotUploadImageTest() throws Exception {

        user.setBanned(true);

        Exception exception = assertThrows(Exception.class,
                () -> user.uploadImage("img1", "/path/image.jpg"));

        assertEquals("User is banned.", exception.getMessage());
    }
}
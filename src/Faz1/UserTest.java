package Faz1;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class UserTest {

    @BeforeEach
    void setUp() {
        Admin.allUsers.clear();
    }

    @Test
    void createUserSuccessfully() throws Exception {
        User user = new User("mahan", "Password1");

        assertEquals("mahan", user.getUsername());
        assertFalse(user.isBanned());
    }

    @Test
    void createUserWithEmailSuccessfully() throws Exception {
        User user = new User(
                "aliMohammad",
                "Password1",
                "ali@gmail.com"
        );

        assertEquals("ali@gmail.com", user.getEmail());
    }

    @Test
    void duplicateUsernameShouldThrowException() throws Exception {
        new User("mahan", "Password1");

        Exception exception = assertThrows(
                Exception.class,
                () -> new User("mahan", "Password2")
        );

        assertEquals("username is used", exception.getMessage());
    }

    @Test
    void weakPasswordShouldThrowException() {
        Exception exception = assertThrows(
                Exception.class,
                () -> new User("mahan", "1234")
        );

        assertTrue(exception.getMessage().contains("Password must be at least 8 characters."));

        Exception exception1 = assertThrows(
                Exception.class,
                () -> new User("mahan", "mahan123A")
        );

        assertEquals(
                "Password must not contain username.",
                exception1.getMessage()
        );
    }

    @Test
    void validEmailShouldBeAccepted() throws Exception {
        User user = new User("mahan", "Password1");

        user.setEmail("mahan@gmail.com");

        assertEquals("mahan@gmail.com", user.getEmail());

        User user1 = new User("Ali", "Password123");

        Exception exception = assertThrows(
                Exception.class,
                () -> user1.setEmail("Ali@yahoo.com")
        );

        assertEquals("Email is not valid", exception.getMessage());
    }

    @Test
    void PhoneNumber() throws Exception {
        User user = new User("mahan", "Password1");

        user.setPhoneNumber(989123456789L);

        assertEquals(
                989123456789L,
                user.getPhoneNumber()
        );

        User user1 = new User("aliMohammad", "Password12");

        Exception exception = assertThrows(
                Exception.class,
                () -> user1.setPhoneNumber(9123456789L)
        );

        assertNotNull(exception);
    }

    @Test
    void changePassword() throws Exception {
        User user = new User("mahan", "Password1");

        user.changePassword(
                "mahan",
                "Password1",
                "NewPass12"
        );

        user.logIn("mahan", "NewPass12");
        user.uploadImage("img", "/test");
        assertEquals(1 , user.getImages().size());


        User user1 = new User("ali", "Password123");

        user1.logIn("ali", "wrongPass");

        Exception exception2 = assertThrows(
                Exception.class,
                () -> user1.uploadImage("img", "/test")
        );

        assertEquals("first Log In", exception2.getMessage());
    }

    @Test
    void uploadImage() throws Exception {
        User user = new User("aliMohammad", "Password1");

        user.uploadImage(
                "nature",
                "/images/nature.jpg"
        );

        assertEquals(
                1,
                user.getImages().size()
        );
        User user1 = new User("ali", "Password12");

        user1.setBanned(true);

        Exception exception = assertThrows(
                Exception.class,
                () -> user1.uploadImage("nature", "/images/nature.jpj")
        );
        assertEquals("User is banned.", exception.getMessage());
    }
    @Test
    void editInformation() throws Exception {
    }
}
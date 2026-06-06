package Faz1;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class AdminTest {

    private Admin admin;
    private User mahan;
    private User aliMohammad;

    @BeforeEach
    void setUp() throws Exception {

        Admin.allUsers.clear();
        Admin.allAdmins.clear();

        admin = new Admin("admin", "1234");

        mahan = new User("mahan", "Password123A");
        aliMohammad = new User("aliMohammad", "Password123A");
    }

    @Test
    void loginSuccessfully() throws Exception {

        Admin loggedAdmin = Admin.Login("admin", "1234");

        assertEquals(admin, loggedAdmin);
    }

    @Test
    void loginWrongUsername() {

        Exception exception = assertThrows(
                Exception.class,
                () -> Admin.Login("wrongAdmin", "1234")
        );

        assertEquals("no such admin", exception.getMessage());
    }


    @Test
    void changePasswordSuccessfully() throws Exception {

        admin.ChangePassword("admin", "1234", "newPass");

        Admin loggedAdmin =
                Admin.Login("admin", "newPass");

        assertEquals(admin, loggedAdmin);
    }

    @Test
    void changePasswordWrongPassword() {

        assertThrows(
                Exception.class,
                () -> admin.ChangePassword(
                        "admin",
                        "wrongPassword",
                        "newPass")
        );
    }

    @Test
    void banAndUnban() throws Exception {

        admin.banOrUnbanUser(aliMohammad, true);

        assertTrue(aliMohammad.isBanned());

        admin.banOrUnbanUser(aliMohammad, false);

        assertFalse(aliMohammad.isBanned());
    }

    @Test
    void printUserInfo() throws Exception {

        User ghost =
                new User("ghost2", "Password123A");

        Admin.allUsers.remove(ghost);

        Exception exception = assertThrows(
                Exception.class,
                () -> admin.printUserInfo(ghost)
        );

        assertEquals(
                "no such user",
                exception.getMessage()
        );
    }
}
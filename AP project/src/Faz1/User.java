package Faz1;

import java.util.ArrayList;

public class User {
    private String username;
    private String password;
    private String email;
    private String phoneNumber;

    private ArrayList<Album> albums;
    private ArrayList<Image> images;

    public User(int id, String username, String password, String email, String phoneNumber) {
        this.username = username;

        this.email = email;
        this.phoneNumber = phoneNumber;

        this.albums = new ArrayList<>();
        this.images = new ArrayList<>();
    }


}


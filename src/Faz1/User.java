package Faz1;

import java.util.*;

public class User {
    private String username;
    private String password;
    private String email;
    private Long phoneNumber;

    private ArrayList<Album> albums;
    private ArrayList<Image> images;
    private Set<Long> likedImageIds;
    private Set<Caption> likedCaption ;

    public User(String username, String password) throws Exception {
        this.username = username;
        setPassword(password);
        this.albums = new ArrayList<>();
        this.images = new ArrayList<>();
        this.likedImageIds = new HashSet<>();
        this.likedCaption  = new HashSet<>();
    }

    public User(String username, String password, String email) throws Exception {
        this(username, password);
        setEmail(email);
    }

    public User(String username, String password, Long phoneNumber) throws Exception {
        this(username, password);
        setPhoneNumber(phoneNumber);
    }

    public User(String username, String password, String email, Long phoneNumber) throws Exception {
        this(username, password);
        setEmail(email);
        setPhoneNumber(phoneNumber);
    }


    public String getUsername() {
        return username;
    }


    public String getEmail() {
        return email;
    }

    public Long getPhoneNumber() {
        return phoneNumber;
    }

    public ArrayList<Album> getAlbums() {
        return albums;
    }

    public ArrayList<Image> getImages() {
        return images;
    }
    public Set<Long> getLikedImageIds() {
        return likedImageIds;
    }

    public Set<Caption> getLikedCaption() {
        return likedCaption;
    }

    public void uploadImage(String name, String path, String caption, String date, Set<String> tags) throws Exception {

        Image image = new Image(this, path, name, date, caption  , tags);

        images.add(image);

    }
    public void makeNewAlbum(String name){
        Album album = new Album(this,name);
        albums.add(album);
    }
    public void makeNewAlbum(String name,Image ... imageid){
        Set<Image> set = new HashSet<>();
        set.addAll(Arrays.asList(imageid));
        Album album = new Album(this,name,set);
        albums.add(album);

    }
    public void addOrRemoveLikeImage(Image image){
        image.addLikeAndRemoveLike(this);
    }
    public void addOrRemoveLikeCaption(Caption caption){
        caption.addLikeAndRemoveCaption(this);
    }



    public void setPassword(String password) throws Exception {
        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        if (password.length() >= 8) {
            if (!password.contains(this.getUsername())) {
                for (char c : password.toCharArray()) {
                    if (Character.isUpperCase(c)) hasUpper = true;
                    else if (Character.isLowerCase(c)) hasLower = true;
                    else if (Character.isDigit(c)) hasDigit = true;
                }
                if (hasDigit && hasLower && hasUpper) {
                    this.password = password;
                    return;
                } else throw new Exception("Password must contain uppercase, lowercase and digit.");
            }
            throw new Exception("Password must not contain username.");
        }
        throw new Exception("Password must be at least 8 characters.");
    }


    public void setEmail(String email) throws Exception {
        if (email.endsWith("@gmail.com") && !email.startsWith("@gmail.com")) {
            this.email = email;
            return;
        } else throw new Exception("Email is not valid");
    }


    public void setPhoneNumber(Long phoneNumber) throws Exception {
        String PhoneNumber2 = phoneNumber.toString();
        if (PhoneNumber2.length() == 11) {
            if (PhoneNumber2.startsWith("98")) {
                this.phoneNumber = phoneNumber;
                return;
            } else
                throw new Exception("phone number should start with 98");
        } else
            throw new Exception("phone number lenght should be 11");
    }



    @Override
    public boolean equals(Object object) {
        if (object == null || getClass() != object.getClass()) return false;
        User user = (User) object;
        return Objects.equals(username, user.username);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(username);
    }
}
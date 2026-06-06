package Faz1;

import java.util.*;
import java.util.stream.Collectors;

public class User {
    private String username;
    private String password;
    private String email;
    private Long phoneNumber;
    private boolean banned;

    private ArrayList<Album> albums;
    private ArrayList<Image> images;
    private Set<Image> likedImages;
    private Set<Comment> likedComment;
    private Set<Comment> yourComments = new HashSet<>();

    public User(String username, String password) throws Exception {
        this.username = username;
        setPassword(password);
        this.albums = new ArrayList<>();
        this.images = new ArrayList<>();
        this.likedImages = new HashSet<>();
        this.likedComment = new HashSet<>();
        this.banned = false;
        Admin.allUsers.add(this);
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

    private void checkBanned() throws Exception {
        if (banned) {
            throw new Exception("User is banned.");
        }
    }

    public List<Image> searchByName(String word) {
        String lowerword = word.toLowerCase();
        List<Image> natige;
        natige = this.images.stream()
                .filter(image -> image.getName().toLowerCase().contains(lowerword))
                .collect(Collectors.toList());
        return natige;
    }

    public List<Image> searchByCaption(String word) {

        String lowerword = word.toLowerCase();
        List<Image> natige;
        natige = this.images.stream()
                .filter(image -> image.getCaption() != null && image.getCaption().toLowerCase().contains(lowerword))
                .collect(Collectors.toList());
        return natige;
    }

    public List<Image> searchByComments(String word) {

        String lowerword = word.toLowerCase();
        List<Image> natige;
        natige = this.images.stream()
                .filter(image -> image.getComments() != null && image.getComments().stream()
                        .anyMatch(c -> c.getComment().toLowerCase().contains(lowerword)))
                .collect(Collectors.toList());
        return natige;
    }

    public List<Image> searchByTags(String word) {
        String lowerword = word.toLowerCase();
        List<Image> natige;
        natige = this.images.stream()
                .filter(image -> image.getTags() != null && image.getTags().stream()
                        .anyMatch(c -> c.toLowerCase().contains(lowerword)))
                .collect(Collectors.toList());
        return natige;
    }

    public List<Image> searchAll(String word) throws NullPointerException {
        if (word == null) {
            throw new NullPointerException("String is null");
        }
        if (word.startsWith("#")) {
            String withoutHashtak = word.substring(1);
            return searchByTags(withoutHashtak);
        }
        List<Image> finalResult = new ArrayList<>();

        List<List<Image>> allResults = Arrays.asList(searchByName(word), searchByCaption(word), searchByComments(word), searchByTags(word));
        for (List<Image> inerList : allResults) {
            for (Image image : inerList) {
                if (!finalResult.contains(image)) {
                    finalResult.add(image);
                }
            }
        }
        return finalResult;
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

    public Set<Image> getLikedImages() {
        return likedImages;
    }

    public Set<Comment> getLikedComment() {
        return likedComment;
    }

    public void uploadImage(String name, String path, String caption, Set<String> tags) throws Exception {
        checkBanned();
        Image image = new Image(this, path, name, caption, tags);
        images.add(image);
    }

    public void uploadImage(String name, String path, String caption) throws Exception {
        checkBanned();
        Image image = new Image(this, path, name, caption);
        images.add(image);
    }

    public void uploadImage(String name, String path, Set<String> tags) throws Exception {
        checkBanned();
        Image image = new Image(this, path, name, tags);
        images.add(image);
    }

    public void uploadImage(String name, String path) throws Exception {
        checkBanned();
        Image image = new Image(this, path, name);
        images.add(image);
    }

    public void makeNewAlbum(String name) throws Exception {
        checkBanned();
        Album album = new Album(this, name);
        albums.add(album);
    }

    public void makeNewAlbum(String name, Image... image) throws Exception {
        checkBanned();
        Set<Image> set = new HashSet<>();
        set.addAll(Arrays.asList(image));
        Album album = new Album(this, name, set);
        albums.add(album);

    }

    public void addOrRemoveLikeImage(Image image) throws Exception {
        checkBanned();
        image.addLikeAndRemoveLike(this);
    }

    public void addOrRemoveLikeComment(Comment comment) throws Exception {
        checkBanned();
        comment.addLikeAndRemoveComment(this);
    }

    public void writeComment(Image image, String string) throws Exception {
        checkBanned();
        Comment comment = new Comment(this, image, string);
        image.addComment(this, comment);
        yourComments.add(comment);
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

    public void deleteAlbum(Album album) throws Exception {
        checkBanned();
        if (album == null) {
            throw new Exception("album is null");
        }
        if (albums.contains(album)) {
            if (!album.isEmpty()) {
                throw new Exception("Album is not empty. Please remove or move the images first.");
            }
            this.albums.remove(album);
        }
    }

    public void deleteImage(Image image) throws Exception {
        checkBanned();
        for (Album album : image.getAlbums()) {
            album.removeImageFromAlbumViaImage(image);
        }
        images.remove(image);
    }

    public void setBanned(boolean banned) {
        this.banned = banned;
    }

    @Override
    public String toString(){
        return "---------------"+
                "Username : " + this.getUsername()+
                "Email    : " + (this.getEmail() != null ? getEmail() : "nothing")+
                "Phone    : " + (this.getPhoneNumber() != null ? this.getPhoneNumber() : "nothing")+
                "Albums   : " + this.getAlbums().size()+
                "Images   : " + this.getImages().size()+
                "Banne?   : " + (this.banned ? "Banned" : "Active")+
                "--------------";
    }

    public boolean isBanned() {
        return banned;
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
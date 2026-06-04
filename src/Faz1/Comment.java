package Faz1;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Comment {
    private String comment;
    private Image image ;
    private User owner ;
    private Set<User> usersWhoLiked =new HashSet<>() ;
    private long likes ;

    public Comment(User user , Image image ,String comment, String date) throws Exception {
        owner = user ;
        this.image =image ;
        if (comment.length() > 1000)
            throw new Exception("caption should be under 1000 charecter");
        else this.comment = comment;
    }

    public void addLikeAndRemoveComment(User user){
        if(usersWhoLiked.contains(user)){
            likes--;
            usersWhoLiked.remove(user);
            user.getLikedComment().remove(this);
        }
        else{
            usersWhoLiked.add(user);
            likes++;
            user.getLikedComment().add(this);
        }
    }
}

package Faz1;

import java.util.HashSet;
import java.util.Set;

public class Caption {
    private String caption ;
    private Set<User> usersWhoLiked =new HashSet<>() ;
    private long likes ;

    public Caption(String caption) throws Exception {
        if (caption.length() > 1000)
            throw new Exception("caption should be under 1000 charecter");
        else this.caption = caption;
    }

    public void addLikeAndRemoveCaption(User user){
        if(usersWhoLiked.contains(user)){
            likes--;
            usersWhoLiked.remove(user);
            user.getLikedCaption().remove(this);
        }
        else{
            usersWhoLiked.add(user);
            likes++;
            user.getLikedCaption().add(this);
        }
    }
}

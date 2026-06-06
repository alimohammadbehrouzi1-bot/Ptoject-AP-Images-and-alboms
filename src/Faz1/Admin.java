package Faz1;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

public class Admin {
    private  String username;
    private String password;
    static Set<User> allUsers = new HashSet<>();
    static Set<Admin> allAdmins= new HashSet<>();

    public Admin(String username, String password) {
        this.username = username;
        this.password = password;
        allAdmins.add(this);
    }
    public static Admin Login(String username , String password) throws Exception{
        for(Admin admin: allAdmins){
            if(admin.username.equals(username) && admin.password.equals(password)){
                return admin;
            }
        }
        throw new Exception("no such admin");
    }

    public void ChangePassword(String firstusername,String firstpassword,String newpassword) throws Exception {
        Admin admin = Admin.Login(firstusername,firstpassword);
        admin.password=newpassword;

    }
    public void banOrUnbanUser(User user,boolean condition)throws Exception{
        for(User u: allUsers){
            if(u.equals(user)){
                user.setBanned(condition);
                if (condition){
                    System.out.println(user.getUsername()+" is banned now");
                }
                else {
                    System.out.println(user.getUsername()+" is unbanned now");
                }
                return;
            }
        }
        throw new Exception("no such user");
    }
    public void printUserInfo(User user) throws Exception{
        for(User u:allUsers){
            if (u.equals(user)){
                System.out.println(u);
                return;
            }
        }
        throw new Exception("no such user");
    }
    public void printUsersList(Set <User> set){
        if(allUsers.isEmpty()){
            System.out.println("no user");
            return;
        }
        for (User user : set){
            System.out.println(user);
        }
    }
    public void printAllUsers(){
        printUsersList(allUsers);
    }
    public void printAllBannedUsers(){
        Set<User> banned = allUsers.stream()
                .filter(User::isBanned)
                .collect(Collectors.toSet());
        printUsersList(banned);
    }

}

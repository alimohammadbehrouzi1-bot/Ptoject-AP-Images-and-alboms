package ServiesFaz1;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import Faz1.Admin;
import Faz1.User;
import java.io.*;
import java.util.HashSet;
import java.util.Set;

public class DatabaseManager {
    private static final String FILE_PATH = "storage/database.json";
    private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    private static class DataWrapper {
        Set<User> users = new HashSet<>();
        Set<Admin> admins = new HashSet<>();
    }

    public synchronized static void save() {
        try {
            File directory = new File("storage");
            if (!directory.exists()) {
                directory.mkdirs();
            }

            try (FileWriter writer = new FileWriter(FILE_PATH)) {
                DataWrapper wrapper = new DataWrapper();
                wrapper.users = Admin.allUsers;
                wrapper.admins = Admin.allAdmins;
                gson.toJson(wrapper, writer);
            }
        } catch (IOException e) {
            System.err.println("Save error: " + e.getMessage());
        }
    }

    public synchronized static void load() {
        File file = new File(FILE_PATH);
        if (!file.exists()) return;

        try (FileReader reader = new FileReader(file)) {
            DataWrapper wrapper = gson.fromJson(reader, DataWrapper.class);
            if (wrapper != null) {
                if (wrapper.users != null) {
                    Admin.allUsers.clear();
                    Admin.allUsers.addAll(wrapper.users);
                }
                if (wrapper.admins != null) {
                    Admin.allAdmins.clear();
                    Admin.allAdmins.addAll(wrapper.admins);
                }
                System.out.println("Database loaded successfully.");
            }
        } catch (IOException e) {
            System.err.println("Load error: " + e.getMessage());
        }
    }
}

package ServiesFaz1;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import Faz1.Admin;
import Faz1.User;
import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DatabaseManager {
    private static final String FILE_PATH = "storage/database.json";
    private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    public synchronized static void save() {
        try (FileWriter writer = new FileWriter(FILE_PATH)) {
            Map<String, Object> data = new HashMap<>();
            data.put("users", Admin.allUsers);
            data.put("admins", Admin.allAdmins);
            gson.toJson(data, writer);
        } catch (IOException e) {
            System.err.println("Save error: " + e.getMessage());
        }
    }

    public synchronized static void load() {
        File file = new File(FILE_PATH);
        if (!file.exists()) return;

        try (FileReader reader = new FileReader(file)) {
            Map<String, Object> data = gson.fromJson(reader, Map.class);
            if (data != null) {
                System.out.println("Data loaded from file.");
            }
        } catch (IOException e) {
            System.err.println("Load error: " + e.getMessage());
        }
    }
}

package ServiesFaz1;

import com.google.gson.Gson;
import Faz1.User;
import Faz1.Admin;
import Faz1.Image;
import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class BackendServer {
    private static final int PORT = 8080;

    public void start() {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Server started on port " + PORT);
            while (true) {
                Socket clientSocket = serverSocket.accept();
                new Thread(new ClientHandler(clientSocket)).start();
            }
        } catch (IOException e) {
            System.err.println("Server error: " + e.getMessage());
        }
    }
}

class ClientHandler implements Runnable {
    private final Socket socket;
    private final Gson gson = new Gson();
    private static final Map<String, String> routes = new HashMap<>();

    static {
        routes.put("auth/login", "auth");
        routes.put("auth/register", "auth");
        routes.put("admin/login", "admin");
    }

    public ClientHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        try (
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            PrintWriter out = new PrintWriter(socket.getOutputStream(), true)
        ) {
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                try {
                    Request request = gson.fromJson(inputLine, Request.class);
                    Response response = handleRouting(request);
                    out.println(gson.toJson(response));
                } catch (Exception e) {
                    Response errorResponse = new Response(null, 500, "Internal Server Error: " + e.getMessage(), null);
                    out.println(gson.toJson(errorResponse));
                }
            }
        } catch (IOException e) {
            System.err.println("Handler error: " + e.getMessage());
        } finally {
            try {
                socket.close();
            } catch (IOException e) {
                System.err.println("Socket close error: " + e.getMessage());
            }
        }
    }

    private Response handleRouting(Request request) {
        String route = request.getRoute();
        switch (route) {
            case "auth/login": return handleLogin(request);
            case "auth/register": return handleRegister(request);
            case "admin/login": return handleAdminLogin(request);
            case "image/upload": return handleImageUpload(request);
            case "image/get-all": return handleImageGetAll(request);
            default: return new Response(request.getRequestId(), 404, "Route Not Found", null);
        }
    }

    private Response handleLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        for (User u : Admin.allUsers) {
            if (u.getUsername().equals(username)) {
                u.logIn(username, password);
                if (u.isBanned()) {
                    return new Response(request.getRequestId(), 403, "Forbidden: User is Banned", null);
                }
                return new Response(request.getRequestId(), 200, "Login Success", new HashMap<>());
            }
        }
        return new Response(request.getRequestId(), 401, "Unauthorized: Invalid credentials", null);
    }

    private Response handleAdminLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        try {
            Admin.Login(username, password);
            return new Response(request.getRequestId(), 200, "Admin Login Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 401, "Unauthorized: Invalid admin credentials", null);
        }
    }

    private Response handleRegister(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");
        String email = (String) request.getPayload().get("email");
        Object phoneRaw = request.getPayload().get("phone");
        Long phone = (phoneRaw != null) ? Long.parseLong(phoneRaw.toString()) : null;

        try {
            if (email != null && !email.isEmpty() && phone != null) new User(username, password, email, phone);
            else if (email != null && !email.isEmpty()) new User(username, password, email);
            else if (phone != null) new User(username, password, phone);
            else new User(username, password);

            DatabaseManager.save();
            return new Response(request.getRequestId(), 200, "Registration Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 400, "Registration Failed: " + e.getMessage(), null);
        }
    }

    private Response handleImageUpload(Request request) {
        String username = (String) request.getPayload().get("username");
        String imageName = (String) request.getPayload().get("imageName");
        String imageData = (String) request.getPayload().get("imageData"); // Base64
        String caption = (String) request.getPayload().get("caption");
        List<String> tagsList = (List<String>) request.getPayload().get("tags");
        Set<String> tags = new HashSet<>(tagsList != null ? tagsList : new ArrayList<>());

        User user = Admin.allUsers.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);

        if (user == null) {
            return new Response(request.getRequestId(), 404, "User Not Found", null);
        }

        try {
            File dir = new File("storage/images");
            if (!dir.exists()) dir.mkdirs();

            String filePath = "storage/images/" + System.currentTimeMillis() + "_" + imageName;
            byte[] imageBytes = Base64.getDecoder().decode(imageData);
            Files.write(Paths.get(filePath), imageBytes);

            user.uploadImage(imageName, filePath, caption, tags);
            DatabaseManager.save();

            return new Response(request.getRequestId(), 200, "Image Uploaded Successfully", new HashMap<>());
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Upload Failed: " + e.getMessage(), null);
        }
    }

    private Response handleImageGetAll(Request request) {
        try {
            List<Map<String, Object>> imageList = new ArrayList<>();
            for (User user : Admin.allUsers) {
                for (Image img : user.getImages()) {
                    Map<String, Object> imgMap = new HashMap<>();
                    imgMap.put("id", img.getId());
                    imgMap.put("name", img.getName());
                    imgMap.put("owner", user.getUsername());
                    imgMap.put("caption", img.getCaption());
                    imgMap.put("tags", img.getTags());

                    // Gson hack to access private 'path' field without changing Phase 1 code
                    String json = gson.toJson(img);
                    Map<String, Object> temp = gson.fromJson(json, Map.class);
                    String path = (String) temp.get("path");

                    if (path != null) {
                        try {
                            byte[] bytes = Files.readAllBytes(Paths.get(path));
                            imgMap.put("imageData", Base64.getEncoder().encodeToString(bytes));
                        } catch (IOException e) {
                            imgMap.put("imageData", null);
                        }
                    }
                    imageList.add(imgMap);
                }
            }
            Map<String, Object> data = new HashMap<>();
            data.put("images", imageList);
            return new Response(request.getRequestId(), 200, "Success", data);
        } catch (Exception e) {
            return new Response(request.getRequestId(), 500, "Error: " + e.getMessage(), null);
        }
    }
}

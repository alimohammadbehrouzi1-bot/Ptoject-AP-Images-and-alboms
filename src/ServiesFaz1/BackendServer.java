package ServiesFaz1;

import com.google.gson.Gson;
import Faz1.User;
import Faz1.Admin;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;

public class BackendServer {
    private static final int PORT = 8080;

    public static void main(String[] args) {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Server is running on port " + PORT);
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
                    Response errorResponse = new Response(500, "Internal Server Error: " + e.getMessage(), null);
                    out.println(gson.toJson(errorResponse));
                }
            }
        } catch (IOException e) {
            System.err.println("Handler error: " + e.getMessage());
        } finally {
            try {
                socket.close();
            } catch (IOException e) {
                System.err.println("Close error: " + e.getMessage());
            }
        }
    }

    private Response handleRouting(Request request) {
        String route = request.getRoute();
        switch (route) {
            case "/user/login": return handleLogin(request);
            case "/user/register": return handleRegister(request);
            case "/admin/login": return handleAdminLogin(request);
            default: return new Response(404, "Route Not Found", null);
        }
    }

    private Response handleLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        for (User u : Admin.allUsers) {
            if (u.getUsername().equals(username)) {
                u.logIn(username, password);
                if (u.isBanned()) {
                    return new Response(403, "Forbidden: User is Banned", null);
                }
                return new Response(200, "Login Success", new HashMap<>());
            }
        }
        return new Response(401, "Unauthorized: Invalid credentials", null);
    }

    private Response handleAdminLogin(Request request) {
        String username = (String) request.getPayload().get("username");
        String password = (String) request.getPayload().get("password");

        try {
            Admin.Login(username, password);
            return new Response(200, "Admin Login Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(401, "Unauthorized: Invalid admin credentials", null);
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

            return new Response(200, "Registration Success", new HashMap<>());
        } catch (Exception e) {
            return new Response(400, "Registration Failed: " + e.getMessage(), null);
        }
    }
}

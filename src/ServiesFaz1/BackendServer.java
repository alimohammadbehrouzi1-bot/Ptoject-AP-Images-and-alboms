package ServiesFaz1;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

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

    public ClientHandler(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        try {
            System.out.println("New client connected: " + socket.getInetAddress());
            socket.close();
        } catch (IOException e) {
            System.err.println("Client handler error: " + e.getMessage());
        }
    }
}

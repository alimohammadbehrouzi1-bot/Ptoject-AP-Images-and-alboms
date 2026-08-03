package ServiesFaz1;

import java.util.Map;

public class Response {
    private String requestId;
    private int statusCode;
    private String message;
    private Map<String, Object> data;

    public Response(String requestId, int statusCode, String message, Map<String, Object> data) {
        this.requestId = requestId;
        this.statusCode = statusCode;
        this.message = message;
        this.data = data;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public void setStatusCode(int statusCode) {
        this.statusCode = statusCode;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Map<String, Object> getData() {
        return data;
    }

    public void setData(Map<String, Object> data) {
        this.data = data;
    }
}

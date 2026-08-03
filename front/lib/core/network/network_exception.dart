sealed class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ConnectionFailedException extends NetworkException {
  ConnectionFailedException() : super('Connection failed');
}

class ConnectionTimeoutException extends NetworkException {
  ConnectionTimeoutException() : super('Connection timeout');
}

class RequestTimeoutException extends NetworkException {
  RequestTimeoutException() : super('Request timeout');
}

class InvalidJsonException extends NetworkException {
  InvalidJsonException() : super('Invalid JSON received from server');
}

class ServerDisconnectedException extends NetworkException {
  ServerDisconnectedException() : super('Server disconnected');
}

class UnknownNetworkException extends NetworkException {
  UnknownNetworkException([String? details])
    : super(details ?? 'Unknown network error');
}

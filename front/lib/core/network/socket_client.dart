import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import '../config/server_config.dart';
import 'api_request.dart';
import 'api_response.dart';
import 'network_exception.dart';

class SocketClient {
  static final SocketClient instance = SocketClient._internal();
  factory SocketClient() => instance;
  SocketClient._internal();

  Socket? _socket;
  final Map<String, Completer<ApiResponse>> _pendingRequests = {};
  int _requestIdCounter = 0;
  
  // Shared future to handle concurrent connection attempts
  Future<void>? _connectionFuture;

  bool get isConnected => _socket != null;

  Future<void> connect() async {
    if (isConnected) return;
    
    // If a connection attempt is already in progress, wait for it
    if (_connectionFuture != null) {
      return _connectionFuture;
    }

    _connectionFuture = _doConnect();
    try {
      await _connectionFuture;
    } finally {
      _connectionFuture = null;
    }
  }

  Future<void> _doConnect() async {
    int attempts = 0;
    final delays = [1, 2, 4];

    while (attempts < 3) {
      try {
        log('Connecting to ${ServerConfig.host}:${ServerConfig.port} (Attempt ${attempts + 1})...');
        
        final Socket socketInstance = await Socket.connect(
          ServerConfig.host,
          ServerConfig.port,
          timeout: const Duration(seconds: 10),
        );

        _socket = socketInstance;

        socketInstance
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(_handleMessage, onError: _handleError, onDone: _handleDone);

        log('Connected to server.');
        return;
      } catch (e) {
        attempts++;
        log('Connection attempt $attempts failed: $e');
        if (attempts < 3) {
          await Future.delayed(Duration(seconds: delays[attempts - 1]));
        }
      }
    }
    throw ConnectionFailedException();
  }

  void _handleMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      final response = ApiResponse.fromJson(decoded);
      final requestId = response.requestId;

      if (requestId != null && _pendingRequests.containsKey(requestId)) {
        final completer = _pendingRequests.remove(requestId);
        if (completer != null) {
          completer.complete(response);
        }
      } else {
        log('Received message without matching requestId: $message');
      }
    } catch (e) {
      log('Failed to decode message: $message');
    }
  }

  void _handleError(dynamic error) {
    log('Socket error: $error');
    _cleanup(UnknownNetworkException(error.toString()));
  }

  void _handleDone() {
    log('Socket closed by server.');
    _cleanup(ServerDisconnectedException());
  }

  void _cleanup(dynamic error) {
    _socket?.destroy();
    _socket = null;

    for (var completer in _pendingRequests.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pendingRequests.clear();
  }

  Future<ApiResponse> sendRequest(ApiRequest request) async {
    // Correctly wait for connection if not connected
    if (!isConnected) {
      await connect();
    }

    final requestId = 'req_${_requestIdCounter++}';
    final requestWithId = ApiRequest(
      requestId: requestId,
      username: request.username,
      route: request.route,
      payload: request.payload,
    );

    final completer = Completer<ApiResponse>();
    _pendingRequests[requestId] = completer;

    final Socket? socket = _socket;
    if (socket == null) {
      _pendingRequests.remove(requestId);
      return ApiResponse.error("Socket connection lost unexpectedly");
    }

    try {
      socket.writeln(jsonEncode(requestWithId.toJson()));
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _pendingRequests.remove(requestId);
          throw RequestTimeoutException();
        },
      );
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _cleanup(ServerDisconnectedException());
  }
}

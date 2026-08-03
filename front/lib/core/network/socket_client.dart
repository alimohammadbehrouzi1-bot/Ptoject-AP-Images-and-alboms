import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../config/server_config.dart';
import 'api_request.dart';
import 'api_response.dart';
import 'network_exception.dart';

class SocketClient {
  static final SocketClient _instance = SocketClient._internal();
  factory SocketClient() => _instance;
  SocketClient._internal();

  Socket? _socket;

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(
        ServerConfig.host,
        ServerConfig.port,
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      throw ConnectionFailedException();
    }
  }

  Future<ApiResponse> send(ApiRequest request) async {
    if (_socket == null) await connect();

    try {
      _socket!.write(request.encode());

      // Basic implementation of receiving a response
      // In a real socket scenario, we might need a more complex listener
      final completer = Completer<ApiResponse>();

      _socket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(utf8.decode(data));
            completer.complete(ApiResponse.fromJson(decoded));
          } catch (e) {
            completer.completeError(InvalidJsonException());
          }
        },
        onError: (e) =>
            completer.completeError(UnknownNetworkException(e.toString())),
        onDone: () => _socket = null,
      );

      return completer.future;
    } catch (e) {
      throw UnknownNetworkException(e.toString());
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
  }
}

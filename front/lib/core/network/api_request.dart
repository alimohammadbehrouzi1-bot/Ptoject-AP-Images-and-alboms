import 'dart:convert';

class ApiRequest {
  final String? requestId;
  final String route;
  final Map<String, dynamic> payload;

  ApiRequest({this.requestId, required this.route, required this.payload});

  Map<String, dynamic> toJson() {
    return {
      if (requestId != null) 'requestId': requestId,
      'route': route,
      'payload': payload,
    };
  }

  String encode() {
    return '${jsonEncode(toJson())}\n';
  }

  @override
  String toString() {
    final Map<String, dynamic> safePayload = Map.from(payload);
    if (safePayload.containsKey('password')) {
      safePayload['password'] = '********';
    }
    return 'ApiRequest(requestId: $requestId, route: $route, payload: $safePayload)';
  }
}

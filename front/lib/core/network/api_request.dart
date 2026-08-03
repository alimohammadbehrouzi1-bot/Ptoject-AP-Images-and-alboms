import 'dart:convert';

class ApiRequest {
  final String route;
  final Map<String, dynamic> payload;

  ApiRequest({required this.route, required this.payload});

  Map<String, dynamic> toJson() {
    return {'route': route, 'payload': payload};
  }

  String encode() {
    return jsonEncode(toJson());
  }
}

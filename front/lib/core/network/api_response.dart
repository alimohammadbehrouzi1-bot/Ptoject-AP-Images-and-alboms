class ApiResponse {
  final int statusCode;
  final String? message;
  final dynamic data;

  ApiResponse({required this.statusCode, this.message, this.data});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      statusCode: json['statusCode'] ?? 500,
      message: json['message'],
      data: json['data'],
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(statusCode: 500, message: message);
  }
}

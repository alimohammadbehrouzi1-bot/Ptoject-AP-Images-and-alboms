class ApiResponse {
  final String? requestId;
  final int statusCode;
  final String? message;
  final dynamic data;

  ApiResponse({
    this.requestId,
    required this.statusCode,
    this.message,
    this.data,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      requestId: json['requestId'],
      statusCode: json['statusCode'] ?? 500,
      message: json['message'],
      data: json['data'],
    );
  }

  factory ApiResponse.error(String message, {String? requestId}) {
    return ApiResponse(requestId: requestId, statusCode: 500, message: message);
  }

  @override
  String toString() =>
      'ApiResponse(requestId: $requestId, statusCode: $statusCode, message: $message, data: $data)';
}

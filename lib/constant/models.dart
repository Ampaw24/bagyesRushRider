class IApiResponse {
  late bool success;
  late String message;
  dynamic data;
  late String token;

  IApiResponse(Map<String, dynamic> json) {
    this.success = json['success'] ?? false;
    this.message = json['message'] ?? '';
    this.data = json['data'];
    this.token = json['token'] ?? '';
  }
}
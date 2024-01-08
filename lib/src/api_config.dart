/// API 配置
class ApiConfig {
  /// 网关地址
  final String baseUrl;

  ///
  final String? appKey;

  ///
  final String? appSecret;

  /// 授权地址
  String get authorizationEndpoint {
    return baseUrl + '/identity/connect/token';
  }

  const ApiConfig({
    required this.baseUrl,
    this.appKey,
    this.appSecret,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      baseUrl: json['baseUrl'],
      appKey: json['appKey'],
      appSecret: json['appSecret'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['baseUrl'] = this.baseUrl;
    data['appKey'] = this.appKey;
    data['appSecret'] = this.appSecret;
    return data;
  }
}

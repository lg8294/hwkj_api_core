/// API 配置
class ApiConfig {
  /// 网关地址
  final String baseUrl;

  ///
  final String appKey;

  ///
  final String appSecret;

  /// 授权地址
  String get authorizationEndpoint {
    return baseUrl + '/identity/connect/token';
  }

  const ApiConfig({
    this.baseUrl,
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

/// 默认API配置
ApiConfig defaultApiConfig = patientApiConfigDev;

/// 患者端dev环境配置
ApiConfig patientApiConfigDev = ApiConfig(
  baseUrl: "http://192.168.1.251:30289",
  appKey: "b92dcfb9-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

/// 患者端fat环境配置
ApiConfig patientApiConfigFat = ApiConfig(
  baseUrl: "https://api.fat.kangfx.com:30561",
  appKey: "b92dcfb9-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

/// 患者端uat环境配置
ApiConfig patientApiConfigUat = ApiConfig(
  baseUrl: 'https://api-uat.kangfx.com',
  appKey: "b92dcfb9-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

/// 医生端开发环境配置
ApiConfig doctorApiConfigDev = ApiConfig(
  baseUrl: "http://192.168.1.251:30289",
  appKey: "b949e291-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

/// 医生端fat环境配置
ApiConfig doctorApiConfigFat = ApiConfig(
  baseUrl: "https://api.fat.kangfx.com:30561",
  appKey: "b949e291-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

/// 医生端uat环境配置
ApiConfig doctorApiConfigUat = ApiConfig(
  baseUrl: 'https://api-uat.kangfx.com',
  appKey: "b949e291-15b5-11ea-9583-000c29026700",
  appSecret: "secret",
);

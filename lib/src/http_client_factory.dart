import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

class HttpClientFactory {
  /// httpClient 公共配置
  static _configCommonHttpClient(Dio httpClient) {
    httpClient.options.connectTimeout = 35000;
    httpClient.options.sendTimeout = 35000;
    httpClient.options.receiveTimeout = 35000;
  }

  /// 配置 httpClient 调试模式，开发环境打开日志
  static debugForHttpClient(Dio hClient) {
    // 开发环境
    if (kDebugMode) {
      hClient.options.connectTimeout = 5000;
      hClient.options.sendTimeout = 5000;
      hClient.options.receiveTimeout = 5000;

      // 打印 Log
      hClient.interceptors.add(LogInterceptor(
        request: false,
//        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
      ));
    }
  }

  /// 生成一个使用公共 HttpClient 配置的 HttpClient，这里不包含 API 配置
  static Dio generalHttpClient() {
    var d = Dio();
    _configCommonHttpClient(d);
    return d;
  }

  /// 获取指定 API 配置的 HttpClient，如果没有传入apiConfig，使用默认API配置
  static Dio createHttpClient({ApiConfig? apiConfig}) {
    apiConfig ??= defaultApiConfig;

    var d = Dio(BaseOptions(
      baseUrl: apiConfig.baseUrl,
    ));

    _configCommonHttpClient(d);

    return d;
  }
}

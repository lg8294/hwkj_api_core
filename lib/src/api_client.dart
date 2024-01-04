import 'package:dio/dio.dart';
import 'package:hwkj_api_core/generated/json/base/json_convert_content.dart';
import 'package:hwkj_api_core/src/models/response_result_entity.dart';

import 'api_result.dart';
import 'constants.dart';
import 'models/ajax_result_entity.dart';

ValidateStatus validateStatus200 = (int? status) {
  return status == 200;
};

ValidateStatus validateStatus200_401 = (int? status) {
  return [200, 401].contains(status);
};

abstract class ApiClient {
  /// apiClient 负责调用 API
  final Dio _httpClient;

  Dio get httpClient => _httpClient;

  ApiClient(Dio httpClient) : _httpClient = httpClient {
    _httpClient.options.validateStatus = validateStatus200_401;
  }

  APIResult<T> handleError<T>(error, {StackTrace? trace}) =>
      globalHandleError(error, trace: trace);

  AjaxResultEntity parseResponseData(Response response) =>
      globalParseResponseData(response);

  static APIResult<T> globalHandleError<T>(
    error, {
    StackTrace? trace,
  }) {
    var msg;

    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.connectTimeout:
          msg = "连接超时";
          break;
        case DioErrorType.sendTimeout:
          msg = "发送数据超时";
          break;
        case DioErrorType.receiveTimeout:
          msg = "接收数据超时";
          break;
        case DioErrorType.response:
          try {
            final responseResult =
                JsonConvert.fromJsonAsT<ResponseResultEntity>(
                    error.response!.data);
            msg = responseResult.message;
          } catch (_) {
            msg = system_error_tip;
            try {
              if (error.error is Error) {
                onError?.call(error.error, (error.error as Error).stackTrace);
              } else {
                onError?.call(error, error.stackTrace);
              }
            } catch (e) {
              print(e.toString());
            }
          }
          break;
        case DioErrorType.cancel:
          msg = "请求已取消";
          break;
        case DioErrorType.other:
          msg = network_error_tip;
          try {
            if (error.error is Error) {
              onError?.call(error.error, (error.error as Error).stackTrace);
            } else {
              onError?.call(error.message, error.stackTrace);
            }
          } catch (e) {
            print(e.toString());
          }
          break;
      }
    } else if (error is Error) {
      msg = system_error_tip;
      try {
        onError?.call(error, error.stackTrace);
      } catch (e) {
        print(e.toString());
      }
    } else {
      msg = system_error_tip;
      try {
        onError?.call(error, trace);
      } catch (e) {
        print(e.toString());
      }
    }

    return APIResult<T>.failure(msg);
  }

  static AjaxResultEntity globalParseResponseData(Response response) {
    if (response.data is Map) {
      final resultMap = response.data as Map;
      // 标准数据模型
      if (resultMap['Type'] != null) {
        final r = JsonConvert.fromJsonAsT<AjaxResultEntity>(response.data);
        return r;
      }
      // 分页数据模型
      if (resultMap['Rows'] != null) {
        return AjaxResultEntity()
          ..data = response.data
          ..type = 200;
      }
    }

    if (response.data is List) {
      return AjaxResultEntity()
        ..data = response.data
        ..type = 200;
    }

    return AjaxResultEntity()
      ..data = response.data
      ..type = -1
      ..content = '无法解析数据';
  }

  /// 全局监听错误
  static void Function(dynamic e, StackTrace? stackTrace)? onError;
}

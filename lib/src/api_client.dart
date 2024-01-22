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

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          msg = "连接超时";
          break;
        case DioExceptionType.sendTimeout:
          msg = "发送数据超时";
          break;
        case DioExceptionType.receiveTimeout:
          msg = "接收数据超时";
          break;
        case DioExceptionType.cancel:
          msg = "请求已取消";
          break;
        case DioExceptionType.badResponse:
          try {
            final responseResult =
                JsonConvert.fromJsonAsT<ResponseResultEntity>(
                    error.response!.data);
            msg = responseResult.message;
          } catch (e, t) {
            print('error:$e stack:$t');
            msg = system_error_tip;
            if (error.error is Error) {
              _safelyCallOnError(error.error, error.stackTrace);
            } else {
              _safelyCallOnError(error.message, error.stackTrace);
            }
          }
          break;
        case DioExceptionType.unknown:
        case DioExceptionType.badCertificate:
        case DioExceptionType.connectionError:
          msg = network_error_tip;
          if (error.error is Error) {
            _safelyCallOnError(error.error, error.stackTrace);
          } else {
            _safelyCallOnError(error.message, error.stackTrace);
          }
          break;
      }
    } else if (error is Error) {
      msg = system_error_tip;
      _safelyCallOnError(error, trace);
    } else {
      msg = system_error_tip;
      _safelyCallOnError(error, trace);
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

  static _safelyCallOnError(dynamic e, StackTrace? stackTrace) {
    try {
      onError?.call(e, stackTrace);
    } catch (e) {
      print(e.toString());
    }
  }
}

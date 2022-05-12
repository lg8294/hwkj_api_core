import 'package:dio/dio.dart';
import 'package:hwkj_api_core/generated/json/base/json_convert_content.dart';

import 'api_result.dart';
import 'models/ajax_result_entity.dart';

ValidateStatus validateStatus200 = (int status) {
  return status == 200;
};

ValidateStatus validateStatus200_401 = (int status) {
  return [200, 401].contains(status);
};

abstract class ApiClient {
  /// apiClient 负责调用 API
  final Dio _httpClient;

  Dio get httpClient => _httpClient;

  ApiClient(Dio httpClient)
      : assert(httpClient != null),
        _httpClient = httpClient {
    _httpClient.options.validateStatus = validateStatus200_401;
  }

  APIResult<T> handleError<T>(e, {StackTrace trace}) =>
      globalHandleError(e, trace: trace);

  static APIResult<T> globalHandleError<T>(
    e, {
    StackTrace trace,
  }) {
    var msg;
    var debugMsg;

    if (e is DioError) {
      switch (e.type) {
        case DioErrorType.CONNECT_TIMEOUT:
          msg = "连接超时";
          break;
        case DioErrorType.SEND_TIMEOUT:
          msg = "发送数据超时";
          break;
        case DioErrorType.RECEIVE_TIMEOUT:
          msg = "接收数据超时";
          break;
        case DioErrorType.RESPONSE:
          msg = e.error;
          debugMsg = e.response.data.toString();
          break;
        case DioErrorType.CANCEL:
          msg = "取消";
          break;
        case DioErrorType.DEFAULT:
          msg = '未知错误';
          debugMsg = 'error:${e.error}';
          if (e.error is Error) {
            debugMsg += '\n' + 'stackTrace:${(e.error as Error).stackTrace}';
          }
          break;
      }
    } else if (e is Error) {
      msg = '未知错误';
      debugMsg = 'error:$e' + '\n' + 'stackTrace:${e.stackTrace.toString()}';
    } else {
      msg = '未知错误';
      debugMsg = 'error:$e' + '\n' + 'stackTrace:${trace?.toString()}';
    }

    return APIResult<T>.failure(msg, debugMsg);
  }

  AjaxResultEntity parseResponseData(Response response) =>
      globalParseResponseData(response);

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

    // if (response.data is String) {
    //   try {
    //     Map resultMap = {};
    //     resultMap = jsonDecode(response.data);
    //     if (resultMap['Type'] != null) {
    //       final r = JsonConvert.fromJsonAsT<AjaxResultEntity>(resultMap);
    //       return r;
    //     }
    //   } catch (e, stack) {
    //     print(e);
    //     print(stack);
    //   }
    // }

    return AjaxResultEntity()
      ..data = response.data
      ..type = -1
      ..content = '无法解析数据';
  }
}

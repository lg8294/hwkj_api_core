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

  APIResult<T> handleError<T>(e, {StackTrace? trace}) =>
      globalHandleError(e, trace: trace);

  static APIResult<T> globalHandleError<T>(
    e, {
    StackTrace? trace,
  }) {
    var msg;
    var debugMsg;

    if (e is DioError) {
      switch (e.type) {
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
                    e.response!.data)!;
            msg = responseResult.message;
            debugMsg = responseResult.developerMessage?.toString();
          } catch (_) {
            msg = system_error_tip;
            debugMsg = e.response!.data?.toString();
          }
          break;
        case DioErrorType.cancel:
          msg = "请求已取消";
          break;
        case DioErrorType.other:
          msg = network_error_tip;
          debugMsg = 'error:${e.error}';
          if (e.error is Error) {
            debugMsg += '\n' + 'stackTrace:${(e.error as Error).stackTrace}';
          }
          break;
      }
    } else if (e is Error) {
      msg = system_error_tip;
      debugMsg = 'error:$e' + '\n' + 'stackTrace:${e.stackTrace.toString()}';
    } else {
      msg = system_error_tip;
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
        final r = JsonConvert.fromJsonAsT<AjaxResultEntity>(response.data)!;
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

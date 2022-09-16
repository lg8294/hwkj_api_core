import 'dart:convert';

/// 业务层调用接口返回数据用这个包装，统一处理成功和失败
class APIResult<T> {
  final T? data;
  final String? msg;
  final String? debugMsg;
  final bool success;

  bool get failure => success != true;

  APIResult(
    this.success, {
    this.data,
    this.msg,
    this.debugMsg,
  });

  APIResult.success(this.data, {this.msg, this.debugMsg}) : success = true;

  APIResult.failure(this.msg, [this.debugMsg])
      : success = false,
        data = null;

  APIResult.failureWithRequestError([this.debugMsg])
      : success = false,
        data = null,
        msg = requestError;

  static const String requestError = '请求出错';

  @override
  String toString() {
    return '''
SUCCESS: $success,
MSG: $msg,
DEBUG_MSG: $debugMsg,
DATA: ${jsonEncode(data)}
    ''';
  }
}

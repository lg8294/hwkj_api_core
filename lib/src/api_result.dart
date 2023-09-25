import 'dart:convert';

/// 业务层调用接口返回数据用这个包装，统一处理成功和失败
class APIResult<T> {
  final T? data;
  final String? msg;
  final String? debugMsg;
  final int? timestamp;
  final bool success;

  bool get failure => success != true;

  APIResult(
    this.success, {
    this.data,
    this.msg,
    this.debugMsg,
    this.timestamp,
  });

  APIResult.success(this.data, {this.msg, this.debugMsg, this.timestamp})
      : success = true;

  APIResult.failure(this.msg, [this.debugMsg])
      : success = false,
        data = null,
        timestamp = null;

  APIResult.failureWithRequestError([this.debugMsg])
      : success = false,
        data = null,
        msg = requestError,
        timestamp = null;

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

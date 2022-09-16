import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';

abstract class CredentialStorage {
  Credentials? get credentials;

  set credentials(Credentials? value) {}
}

abstract class App {
  /// 设置登录状态失效
  setLoginStateInvalid();
}

class AuthenticationHttpClientDelegate {
  final Function lock;
  final Function unlock;
  final Function onRefreshTokenFailure;
  final Dio currentHttpClient;

  const AuthenticationHttpClientDelegate({
    required this.lock,
    required this.unlock,
    required this.onRefreshTokenFailure,
    required this.currentHttpClient,
  });
}

class AuthInterceptor extends QueuedInterceptor {
  Credentials _credentials;
  AuthInterceptor(this._credentials);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_credentials.isExpired) {
      if (_credentials.canRefresh) {
        _credentials = await _credentials.refresh();
      } else {
        // return _currentDio.reject("登录信息过期，请重新登录");
        return handler.reject(
          DioError(
            requestOptions: options,
            error: '登录信息过期，请重新登录',
          ),
        );
      }
    }

    final token = _credentials.accessToken;
    final tokenType = "Bearer";
    options.headers.addAll({"Authorization": "$tokenType $token"});
    handler.next(options);
  }
}

class UserAuthInterceptor extends QueuedInterceptor {
  final CredentialStorage _credentialStorage;
  final ApiConfig _apiConfig;
  final App? _app;
  final AuthenticationHttpClientDelegate httpClientDelegate;

  final int maxRetryCount;
  int _retryCount = 0;

  UserAuthInterceptor(
    this._credentialStorage,
    this._apiConfig,
    this.httpClientDelegate, {
    this.maxRetryCount = 1,
    App? app,
  }) : _app = app;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Future onRequest(RequestOptions options) async {

    if (_credentialStorage.credentials == null) {
      _app?.setLoginStateInvalid();
      return handler.reject(DioError(requestOptions: options, error: '未登录'));
    }
    if (_credentialStorage.credentials!.isExpired) {
      httpClientDelegate.lock.call();
      if (_credentialStorage.credentials!.canRefresh) {
        Credentials? credentials;
        try {
          credentials = await _credentialStorage.credentials!.refresh(
            identifier: _apiConfig.appKey,
            secret: _apiConfig.appSecret,
          );
        } catch (e, trace) {
          print(e);
          print(trace);
        }
        if (credentials != null) {
          _credentialStorage.credentials = credentials;
          httpClientDelegate.unlock.call();
        } else {
          httpClientDelegate.onRefreshTokenFailure.call();
          httpClientDelegate.unlock.call();
          _app?.setLoginStateInvalid();
          throw '登录信息已失效，请重新登录';
        }
      } else {
        httpClientDelegate.onRefreshTokenFailure.call();
        httpClientDelegate.unlock.call();
        _app?.setLoginStateInvalid();
        throw '登录信息已失效，请重新登录';
      }
    }

    final token = _credentialStorage.credentials!.accessToken;
    final tokenType = "Bearer";
    options.headers.addAll({"Authorization": "$tokenType $token"});
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401) {
      if (_retryCount >= maxRetryCount) {
        _retryCount = 0;
        _app?.setLoginStateInvalid();
        return handler.reject(DioError(
          requestOptions: response.requestOptions,
          error: '登录信息已失效，请重新登录',
        ));
      }

      _retryCount++;
      if (_credentialStorage.credentials!.canRefresh) {
        httpClientDelegate.lock.call();
        Credentials? credential;
        try {
          credential = await _credentialStorage.credentials!.refresh(
            identifier: _apiConfig.appKey,
            secret: _apiConfig.appSecret,
          );
        } catch (e, trace) {
          debugPrintStack(stackTrace: trace, label: '$e');
        }

        if (credential != null) {
          _credentialStorage.credentials = credential;
          httpClientDelegate.unlock.call();

          /// 重新发送请求
          final requestOption = response.requestOptions;
          final r = await httpClientDelegate.currentHttpClient.request(
            requestOption.path,
            data: requestOption.data,
            cancelToken: requestOption.cancelToken,
            options: Options(method: requestOption.method),
            onSendProgress: requestOption.onSendProgress,
            onReceiveProgress: requestOption.onReceiveProgress,
          );

          return handler.resolve(r);
        } else {
          httpClientDelegate.onRefreshTokenFailure.call();
          httpClientDelegate.unlock.call();
          _app?.setLoginStateInvalid();
          return handler.reject(DioError(
            requestOptions: response.requestOptions,
            error: '登录信息已失效，请重新登录',
          ));
        }
      } else {
        httpClientDelegate.onRefreshTokenFailure.call();
        httpClientDelegate.unlock.call();
        _app?.setLoginStateInvalid();
        return handler.reject(DioError(
          requestOptions: response.requestOptions,
          error: '登录信息已失效，请重新登录',
        ));
      }
    }

    _retryCount = 0;
    super.onResponse(response, handler);
  }
}

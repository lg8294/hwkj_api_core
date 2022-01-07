import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';
import 'package:oauth2/oauth2.dart';

abstract class CredentialStorage {
  Credentials get credentials;

  set credentials(Credentials value) {}
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
    @required this.lock,
    @required this.unlock,
    @required this.onRefreshTokenFailure,
    @required this.currentHttpClient,
  });
}

class AuthInterceptor extends Interceptor {
  Dio _currentDio;
  bool _locked = false;
  Credentials _credentials;
  AuthInterceptor(this._credentials, {Dio dio}) : _currentDio = dio;

  @override
  Future onRequest(RequestOptions options) async {
    if (_credentials.isExpired) {
      _currentDio.lock();
      _locked = true;
      if (_credentials.canRefresh) {
        _credentials = await _credentials.refresh();
      } else {
        _currentDio.clear();
        return _currentDio.reject("登录信息过期，请重新登录");
      }
    }

    final token = _credentials.accessToken;
    final tokenType = "Bearer";
    options.headers.addAll({"Authorization": "$tokenType $token"});

    if (_locked) {
      _currentDio.unlock();
      _locked = false;
    }
    return options;
  }
}

class UserAuthInterceptor extends Interceptor {
  final CredentialStorage _credentialStorage;
  final ApiConfig _apiConfig;
  final App _app;
  final AuthenticationHttpClientDelegate httpClientDelegate;

  final int maxRetryCount;
  int _retryCount = 0;

  UserAuthInterceptor(
    this._credentialStorage,
    this._apiConfig,
    this.httpClientDelegate, {
    this.maxRetryCount = 1,
    App app,
  })  : assert(_credentialStorage != null),
        assert(_apiConfig != null),
        assert(httpClientDelegate != null),
        assert(maxRetryCount != null),
        _app = app;

  @override
  Future onRequest(RequestOptions options) async {
    if (_credentialStorage.credentials == null) {
      _app?.setLoginStateInvalid();
      throw '请登录';
    }
    if (_credentialStorage.credentials.isExpired) {
      httpClientDelegate.lock.call();
      if (_credentialStorage.credentials.canRefresh) {
        Credentials credentials;
        try {
          credentials = await _credentialStorage.credentials.refresh(
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

    final token = _credentialStorage.credentials.accessToken;
    final tokenType = "Bearer";
    options.headers.addAll({"Authorization": "$tokenType $token"});

    return options;
  }

  @override
  Future onResponse(Response response) async {
    if (response.statusCode == 401) {
      print('未授权（401）');

      if (_retryCount >= maxRetryCount) {
        _retryCount = 0;
        _app?.setLoginStateInvalid();
        throw '登录信息已失效，请重新登录';
      }

      _retryCount++;
      if (_credentialStorage.credentials.canRefresh) {
        httpClientDelegate.lock.call();
        Credentials credential;
        try {
          credential = await _credentialStorage.credentials.refresh(
            identifier: _apiConfig.appKey,
            secret: _apiConfig.appSecret,
          );
        } catch (e, trace) {
          print(e);
          print(trace);
        }

        if (credential != null) {
          _credentialStorage.credentials = credential;
          httpClientDelegate.unlock.call();

          /// 重新发送请求
          final requestOption = response.request;
          return httpClientDelegate.currentHttpClient.request(
            requestOption.path,
            data: requestOption.data,
            cancelToken: requestOption.cancelToken,
            options: requestOption,
            onSendProgress: requestOption.onSendProgress,
            onReceiveProgress: requestOption.onReceiveProgress,
          );
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

    _retryCount = 0;
    return super.onResponse(response);
  }
}

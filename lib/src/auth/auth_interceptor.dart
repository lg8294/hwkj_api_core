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
  final Dio _currentDio;
  final CredentialStorage _credentialStorage;
  final ApiConfig _apiConfig;
  final App _app;

  final int maxRetryCount;
  int _retryCount = 0;

  UserAuthInterceptor(
    this._credentialStorage,
    this._apiConfig, {
    @required Dio currentDio,
    this.maxRetryCount = 3,
    App app,
  })  : assert(_credentialStorage != null),
        assert(_apiConfig != null),
        assert(currentDio != null),
        assert(maxRetryCount != null),
        _currentDio = currentDio,
        _app = app;

  @override
  Future onRequest(RequestOptions options) async {
    if (_credentialStorage.credentials == null) {
      _app?.setLoginStateInvalid();
      return _currentDio.reject("登录失效，请重新登录");
    }
    if (_credentialStorage.credentials.isExpired) {
      _currentDio.lock();
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
          _currentDio.unlock();
        } else {
          _currentDio.clear();
          _currentDio.unlock();
          _app?.setLoginStateInvalid();
          return _currentDio.reject("登录失效，请重新登录");
        }
      } else {
        _currentDio.clear();
        _currentDio.unlock();
        _app?.setLoginStateInvalid();
        return _currentDio.reject("登录过期，请重新登录");
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
      print('无权限，需要刷新token');

      if (_retryCount >= maxRetryCount) {
        _retryCount = 0;
        _app?.setLoginStateInvalid();
        return _currentDio.reject("token过期，请重新登录");
      }

      _retryCount++;
      if (_credentialStorage.credentials.canRefresh) {
        _currentDio.lock();
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
          _currentDio.unlock();

          /// 重新发送请求
          final requestOption = response.request;
          return _currentDio.request(
            requestOption.path,
            data: requestOption.data,
            cancelToken: requestOption.cancelToken,
            options: requestOption,
            onSendProgress: requestOption.onSendProgress,
            onReceiveProgress: requestOption.onReceiveProgress,
          );
        } else {
          _currentDio.clear();
          _currentDio.unlock();
          _app?.setLoginStateInvalid();
          return _currentDio.reject("登录失效，请重新登录");
        }
      } else {
        _currentDio.clear();
        _currentDio.unlock();
        _app?.setLoginStateInvalid();
        return _currentDio.reject("登录过期，请重新登录");
      }
    }

    _retryCount = 0;
    return super.onResponse(response);
  }
}

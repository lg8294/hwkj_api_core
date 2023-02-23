import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';

abstract class CredentialStorage {
  Credentials? get credentials;

  set credentials(Credentials? value) {}
}

abstract class App {
  /// 设置登录状态失效
  void invalidateLoginState();
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
  final int maxRetryCount;
  int _retryCount = 0;

  UserAuthInterceptor(
    this._credentialStorage,
    this._apiConfig, {
    this.maxRetryCount = 1,
    App? app,
  }) : _app = app;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Future onRequest(RequestOptions options) async {

    if (_credentialStorage.credentials == null) {
      _app?.invalidateLoginState();
      return handler.reject(DioError(requestOptions: options, error: '未登录'));
    }
    if (_credentialStorage.credentials!.isExpired) {
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
        } else {
          _app?.invalidateLoginState();
          throw '登录信息已失效，请重新登录';
        }
      } else {
        _app?.invalidateLoginState();
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
        _app?.invalidateLoginState();
        return handler.reject(DioError(
          requestOptions: response.requestOptions,
          error: '登录信息已失效，请重新登录',
        ));
      }

      _retryCount++;
      if (_credentialStorage.credentials!.canRefresh) {
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

          // 重新发送请求
          try {
            final requestOption = response.requestOptions;

            final r = await Dio().fetch(requestOption);

            return handler.resolve(r);
          } catch (e, trace) {
            log('重新发送请求出错', name: 'hwkj_api_core', error: e, stackTrace: trace);
            return handler.resolve(response);
          }
        } else {
          _app?.invalidateLoginState();
          return handler.reject(DioError(
            requestOptions: response.requestOptions,
            error: '登录信息已失效，请重新登录',
          ));
        }
      } else {
        _app?.invalidateLoginState();
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

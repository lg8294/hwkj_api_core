import 'dart:async';
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
    // 如果凭证不存在，返回 "未登录"
    if (_credentialStorage.credentials == null) {
      Timer.run(() {
        _app?.invalidateLoginState();
      });
      return handler.reject(DioError(requestOptions: options, error: '未登录'));
    }

    // 如果凭证过期，刷新凭证
    if (_credentialStorage.credentials!.isExpired) {
      Credentials credentials;
      try {
        credentials = await _credentialStorage.credentials!.refresh(
          identifier: _apiConfig.appKey,
          secret: _apiConfig.appSecret,
        );
      } catch (e, trace) {
        debugPrintStack(stackTrace: trace, label: '$e');
        Timer.run(() {
          _app?.invalidateLoginState();
        });
        throw '登录信息已失效，请重新登录';
      }
      _credentialStorage.credentials = credentials;
    }

    final token = _credentialStorage.credentials!.accessToken;
    final tokenType = "Bearer";
    options.headers.addAll({"Authorization": "$tokenType $token"});
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode != 401) {
      _retryCount = 0;
      super.onResponse(response, handler);
      return;
    }

    if (_retryCount >= maxRetryCount) {
      _retryCount = 0;
      Timer.run(() {
        _app?.invalidateLoginState();
      });
      _handle401Response(handler, response);
      return;
    }

    if (!(_credentialStorage.credentials?.canRefresh ?? false)) {
      _retryCount = 0;
      Timer.run(() {
        _app?.invalidateLoginState();
      });
      _handle401Response(handler, response);
      return;
    }

    _retryCount++;

    Credentials credential;
    try {
      credential = await _credentialStorage.credentials!.refresh(
        identifier: _apiConfig.appKey,
        secret: _apiConfig.appSecret,
      );
    } catch (e, trace) {
      debugPrintStack(stackTrace: trace, label: '$e');
      _retryCount++;
      Timer.run(() {
        _app?.invalidateLoginState();
      });
      _handle401Response(handler, response);
      return;
    }

    _credentialStorage.credentials = credential;

    // 重新发送请求
    try {
      final requestOption = response.requestOptions;

      final r = await Dio().fetch(requestOption);

      if (r.statusCode == 401) {
        _retryCount++;
        Timer.run(() {
          _app?.invalidateLoginState();
        });
        _handle401Response(handler, response);
        return;
      } else {
        handler.resolve(r);
        return;
      }
    } catch (e, trace) {
      log('重新发送请求出错', name: 'hwkj_api_core', error: e, stackTrace: trace);
      _retryCount = 0;
      Timer.run(() {
        _app?.invalidateLoginState();
      });
      _handle401Response(handler, response);
      return;
    }
  }

  void _handle401Response(
    ResponseInterceptorHandler handler,
    Response<dynamic> response,
  ) {
    return handler.reject(DioError(
      requestOptions: response.requestOptions,
      error: '登录信息已失效，请重新登录',
    ));
  }
}

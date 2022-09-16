import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';
import 'package:oauth_dio/oauth_dio.dart';

void main() {
  final userName = '15196614938';
  final password = 'admin123';

  test('oauth2 auth demo', () async {
    setupLgTestHttpProxy();

    final ApiConfig apiConfig = patientApiConfigFat;
    final authClient = await resourceOwnerPasswordGrant(
      Uri.parse(apiConfig.authorizationEndpoint),
      userName,
      password,
      identifier: apiConfig.appKey,
      secret: apiConfig.appSecret,
    );

    print(authClient.credentials.toJson());
    expect(authClient, isNotNull);

    final client = HttpClientFactory.createHttpClient();
    client.interceptors..add(AuthInterceptor(authClient.credentials));
    HttpClientFactory.debugForHttpClient(client);

    authClient.close();
  });

  test('authApi auth demo', () async {
    setupLgTestHttpProxy();

    final authHttpClient = Dio();
    HttpClientFactory.debugForHttpClient(authHttpClient);

    ApiConfig apiConfig = patientApiConfigFat;

    OAuth oauth = AuthApi.getOAuth(
      client: authHttpClient,
      config: apiConfig,
      oAuthStorage: OAuthMemoryStorage(),
    );
    await oauth.requestToken(PasswordGrant(
      username: userName,
      password: password,
      scope: [],
    ));

    final httpClient = HttpClientFactory.createHttpClient(apiConfig: apiConfig);
    httpClient.interceptors.add(MyBearerInterceptor(oauth));
    HttpClientFactory.debugForHttpClient(httpClient);
  });

  test('测试 MyOAuthToken', () async {
    setupLgTestHttpProxy();

    final authHttpClient = Dio();
    HttpClientFactory.debugForHttpClient(authHttpClient);

    ApiConfig apiConfig = patientApiConfigFat;

    OAuth oauth = AuthApi.getOAuth(
      client: authHttpClient,
      config: apiConfig,
      oAuthStorage: OAuthMemoryStorage(),
    );
    final authToken = await oauth.requestToken(PasswordGrant(
      username: userName,
      password: password,
      scope: [],
    ));

    /// MyOAuthToken 序列化和反序列化
    MyOAuthToken mainToken = authToken as MyOAuthToken;
    final json = jsonEncode(authToken);
    final _token = MyOAuthToken.fromJson(jsonDecode(json));
    expect(_token.accessToken, equals(mainToken.accessToken));
    expect(_token.refreshToken, equals(mainToken.refreshToken));
    expect(_token.idToken, equals(mainToken.idToken));
    expect(_token.tokenType, equals(mainToken.tokenType));
    expect(_token.expiresDateTime, equals(mainToken.expiresDateTime));
    expect(_token.expiresIn, equals(mainToken.expiresIn));
    expect(_token.scope, equals(mainToken.scope));
  });
}

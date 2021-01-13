import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';
import 'package:hwkj_api_core/src/auth/auth_api.dart';
import 'package:oauth2/oauth2.dart';
import 'package:oauth_dio/oauth_dio.dart';

void main() {
  final userName = '15196614938';
  final password = 'admin12';
  MyOAuthToken mainToken;

  group("测试token", () {
    test('获取 token', () async {
      try {
        OAuthToken authToken =
            await AuthApi.getOAuth().requestToken(PasswordGrant(
          username: userName,
          password: password,
        ));
        expect(authToken, isNotNull);
        print(authToken);
        mainToken = authToken;
      } catch (e) {
        fail("=============== 发生异常 =============== \n$e");
      }
    });

    test('MyOAuthToken 序列化和反序列化', () {
      final json = jsonEncode(mainToken);
      final _token = MyOAuthToken.fromJson(jsonDecode(json));
      expect(_token.accessToken, equals(mainToken.accessToken));
      expect(_token.refreshToken, equals(mainToken.refreshToken));
      expect(_token.idToken, equals(mainToken.idToken));
      expect(_token.tokenType, equals(mainToken.tokenType));
      expect(_token.expiresDateTime, equals(mainToken.expiresDateTime));
      expect(_token.expiresIn, equals(mainToken.expiresIn));
      expect(_token.scope, equals(mainToken.scope));
    });
  });

  setUp(() {
    print('setUp');
  });
  tearDown(() {
    print('tearDown');
  });
  setUpAll(() {
    print('setUpAll');
  });
  tearDownAll(() {
    print('tearDownAll');
  });

  test('账号密码授权', () async {
    final apiConfig = patientApiConfigFat;
    try {
      final client = await resourceOwnerPasswordGrant(
        Uri.parse(apiConfig.authorizationEndpoint),
        '15196614938',
        'admin123',
      );
    } catch (e) {
      print('发生异常');
      print(e);
    }
  });
}

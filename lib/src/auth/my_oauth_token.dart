import 'package:dio/dio.dart';
import 'package:oauth_dio/oauth_dio.dart';

class MyOAuthToken extends OAuthToken {
  final String? idToken;
  final int? expiresIn;
  final String? tokenType;
  final String? scope;

  final DateTime? expiresDateTime;

  MyOAuthToken({
    String? accessToken,
    String? refreshToken,
    this.idToken,
    this.expiresIn,
    this.expiresDateTime,
    this.tokenType,
    this.scope,
  }) : super(accessToken: accessToken, refreshToken: refreshToken);

  MyOAuthToken.fromJson(json)
      : this(
          accessToken: json['access_token'],
          refreshToken: json['refresh_token'],
          idToken: json['id_token'],
          expiresIn: json['expires_in'],
          tokenType: json['token_type'],
          scope: json['scope'],
          expiresDateTime: json['expiresDateTime'] != null
              ? DateTime.parse(json['expiresDateTime'])
              : DateTime.now()
                  .add(Duration(seconds: json['expires_in'] ?? 3600)),
        );
  toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['access_token'] = this.accessToken;
    data['refresh_token'] = this.refreshToken;
    data['expires_in'] = this.expiresIn;
    data['token_type'] = this.tokenType;
    data['scope'] = this.scope;
    data['id_token'] = this.idToken;
    data['expiresDateTime'] = this.expiresDateTime.toString();
    return data;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

OAuthTokenExtractor defaultMyOAuthTokenExtractor = (Response response) {
  final token = MyOAuthToken.fromJson(response.data);
  return token;
};

OAuthTokenValidator defaultMyOAuthTokenValidator = (OAuthToken token) async {
  if (token is MyOAuthToken) {
//    return true;
    if (token.expiresDateTime!.isAfter(DateTime.now())) {
      return true;
    }
  }
  return false;
};

// Dio Interceptor for Bearer AccessToken
class MyBearerInterceptor extends Interceptor {
  OAuth oauth;

  MyBearerInterceptor(this.oauth);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await oauth.fetchOrRefreshAccessToken();
    if (token is MyOAuthToken) {
      options.headers
          .addAll({"Authorization": "${token.tokenType} ${token.accessToken}"});
    }

    handler.next(options);
  }
}

import 'package:dio/dio.dart';
import 'package:hwkj_api_core/hwkj_api_core.dart';
import 'package:oauth_dio/oauth_dio.dart' hide BearerInterceptor;

import '../api_config.dart';
import 'my_oauth_token.dart';

export 'my_oauth_token.dart';

class AuthApi {
  static OAuth getOAuth({
    ApiConfig config,
    OAuthStorage oAuthStorage,
    Dio client,
  }) {
    config ??= defaultApiConfig;

    var authorizationEndpoint;
    var identifier;
    var secret;
    final path = '/identity/connect/token';

    authorizationEndpoint = Uri.parse("${config.baseUrl}$path");
    identifier = config.appKey;
    secret = config.appSecret;

//      var client = await oauth2.resourceOwnerPasswordGrant(
//        authorizationEndpoint,
//        userName,
//        password,
//        identifier: identifier,
//        secret: secret,
////        basicAuth: false,
//      );
//      final oauthToken = client.credentials;

    final oauth = OAuth(
      dio: client ?? HttpClientFactory.generalHttpClient(),
      storage: oAuthStorage,
      tokenUrl: authorizationEndpoint.toString(),
      clientId: identifier,
      clientSecret: secret,
      validator: defaultMyOAuthTokenValidator,
      extractor: defaultMyOAuthTokenExtractor,
    );
    return oauth;
  }
}

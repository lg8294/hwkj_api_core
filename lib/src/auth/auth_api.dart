import 'package:hwkj_api_core/hwkj_api_core.dart';
import 'package:oauth_dio/oauth_dio.dart' hide BearerInterceptor;

export 'my_oauth_token.dart';

class AuthApi {
  static OAuth getOAuth({
    required ApiConfig config,
    required OAuthStorage oAuthStorage,
    required Dio client,
  }) {
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
      dio: client,
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

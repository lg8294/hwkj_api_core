import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:oauth2/oauth2.dart';

// oauth2/utils.dart
String _basicAuthHeader(String identifier, String secret) {
  var userPass = Uri.encodeFull(identifier) + ':' + Uri.encodeFull(secret);
  return 'Basic ' + base64Encode(ascii.encode(userPass));
}

// oauth2/parameters.dart

/// The type of a callback that parses parameters from an HTTP response.
typedef _GetParameters = Map<String, dynamic> Function(
    MediaType contentType, String body);

/// Parses parameters from a response with a JSON body, as per the [OAuth2
/// spec][].
///
/// [OAuth2 spec]: https://tools.ietf.org/html/rfc6749#section-5.1
Map<String, dynamic> _parseJsonParameters(MediaType contentType, String body) {
  // The spec requires a content-type of application/json, but some endpoints
  // (e.g. Dropbox) serve it as text/javascript instead.
  if (contentType == null ||
      (contentType.mimeType != 'application/json' &&
          contentType.mimeType != 'text/javascript')) {
    throw FormatException(
        'Content-Type was "$contentType", expected "application/json"');
  }

  var untypedParameters = jsonDecode(body);
  if (untypedParameters is Map<String, dynamic>) {
    return untypedParameters;
  }

  throw FormatException('Parameters must be a map, was "$untypedParameters"');
}

// oauth2/handle_access_token_response.dart
const _expirationGrace = Duration(seconds: 10);

Credentials _handleAccessTokenResponse(
    http.Response response,
    Uri tokenEndpoint,
    DateTime startTime,
    List<String> scopes,
    String delimiter,
    {Map<String, dynamic> Function(MediaType contentType, String body)
        getParameters}) {
  getParameters ??= _parseJsonParameters;

  try {
    if (response.statusCode != 200) {
      _handleErrorResponse(response, tokenEndpoint, getParameters);
    }

    var contentTypeString = response.headers['content-type'];
    if (contentTypeString == null) {
      throw FormatException('Missing Content-Type string.');
    }

    var parameters =
        getParameters(MediaType.parse(contentTypeString), response.body);

    for (var requiredParameter in ['access_token', 'token_type']) {
      if (!parameters.containsKey(requiredParameter)) {
        throw FormatException(
            'did not contain required parameter "$requiredParameter"');
      } else if (parameters[requiredParameter] is! String) {
        throw FormatException(
            'required parameter "$requiredParameter" was not a string, was '
            '"${parameters[requiredParameter]}"');
      }
    }

    // TODO(nweiz): support the "mac" token type
    // (http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-01)
    if (parameters['token_type'].toLowerCase() != 'bearer') {
      throw FormatException(
          '"$tokenEndpoint": unknown token type "${parameters['token_type']}"');
    }

    var expiresIn = parameters['expires_in'];
    if (expiresIn != null && expiresIn is! int) {
      throw FormatException(
          'parameter "expires_in" was not an int, was "$expiresIn"');
    }

    for (var name in ['refresh_token', 'id_token', 'scope']) {
      var value = parameters[name];
      if (value != null && value is! String) {
        throw FormatException(
            'parameter "$name" was not a string, was "$value"');
      }
    }

    var scope = parameters['scope'] as String;
    if (scope != null) scopes = scope.split(delimiter);

    var expiration = expiresIn == null
        ? null
        : startTime.add(Duration(seconds: expiresIn) - _expirationGrace);

    return Credentials(parameters['access_token'],
        refreshToken: parameters['refresh_token'],
        idToken: parameters['id_token'],
        tokenEndpoint: tokenEndpoint,
        scopes: scopes,
        expiration: expiration);
  } on FormatException catch (e) {
    throw FormatException('Invalid OAuth response for "$tokenEndpoint": '
        '${e.message}.\n\n${response.body}');
  }
}

/// Throws the appropriate exception for an error response from the
/// authorization server.
void _handleErrorResponse(
    http.Response response, Uri tokenEndpoint, _GetParameters getParameters) {
  // OAuth2 mandates a 400 or 401 response code for access token error
  // responses. If it's not a 400 reponse, the server is either broken or
  // off-spec.
  if (response.statusCode != 400 && response.statusCode != 401) {
    var reason = '';
    if (response.reasonPhrase != null && response.reasonPhrase.isNotEmpty) {
      ' ${response.reasonPhrase}';
    }
    throw FormatException('OAuth request for "$tokenEndpoint" failed '
        'with status ${response.statusCode}$reason.\n\n${response.body}');
  }

  var contentTypeString = response.headers['content-type'];
  var contentType =
      contentTypeString == null ? null : MediaType.parse(contentTypeString);

  var parameters = getParameters(contentType, response.body);

  if (!parameters.containsKey('error')) {
    throw FormatException('did not contain required parameter "error"');
  } else if (parameters['error'] is! String) {
    throw FormatException('required parameter "error" was not a string, was '
        '"${parameters["error"]}"');
  }

  for (var name in ['error_description', 'error_uri']) {
    var value = parameters[name];

    if (value != null && value is! String) {
      throw FormatException('parameter "$name" was not a string, was "$value"');
    }
  }

  var description = parameters['error_description'];
  var uriString = parameters['error_uri'];
  var uri = uriString == null ? null : Uri.parse(uriString);
  throw AuthorizationException(parameters['error'], description, uri);
}

Future<Client> resourceOwnerVerifyCodeGrant(Uri authorizationEndpoint,
    String phone, String verifyCode, String verifyCodeId,
    {String identifier,
    String secret,
    Iterable<String> scopes,
    bool basicAuth = true,
    CredentialsRefreshedCallback onCredentialsRefreshed,
    http.Client httpClient,
    String delimiter,
    Map<String, dynamic> Function(MediaType contentType, String body)
        getParameters}) async {
  delimiter ??= ' ';
  var startTime = DateTime.now();

  var body = {
    'grant_type': 'password',
    'username': phone,
    'password': verifyCode,
    'verifyCodeId': verifyCodeId,
  };

  var headers = <String, String>{};

  if (identifier != null) {
    if (basicAuth) {
      headers['Authorization'] = _basicAuthHeader(identifier, secret);
    } else {
      body['client_id'] = identifier;
      if (secret != null) body['client_secret'] = secret;
    }
  }

  if (scopes != null && scopes.isNotEmpty) {
    body['scope'] = scopes.join(delimiter);
  }

  httpClient ??= http.Client();
  var response = await httpClient.post(authorizationEndpoint,
      headers: headers, body: body);

  var credentials = await _handleAccessTokenResponse(
      response, authorizationEndpoint, startTime, scopes, delimiter,
      getParameters: getParameters);
  return Client(credentials,
      identifier: identifier,
      secret: secret,
      httpClient: httpClient,
      onCredentialsRefreshed: onCredentialsRefreshed);
}

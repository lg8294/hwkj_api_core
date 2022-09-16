import 'dart:io';

import 'package:flutter/foundation.dart';

@visibleForTesting
void setupLgTestHttpProxy() {
  LGHttpProxy.setupGlobalHttpProxy('127.0.0.1', '8888');
}

class LGHttpProxy extends HttpOverrides {
  String? host;
  String? port;

  LGHttpProxy(this.host, this.port);

  static setupGlobalHttpProxy(String? host, String? port) {
    HttpOverrides.global = LGHttpProxy(host, port);
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    var client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      print('证书 $cert , 地址:$host:$port');
      return true;
    };
    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    if (host == null) {
      return super.findProxyFromEnvironment(url, environment);
    }

    if (environment == null) {
      environment = {};
    }

    if (port != null) {
      environment['http_proxy'] = '$host:$port';
      environment['https_proxy'] = '$host:$port';
    } else {
      environment['http_proxy'] = '$host:8888';
      environment['https_proxy'] = '$host:8888';
    }

    print('通过环境 $environment 获取访问 $url 的代理');
    return super.findProxyFromEnvironment(url, environment);
  }
}

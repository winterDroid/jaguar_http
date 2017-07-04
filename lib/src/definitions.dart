library jaguar_http.definitions;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

typedef JaguarRequest RequestInterceptor(JaguarRequest request);
typedef JaguarResponse ResponseInterceptor(JaguarResponse response);

class JaguarHttp {
  final String name;

  const JaguarHttp({this.name});
}

class Req {
  final String method;
  final String url;

  const Req(this.method, this.url);
}

class Param {
  final String name;

  const Param({this.name});
}

class Body {
  const Body();
}

class Get extends Req {
  const Get(String url) : super("GET", url);
}

class Post extends Req {
  const Post(String url) : super("POST", url);
}

class Put extends Req {
  const Put(String url) : super("PUT", url);
}

class Delete extends Req {
  const Delete(String url) : super("DELETE", url);
}

class Patch extends Req {
  const Patch(String url) : super("PATCH", url);
}

class JaguarResponse<T> {
  final T body;
  final http.Response rawResponse;

  JaguarResponse(this.body, this.rawResponse);

  JaguarResponse.error(this.rawResponse) : body = null;

  bool isSuccessful() =>
      rawResponse.statusCode >= 200 && rawResponse.statusCode < 300;

  String toString() => "JaguarResponse<($body)";
}

class JaguarRequest<T> {
  T body;
  String method;
  String url;
  Map<String, String> headers;

  JaguarRequest({this.method, this.headers, this.body, this.url});

  Future<http.Response> send(http.Client client) async {
    switch (method) {
      case "POST":
        return client.post(url, headers: headers, body: body);
      case "PUT":
        return client.put(url, headers: headers, body: body);
      case "PATCH":
        return client.patch(url, headers: headers, body: body);
      case "DELETE":
        return client.delete(url, headers: headers);
      default:
        return client.get(url, headers: headers);
    }
  }
}

abstract class JaguarInterceptors {
  final List<RequestInterceptor> requestInterceptors = [];
  final List<ResponseInterceptor> responseInterceptors = [];

  @protected
  JaguarRequest interceptRequest(JaguarRequest request) {
    requestInterceptors.forEach((requestInterceptor) {
      request = requestInterceptor(request);
    });
    return request;
  }

  @protected
  JaguarResponse interceptResponse(JaguarResponse response) {
    responseInterceptors.forEach((responseInterceptor) {
      response = responseInterceptor(response);
    });
    return response;
  }
}

library jaguar_http.definitions;

import 'dart:async';
import 'package:jaguar_serializer/jaguar_serializer.dart';
import 'package:jaguar_client/jaguar_client.dart';
import 'package:meta/meta.dart';

typedef FutureOr<JaguarRequest> RequestInterceptor(JaguarRequest request);
typedef FutureOr<JaguarResponse> ResponseInterceptor(JaguarResponse response);

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

  const Param([this.name]);
}

class QueryParam {
  final String name;

  const QueryParam([this.name]);
}

class Body {
  const Body();
}

class Get extends Req {
  const Get([String url = "/"]) : super("GET", url);
}

class Post extends Req {
  const Post([String url = "/"]) : super("POST", url);
}

class Put extends Req {
  const Put([String url = "/"]) : super("PUT", url);
}

class Delete extends Req {
  const Delete([String url = "/"]) : super("DELETE", url);
}

class Patch extends Req {
  const Patch([String url = "/"]) : super("PATCH", url);
}

class JaguarResponse<T> {
  final T body;
  final JsonResponse rawResponse;

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

  Future<JsonResponse> send(JsonClient client) async {
    switch (method) {
      case "POST":
        return client.post(url, headers: headers, body: body);
      case "PUT":
        return client.put(url, headers: headers, body: body);
      case "PATCH":
        throw new Exception("Not implemented yet");
//        return client.patch(url, headers: headers, body: body);
      case "DELETE":
        return client.delete(url, headers: headers);
      default:
        return client.get(url, headers: headers);
    }
  }
}

abstract class JaguarApiDefinition {
  final String baseUrl;
  final Map headers;
  final JsonClient client;
  final SerializerRepo serializers;

  JaguarApiDefinition(
      this.client, this.baseUrl, Map headers, SerializerRepo serializers)
      : headers = headers ?? {'content-type': 'application/json'},
        serializers = serializers ?? new JsonRepo();

  final List<RequestInterceptor> requestInterceptors = [];
  final List<ResponseInterceptor> responseInterceptors = [];

  @protected
  FutureOr<JaguarRequest> interceptRequest(JaguarRequest request) async {
    for (var requestInterceptor in requestInterceptors) {
      request = await requestInterceptor(request);
    }
    return request;
  }

  @protected
  FutureOr<JaguarResponse> interceptResponse(JaguarResponse response) async {
    for (var responseInterceptor in responseInterceptors) {
      response = await responseInterceptor(response);
    }
    return response;
  }
}

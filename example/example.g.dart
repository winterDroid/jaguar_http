// GENERATED CODE - DO NOT MODIFY BY HAND

part of jaguar_http.example;

// **************************************************************************
// Generator: JaguarHttpGenerator
// Target: abstract class ApiDefinition
// **************************************************************************

class Api extends ApiDefinition {
  final String baseUrl;
  final Map headers;
  final Client _client;
  final SerializerRepo serializers;
  Api(this._client, this.baseUrl, {Map headers, SerializerRepo serializers})
      : headers = headers ?? {'content-type': 'application/json'},
        serializers = serializers ?? new JsonRepo();
  Future<JaguarResponse<User>> getUserById(String id) async {
    final url = '$baseUrl//users/${id}';
    var request = new JaguarRequest(method: 'GET', url: url, headers: headers);
    if (this is JaguarInterceptors) {
      request = interceptRequest(request);
    }
    final rawResponse = await request.send(_client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    if (this is JaguarInterceptors) {
      response = interceptResponse(response);
    }
    return response;
  }

  Future<JaguarResponse<User>> postUser(User user) async {
    final url = '$baseUrl//users';
    var request = new JaguarRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: serializers.serialize(user));
    if (this is JaguarInterceptors) {
      request = interceptRequest(request);
    }
    final rawResponse = await request.send(_client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    if (this is JaguarInterceptors) {
      response = interceptResponse(response);
    }
    return response;
  }

  Future<JaguarResponse<User>> updateUser(String userId, User user) async {
    final url = '$baseUrl//users/${userId}';
    var request = new JaguarRequest(
        method: 'PUT',
        url: url,
        headers: headers,
        body: serializers.serialize(user));
    if (this is JaguarInterceptors) {
      request = interceptRequest(request);
    }
    final rawResponse = await request.send(_client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body, type: User), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    if (this is JaguarInterceptors) {
      response = interceptResponse(response);
    }
    return response;
  }

  Future<JaguarResponse<dynamic>> deleteUser(String id) async {
    final url = '$baseUrl//users';
    var request =
        new JaguarRequest(method: 'DELETE', url: url, headers: headers);
    if (this is JaguarInterceptors) {
      request = interceptRequest(request);
    }
    final rawResponse = await request.send(_client);
    var response;
    if (responseSuccessful(rawResponse)) {
      response = new JaguarResponse(
          serializers.deserialize(rawResponse.body), rawResponse);
    } else
      response = new JaguarResponse.error(rawResponse);
    if (this is JaguarInterceptors) {
      response = interceptResponse(response);
    }
    return response;
  }
}

library jaguar_http.example;

import 'dart:async';
import 'package:jaguar_http/jaguar_http.dart';
import 'package:jaguar_serializer/serializer.dart';
import 'models/user.dart';

part 'example.g.dart';

/// definition
@JaguarHttp(name: "Api")
abstract class ApiDefinition extends JaguarInterceptors {
  @Get("/users/:id")
  Future<JaguarResponse<User>> getUserById(@Param() String id);

  @Post("/users")
  Future<JaguarResponse<User>> postUser(@Body() User user);

  @Put("/users/:uid")
  Future<JaguarResponse<User>> updateUser(@Param(name: "uid") String userId, @Body() User user);

  @Delete("/users")
  Future<JaguarResponse> deleteUser(@Param() String id);
}

JsonRepo repo = new JsonRepo()
  ..add(new UserSerializer());

void main() {
  ApiDefinition api = new Api(
      new IOClient(),
      "http://localhost:9000",
      serializers: repo);

  api.requestInterceptors.add((JaguarRequest req) {
    req.headers["Authorization"] = "TOKEN";
    return req;
  });

  api.getUserById("userId").then((JaguarResponse res) {
    print(res);
  }, onError: (e) {
    print(e);
  });
}
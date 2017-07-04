# jaguar_http

An Http Api generator inspired by Retrofit for Dart

## Usage

A simple usage example:

#### pubspec.yaml

```yaml
jaguar_http:
  - example/example.dart
```

#### example.yaml

```dart
library example;

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
```


#### run
`jaguar_http build`

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

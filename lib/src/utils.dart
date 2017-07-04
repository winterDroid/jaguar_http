import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:jaguar_http/src/definitions.dart';

bool responseSuccessful(http.Response response) =>
    response.statusCode >= 200 && response.statusCode < 300;

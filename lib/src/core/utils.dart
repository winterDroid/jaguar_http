import 'package:http/src/utils.dart' as http_utils;
import 'package:jaguar_client/jaguar_client.dart';

bool responseSuccessful(JsonResponse response) =>
    response.statusCode >= 200 && response.statusCode < 300;

String paramsToQueryUri(Map<String, String> params) =>
    http_utils.mapToQuery(params);

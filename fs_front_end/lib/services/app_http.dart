import 'dart:convert';
import 'package:http/http.dart' as http_client;

/// Wrapper autour du package http avec un timeout global de 10 secondes.
/// Utilisé à la place de `http.get/post/etc.` dans tous les services.
const _kTimeout = Duration(seconds: 10);

Future<http_client.Response> get(Uri url, {Map<String, String>? headers}) =>
    http_client.get(url, headers: headers).timeout(_kTimeout);

Future<http_client.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => http_client
    .post(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<http_client.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => http_client
    .put(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<http_client.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => http_client
    .patch(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<http_client.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => http_client
    .delete(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

// Re-export pour éviter d'importer les deux
typedef Response = http_client.Response;

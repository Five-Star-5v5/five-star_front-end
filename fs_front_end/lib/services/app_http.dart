import 'dart:convert';
import 'package:http/http.dart' as _http;

/// Wrapper autour du package http avec un timeout global de 10 secondes.
/// Utilisé à la place de `http.get/post/etc.` dans tous les services.
const _kTimeout = Duration(seconds: 10);

Future<_http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _http.get(url, headers: headers).timeout(_kTimeout);

Future<_http.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _http
    .post(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<_http.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _http
    .put(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<_http.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _http
    .patch(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

Future<_http.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => _http
    .delete(url, headers: headers, body: body, encoding: encoding)
    .timeout(_kTimeout);

// Re-export pour éviter d'importer les deux
typedef Response = _http.Response;

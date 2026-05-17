import 'dart:convert';
import 'package:http/http.dart' as http_client;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'auth_service.dart';

const _kTimeout = Duration(seconds: 10);

void _handle401(http_client.Response resp, Map<String, String>? headers) {
  if (resp.statusCode == 401 && headers?['Authorization'] != null) {
    AuthService.onUnauthorized?.call();
  }
}

void _captureHttpError(String method, Uri url, int statusCode) {
  if (statusCode >= 400) {
    Sentry.captureMessage(
      'HTTP $statusCode — $method ${url.path}',
      level: statusCode >= 500 ? SentryLevel.error : SentryLevel.warning,
    );
  }
}

Future<http_client.Response> get(Uri url, {Map<String, String>? headers}) async {
  final resp = await http_client.get(url, headers: headers).timeout(_kTimeout);
  _handle401(resp, headers);
  _captureHttpError('GET', url, resp.statusCode);
  return resp;
}

Future<http_client.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final resp = await http_client
      .post(url, headers: headers, body: body, encoding: encoding)
      .timeout(_kTimeout);
  _handle401(resp, headers);
  _captureHttpError('POST', url, resp.statusCode);
  return resp;
}

Future<http_client.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final resp = await http_client
      .put(url, headers: headers, body: body, encoding: encoding)
      .timeout(_kTimeout);
  _handle401(resp, headers);
  _captureHttpError('PUT', url, resp.statusCode);
  return resp;
}

Future<http_client.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final resp = await http_client
      .patch(url, headers: headers, body: body, encoding: encoding)
      .timeout(_kTimeout);
  _handle401(resp, headers);
  _captureHttpError('PATCH', url, resp.statusCode);
  return resp;
}

Future<http_client.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  final resp = await http_client
      .delete(url, headers: headers, body: body, encoding: encoding)
      .timeout(_kTimeout);
  _handle401(resp, headers);
  _captureHttpError('DELETE', url, resp.statusCode);
  return resp;
}

// Re-export pour éviter d'importer les deux
typedef Response = http_client.Response;

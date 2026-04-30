import 'dart:convert';
import 'package:http/http.dart' as http_client;
import 'auth_service.dart';

/// Wrapper autour du package http avec timeout global et détection des 401.
const _kTimeout = Duration(seconds: 10);

// Déclenche le logout si la réponse est 401 sur une requête authentifiée.
void _handle401(http_client.Response resp, Map<String, String>? headers) {
  if (resp.statusCode == 401 && headers?['Authorization'] != null) {
    AuthService.onUnauthorized?.call();
  }
}

Future<http_client.Response> get(Uri url, {Map<String, String>? headers}) async {
  final resp = await http_client.get(url, headers: headers).timeout(_kTimeout);
  _handle401(resp, headers);
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
  return resp;
}

// Re-export pour éviter d'importer les deux
typedef Response = http_client.Response;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../errors.dart';

/// Thin Dio wrapper that POSTs JSON bodies and decodes JSON responses for the
/// Moamalat PayLink endpoints.
class MoamalatHttpClient {
  final Duration timeout;
  final Dio _client;

  MoamalatHttpClient({
    this.timeout = const Duration(seconds: 10),
    Dio? client,
  }) : _client = client ?? Dio();

  Future<Map<String, dynamic>> postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final response = await _post(uri, body);
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode > 299) {
      final responseBody = _responseBody(response.data);
      throw MoamalatPaymentError(
        responseBody.isEmpty
            ? response.statusMessage ?? 'HTTP request failed'
            : responseBody,
        statusCode: statusCode,
      );
    }
    final decoded = _decodeJson(response.data);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const MoamalatPaymentError(
      'Expected JSON object in PayByCard response',
    );
  }

  Future<Response<Object?>> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      return await _client
          .postUri<Object?>(
            uri,
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              headers: const {'Accept-Language': 'en'},
              receiveTimeout: timeout,
              responseType: ResponseType.json,
              sendTimeout: timeout,
              validateStatus: (_) => true,
            ),
          )
          .timeout(timeout);
    } on Object catch (error) {
      throw MoamalatPaymentError(
        'Unable to complete PayByCard request',
        cause: error,
      );
    }
  }

  String _responseBody(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } on Object {
      return data.toString();
    }
  }

  Object? _decodeJson(Object? data) {
    if (data is! String) return data;
    try {
      return jsonDecode(data);
    } on Object catch (error) {
      throw MoamalatPaymentError(
        'Error decoding PayByCard response',
        cause: error,
      );
    }
  }

  void close({bool force = false}) => _client.close(force: force);
}

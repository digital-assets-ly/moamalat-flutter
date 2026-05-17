import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_assets_moamalat_pay/src/errors.dart';
// ignore: implementation_imports
import 'package:digital_assets_moamalat_pay/src/services/payment_http_client.dart';

void main() {
  group('MoamalatHttpClient.postJson', () {
    test('posts JSON with gateway headers and returns a JSON object', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.uri, Uri.parse('https://example.com/PayByCard'));
              expect(options.data, <String, dynamic>{'AmountTrxn': '250'});
              expect(options.contentType, Headers.jsonContentType);
              expect(options.headers['Accept-Language'], 'en');
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{'Success': true},
                ),
              );
            },
          ),
        );
      final client = MoamalatHttpClient(client: dio);
      addTearDown(client.close);

      final json = await client.postJson(
        Uri.parse('https://example.com/PayByCard'),
        <String, dynamic>{'AmountTrxn': '250'},
      );

      expect(json, <String, dynamic>{'Success': true});
    });

    test('decodes string JSON responses', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: '{"Success":true}',
                ),
              );
            },
          ),
        );
      final client = MoamalatHttpClient(client: dio);
      addTearDown(client.close);

      final json = await client.postJson(
        Uri.parse('https://example.com/PayByCard'),
        <String, dynamic>{},
      );

      expect(json, <String, dynamic>{'Success': true});
    });

    test('throws payment errors for non-2xx responses', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 422,
                  statusMessage: 'Unprocessable Entity',
                  data: 'Bad card',
                ),
              );
            },
          ),
        );
      final client = MoamalatHttpClient(client: dio);
      addTearDown(client.close);

      await expectLater(
        client.postJson(
          Uri.parse('https://example.com/PayByCard'),
          <String, dynamic>{},
        ),
        throwsA(
          isA<MoamalatPaymentError>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Bad card'),
        ),
      );
    });

    test('throws payment errors for invalid response shapes', () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <Object?>[true],
                ),
              );
            },
          ),
        );
      final client = MoamalatHttpClient(client: dio);
      addTearDown(client.close);

      await expectLater(
        client.postJson(
          Uri.parse('https://example.com/PayByCard'),
          <String, dynamic>{},
        ),
        throwsA(
          isA<MoamalatPaymentError>().having(
            (error) => error.message,
            'message',
            'Expected JSON object in PayByCard response',
          ),
        ),
      );
    });
  });
}

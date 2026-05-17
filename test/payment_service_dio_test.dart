import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';

void main() {
  group('MoamalatPaymentService Dio requests', () {
    test('posts JSON with gateway headers and returns a typed response',
        () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'POST');
              expect(options.uri, Uri.parse(_payByCardUri));
              expect(options.contentType, Headers.jsonContentType);
              expect(options.headers['Accept-Language'], 'en');
              expect(
                options.data,
                containsPair('AmountTrxn', '250'),
              );
              expect(
                options.data,
                containsPair('PAN', '4111111111111111'),
              );
              handler.resolve(
                Response<Object?>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'Success': true,
                    'Message': 'OK',
                  },
                ),
              );
            },
          ),
        );
      final service = MoamalatPaymentService(_config, dio: dio);
      addTearDown(service.close);

      final response = await service.payByCard(
        cardNumber: '4111111111111111',
        cardHolderName: 'Test User',
        expiryDate: '0127',
        cvv: '123',
        secureHash: 'hash',
      );

      expect(response.success, true);
      expect(response.message, 'OK');
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
      final service = MoamalatPaymentService(_config, dio: dio);
      addTearDown(service.close);

      final response = await service.payByCard(
        cardNumber: '4111111111111111',
        cardHolderName: 'Test User',
        expiryDate: '0127',
        cvv: '123',
        secureHash: 'hash',
      );

      expect(response.success, true);
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
      final service = MoamalatPaymentService(_config, dio: dio);
      addTearDown(service.close);

      await expectLater(
        service.payByCard(
          cardNumber: '4111111111111111',
          cardHolderName: 'Test User',
          expiryDate: '0127',
          cvv: '123',
          secureHash: 'hash',
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
      final service = MoamalatPaymentService(_config, dio: dio);
      addTearDown(service.close);

      await expectLater(
        service.payByCard(
          cardNumber: '4111111111111111',
          cardHolderName: 'Test User',
          expiryDate: '0127',
          cvv: '123',
          secureHash: 'hash',
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

const _payByCardUri =
    'https://tnpg.moamalat.net/cube/PayLink.svc/api/PayByCard';

const _config = MoamalatPaymentConfig(
  environment: MoamalatEnvironment.testing,
  merchantId: 'M',
  terminalId: 'T',
  amount: 250,
  currencyCode: 434,
  secureHash: 'hash',
  transactionDate: '240307090501023',
);

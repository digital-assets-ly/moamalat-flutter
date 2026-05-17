import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';

void main() {
  group('MoamalatCardPaymentForm PayByCard handling', () {
    testWidgets('approves immediate payments only when ActionCode is 00',
        (tester) async {
      PayByCardResponse? success;
      MoamalatPaymentError? error;

      await _pumpAndSubmit(
        tester,
        responseJson: <String, dynamic>{
          'Success': true,
          'ActionCode': '00',
          'Message': 'Approved',
        },
        onSuccess: (response) => success = response,
        onError: (paymentError) => error = paymentError,
      );

      expect(success?.actionCode, '00');
      expect(error, isNull);
    });

    testWidgets('rejects successful responses with non-approved ActionCode',
        (tester) async {
      PayByCardResponse? success;
      MoamalatPaymentError? error;

      await _pumpAndSubmit(
        tester,
        responseJson: <String, dynamic>{
          'Success': true,
          'ActionCode': '05',
          'Message': 'Declined',
        },
        onSuccess: (response) => success = response,
        onError: (paymentError) => error = paymentError,
      );

      expect(success, isNull);
      expect(error?.message, 'Declined');
    });

    testWidgets('does not open 3DS for failed PayByCard responses',
        (tester) async {
      PayByCardResponse? success;
      MoamalatPaymentError? error;

      await _pumpAndSubmit(
        tester,
        responseJson: <String, dynamic>{
          'Success': false,
          'ChallengeRequired': true,
          'ThreeDSUrl': 'https://acs.example/challenge',
          'Message': 'Payment failed',
        },
        onSuccess: (response) => success = response,
        onError: (paymentError) => error = paymentError,
      );

      expect(success, isNull);
      expect(error?.message, 'Payment failed');
    });
  });
}

Future<void> _pumpAndSubmit(
  WidgetTester tester, {
  required Map<String, dynamic> responseJson,
  ValueChanged<PayByCardResponse>? onSuccess,
  ValueChanged<MoamalatPaymentError>? onError,
}) async {
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: responseJson,
            ),
          );
        },
      ),
    );
  final service = MoamalatPaymentService(_config, dio: dio);
  addTearDown(dio.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MoamalatCardPaymentForm(
          config: _config,
          service: service,
          cvvRequired: true,
          initialCardNumber: '4111111111111111',
          initialCardHolderName: 'Test User',
          initialExpiryDate: '0127',
          initialCvv: '123',
          onSuccess: onSuccess ?? (_) {},
          onError: onError ?? (_) {},
        ),
      ),
    ),
  );

  await tester.tap(find.text('Pay'));
  await tester.pumpAndSettle();
}

const _config = MoamalatPaymentConfig(
  environment: MoamalatEnvironment.testing,
  merchantId: 'M',
  terminalId: 'T',
  amount: 250,
  currencyCode: 434,
  secureHash: 'hash',
  transactionDate: '240307090501023',
);

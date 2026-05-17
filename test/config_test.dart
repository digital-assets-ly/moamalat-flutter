import 'package:flutter_test/flutter_test.dart';

import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';
// ignore: implementation_imports
import 'package:digital_assets_moamalat_pay/src/services/api_endpoint.dart';

void main() {
  group('MoamalatPaymentConfig', () {
    test('uses enhanced enum values for environment URLs', () {
      expect(
        MoamalatEnvironment.production.baseUrl,
        'https://npg.moamalat.net/',
      );
      expect(
        MoamalatEnvironment.testing.baseUrl,
        'https://tnpg.moamalat.net/',
      );
    });

    test('builds endpoint URIs from enhanced endpoint enum values', () {
      const config = MoamalatPaymentConfig(
        environment: MoamalatEnvironment.testing,
        merchantId: 'M',
        terminalId: 'T',
        amount: 1,
        currencyCode: 434,
        secureHash: 'hash',
        transactionDate: '240307090501023',
      );

      expect(
        config.uriFor(ApiEndpoint.payByCard).toString(),
        'https://tnpg.moamalat.net/cube/PayLink.svc/api/PayByCard',
      );
      expect(
        config.uriFor(ApiEndpoint.checkTransactionStatus).toString(),
        'https://tnpg.moamalat.net/cube/PayLink.svc/api/CheckTxnStatus',
      );
    });
  });
}

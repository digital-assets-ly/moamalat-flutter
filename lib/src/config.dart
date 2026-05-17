import 'services/api_endpoint.dart';

enum MoamalatEnvironment {
  production('https://npg.moamalat.net/'),
  testing('https://tnpg.moamalat.net/');

  const MoamalatEnvironment(this.baseUrl);

  final String baseUrl;
}

class MoamalatPaymentConfig {
  static const String _gatewayPath = 'cube/PayLink.svc/api';

  final MoamalatEnvironment environment;
  final String merchantId;
  final String terminalId;
  final double amount;
  final int currencyCode;
  final String secureHash;
  final String? trnxRefNumber;
  final String? customerId;
  final String? customerEmail;
  final String transactionDate;
  final Duration timeout;
  final String? returnUrl;

  const MoamalatPaymentConfig({
    required this.environment,
    required this.merchantId,
    required this.terminalId,
    required this.amount,
    required this.currencyCode,
    required this.secureHash,
    required this.transactionDate,
    this.trnxRefNumber,
    this.customerId,
    this.customerEmail,
    this.timeout = const Duration(seconds: 10),
    this.returnUrl,
  });

  String get baseApiUrl => '${environment.baseUrl}$_gatewayPath';

  /// The URL the gateway redirects to after a 3DS challenge. Falls back to
  /// the environment's base URL when the consumer hasn't supplied one.
  String get resolvedReturnUrl => returnUrl ?? environment.baseUrl;

  Uri uriFor(ApiEndpoint endpoint) => Uri.parse('$baseApiUrl${endpoint.path}');
}

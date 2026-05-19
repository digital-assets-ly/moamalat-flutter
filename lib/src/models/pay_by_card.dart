import '../config.dart';
import '../utils/json_coercion.dart';

class PayByCardParameters {
  final String amountTrxn;
  final String currencyCodeTrxn;
  final String merchantId;
  final String terminalId;
  final String secureHash;
  final String dateTimeLocalTrxn;
  final bool isSaveCard;
  final bool isDefaultCard;
  final String cardAcceptorIdCode;
  final String cardAcceptorTerminalId;
  final String cardHolderName;
  final String dateExpiration;
  final String cvv2;
  final String pan;
  final String? merchantReference;
  final String? systemTraceNr;
  final String? returnURL;
  final bool isFromPOS;
  final bool isWebRequest;
  final bool isMobileSDK;
  final String? customerEmail;
  final String? tokenCustomerId;
  final String? tokenCustomerSession;

  PayByCardParameters({
    required this.amountTrxn,
    required this.currencyCodeTrxn,
    required this.merchantId,
    required this.terminalId,
    required this.secureHash,
    required this.dateTimeLocalTrxn,
    required this.cardHolderName,
    required this.dateExpiration,
    required this.pan,
    this.merchantReference,
    this.systemTraceNr,
    this.returnURL,
    this.isSaveCard = false,
    this.isDefaultCard = false,
    this.cvv2 = '',
    this.isFromPOS = true,
    this.isWebRequest = true,
    this.isMobileSDK = true,
    this.customerEmail,
    this.tokenCustomerId,
    this.tokenCustomerSession,
  })  : cardAcceptorIdCode = merchantId,
        cardAcceptorTerminalId = terminalId;

  factory PayByCardParameters.fromConfig({
    required MoamalatPaymentConfig config,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required String secureHash,
    bool isSaveCard = false,
    bool isDefaultCard = false,
    String? tokenCustomerSession,
  }) {
    return PayByCardParameters(
      amountTrxn: config.amount.toString(),
      currencyCodeTrxn: config.currencyCode.toString(),
      merchantId: config.merchantId,
      terminalId: config.terminalId,
      secureHash: secureHash,
      dateTimeLocalTrxn: config.transactionDate,
      cardHolderName: cardHolderName,
      dateExpiration: expiryDate,
      cvv2: cvv,
      pan: cardNumber,
      merchantReference: config.merchantReference,
      systemTraceNr: null,
      returnURL: config.resolvedReturnUrl,
      isSaveCard: isSaveCard,
      isDefaultCard: isDefaultCard,
      customerEmail: config.customerEmail,
      tokenCustomerId: config.customerId,
      tokenCustomerSession: tokenCustomerSession,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'AmountTrxn': amountTrxn,
      'CurrencyCodeTrxn': currencyCodeTrxn,
      if (merchantReference != null) 'MerchantReference': merchantReference,
      'MerchantId': merchantId,
      'TerminalId': terminalId,
      'SecureHash': secureHash,
      'DateTimeLocalTrxn': dateTimeLocalTrxn,
      'cvv2': cvv2,
      'CardAcceptorIDcode': cardAcceptorIdCode,
      'CardAcceptorTerminalID': cardAcceptorTerminalId,
      'ISFromPOS': isFromPOS,
      'DateExpiration': dateExpiration,
      if (systemTraceNr != null) 'SystemTraceNr': systemTraceNr,
      'PAN': pan,
      if (returnURL != null) 'ReturnURL': returnURL,
      'IsWebRequest': isWebRequest,
      'IsMobileSDK': isMobileSDK,
      'Success': false,
      if(tokenCustomerSession !=null) 'TokenCustomerSession': tokenCustomerSession,
      if(customerEmail != null) 'CustomerEmail': customerEmail,
      if(tokenCustomerId != null) 'TokenCustomerId': tokenCustomerId,
    };
  }
}

class PayByCardResponse {
  final bool? success;
  final String? message;
  final String? actionCode;
  final String? authCode;
  final String? mWMessage;
  final String? merchantReference;
  final String? networkReference;
  final String? receiptNumber;
  final String? refNumber;
  final int? systemReference;
  final String? tokenCustomerId;
  final String? transactionNo;
  final String? threeDSUrl;
  final bool? challengeRequired;
  final bool? isPaid;
  final String? fromWhere;
  final Map<String, dynamic> rawJson;

  const PayByCardResponse({
    required this.rawJson,
    this.success,
    this.message,
    this.actionCode,
    this.authCode,
    this.mWMessage,
    this.merchantReference,
    this.networkReference,
    this.receiptNumber,
    this.refNumber,
    this.systemReference,
    this.tokenCustomerId,
    this.transactionNo,
    this.threeDSUrl,
    this.challengeRequired,
    this.isPaid,
    this.fromWhere,
  });

  factory PayByCardResponse.fromJson(Map<String, dynamic> json) {
    return PayByCardResponse(
      rawJson: Map<String, dynamic>.from(json),
      success: jsonBool(json['Success']),
      message: jsonString(json['Message']),
      actionCode: jsonString(json['ActionCode']),
      authCode: jsonString(json['AuthCode']),
      mWMessage: jsonString(json['MWMessage']),
      merchantReference: jsonString(json['MerchantReference']),
      networkReference: jsonString(json['NetworkReference']),
      receiptNumber: jsonString(json['ReceiptNumber']),
      refNumber: jsonString(json['RefNumber']),
      systemReference: jsonInt(json['SystemReference']),
      tokenCustomerId: jsonString(json['TokenCustomerId']),
      transactionNo: jsonString(json['TransactionNo']),
      threeDSUrl: jsonString(json['ThreeDSUrl']),
      challengeRequired: jsonBool(json['ChallengeRequired']),
      isPaid: jsonBool(json['IsPaid']),
      fromWhere: jsonString(json['FROMWHERE']),
    );
  }
}

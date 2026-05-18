import 'package:flutter/material.dart';

import '../config.dart';
import '../errors.dart';
import '../models/pay_by_card.dart';
import 'card_payment_form.dart';

/// Pushes a full-screen `Scaffold` containing a [MoamalatCardPaymentForm].
///
/// Returns the [PayByCardResponse] on success. Returns `null` if the user
/// cancelled the form (back button or close icon). Throws a
/// [MoamalatPaymentError] if the gateway, network, or 3DS challenge failed.
Future<PayByCardResponse?> showMoamalatPaymentSheet(
  BuildContext context, {
  required MoamalatPaymentConfig config,
  String title = 'Pay by card',
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  InputDecoration? inputDecoration,
  ButtonStyle? payButtonStyle,
  String payButtonLabel = 'Pay',
  bool verifyTransactionStatusAfter3DS = false,
  bool isNaps = true,
  bool isOoredoo = false,
  bool cvvRequired = true,
  String? initialCardNumber,
  String? initialCardHolderName,
  String? initialExpiryDate,
  String? initialCvv,
}) async {
  final result = await showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => _PaymentSheetScreen(
      config: config,
      title: title,
        padding: padding,
        inputDecoration: inputDecoration,
        payButtonStyle: payButtonStyle,
        payButtonLabel: payButtonLabel,
        verifyTransactionStatusAfter3DS: verifyTransactionStatusAfter3DS,
        isNaps: isNaps,
        isOoredoo: isOoredoo,
        cvvRequired: cvvRequired,
        initialCardNumber: initialCardNumber,
        initialCardHolderName: initialCardHolderName,
        initialExpiryDate: initialExpiryDate,
        initialCvv: initialCvv,
      ),
  );
  if (result is PayByCardResponse) return result;
  if (result is MoamalatPaymentError) throw result;
  return null;
}

class _PaymentSheetScreen extends StatelessWidget {
  final MoamalatPaymentConfig config;
  final String title;
  final EdgeInsetsGeometry padding;
  final InputDecoration? inputDecoration;
  final ButtonStyle? payButtonStyle;
  final String payButtonLabel;
  final bool verifyTransactionStatusAfter3DS;
  final bool isNaps;
  final bool isOoredoo;
  final bool cvvRequired;
  final String? initialCardNumber;
  final String? initialCardHolderName;
  final String? initialExpiryDate;
  final String? initialCvv;

  const _PaymentSheetScreen({
    required this.config,
    required this.title,
    required this.padding,
    required this.inputDecoration,
    required this.payButtonStyle,
    required this.payButtonLabel,
    required this.verifyTransactionStatusAfter3DS,
    required this.isNaps,
    required this.isOoredoo,
    required this.cvvRequired,
    required this.initialCardNumber,
    required this.initialCardHolderName,
    required this.initialExpiryDate,
    required this.initialCvv,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: const CloseButton()),
      body: SingleChildScrollView(
        padding: padding,
        child: MoamalatCardPaymentForm(
          config: config,
          inputDecoration: inputDecoration,
          payButtonStyle: payButtonStyle,
          payButtonLabel: payButtonLabel,
          verifyTransactionStatusAfter3DS: verifyTransactionStatusAfter3DS,
          isNaps: isNaps,
          isOoredoo: isOoredoo,
          cvvRequired: cvvRequired,
          initialCardNumber: initialCardNumber,
          initialCardHolderName: initialCardHolderName,
          initialExpiryDate: initialExpiryDate,
          initialCvv: initialCvv,
          onSuccess: (response) => Navigator.of(context).pop(response),
          onError: (error) => Navigator.of(context).pop(error),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

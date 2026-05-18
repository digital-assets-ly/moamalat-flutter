import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../errors.dart';
import '../models/pay_by_card.dart';
import '../models/three_ds_result.dart';
import '../services/payment_service.dart';
import 'input_formatters.dart';
import 'three_ds_webview_screen.dart';

/// Material card-payment form with built-in 3DS / OTP handling.
///
/// Drop into any page that already has a `MaterialApp` ancestor. The widget
/// handles validation, network request, and the 3DS WebView push internally;
/// callers only react to the terminal events via [onSuccess], [onError], and
/// the optional [onCancel].
class MoamalatCardPaymentForm extends StatefulWidget {
  final MoamalatPaymentConfig config;
  final ValueChanged<PayByCardResponse> onSuccess;
  final ValueChanged<MoamalatPaymentError> onError;
  final VoidCallback? onCancel;

  /// Optional pre-built service. When provided the widget will NOT call
  /// `service.close()` — the caller owns the lifecycle. When omitted the
  /// widget creates a service per submission and closes it afterwards.
  final MoamalatPaymentService? service;

  /// Base decoration applied to every text field. Field-specific
  /// `labelText` / `hintText` are overlaid via `copyWith`.
  final InputDecoration? inputDecoration;

  /// Style applied to the Pay button.
  final ButtonStyle? payButtonStyle;

  final String payButtonLabel;
  final String cardNumberLabel;
  final String cardHolderNameLabel;
  final String expiryDateLabel;
  final String cvvLabel;
  final String threeDSScreenTitle;

  /// When `true` (default), the widget calls `CheckTxnStatus` after a
  /// successful 3DS redirect to confirm `IsPaid == true` before invoking
  /// `onSuccess`.
  final bool verifyTransactionStatusAfter3DS;
  final bool isNaps;
  final bool isOoredoo;

  /// When `false`, the CVV field accepts an empty value. When non-empty it
  /// still has to be 3-4 digits. Defaults to `true`.
  final bool cvvRequired;

  /// Optional pre-fill values, useful for sandbox / playground flows or for
  /// rendering a previously-saved card. Digits-only formatting is applied
  /// automatically: pass `'6395 0438...'` or `'6395043835180860'` for the
  /// PAN, `'0127'` or `'01/27'` for the expiry.
  final String? initialCardNumber;
  final String? initialCardHolderName;
  final String? initialExpiryDate;
  final String? initialCvv;

  const MoamalatCardPaymentForm({
    super.key,
    required this.config,
    required this.onSuccess,
    required this.onError,
    this.onCancel,
    this.service,
    this.inputDecoration,
    this.payButtonStyle,
    this.payButtonLabel = 'Pay',
    this.cardNumberLabel = 'Card number',
    this.cardHolderNameLabel = 'Cardholder name',
    this.expiryDateLabel = 'YY/MM',
    this.cvvLabel = 'CVV',
    this.threeDSScreenTitle = '3-D Secure',
    this.verifyTransactionStatusAfter3DS = false,
    this.isNaps = true,
    this.isOoredoo = false,
    this.cvvRequired = true,
    this.initialCardNumber,
    this.initialCardHolderName,
    this.initialExpiryDate,
    this.initialCvv,
  });

  @override
  State<MoamalatCardPaymentForm> createState() =>
      _MoamalatCardPaymentFormState();
}

class _MoamalatCardPaymentFormState extends State<MoamalatCardPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cardNumberController =
      TextEditingController(text: _formatPanInitial(widget.initialCardNumber));
  late final TextEditingController _cardHolderController =
      TextEditingController(text: widget.initialCardHolderName ?? '');
  late final TextEditingController _expiryController = TextEditingController(
      text: _formatExpiryInitial(widget.initialExpiryDate));
  late final TextEditingController _cvvController =
      TextEditingController(text: widget.initialCvv ?? '');
  bool _submitting = false;
  bool _isNumoCard = false;

  @override
  void initState() {
    super.initState();
    // Initialize card type detection
    _updateCardType(_cardNumberController.text);
    // Listen to card number changes to update card type
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  String _formatPanInitial(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatExpiryInitial(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return digits;
    final clamped = digits.length > 4 ? digits.substring(0, 4) : digits;
    return '${clamped.substring(2)}/${clamped.substring(0, 2)}';
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_onCardNumberChanged);
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    _updateCardType(_cardNumberController.text);
  }

  void _updateCardType(String cardNumber) {
    final isNumo = isNumoCard(cardNumber);
    if (isNumo != _isNumoCard) {
      setState(() {
        _isNumoCard = isNumo;
      });
    }
  }

  InputDecoration _decoration(String label) {
    final base = widget.inputDecoration ??
        const InputDecoration(border: OutlineInputBorder());
    return base.copyWith(labelText: label);
  }

  String? _validateCardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your card number';
    if (digits.length < 13 || digits.length > 19) {
      return 'Card number length looks wrong';
    }
    if (!luhnCheck(digits)) return 'Card number is invalid';
    return null;
  }

  String? _validateCardHolder(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter the cardholder name';
    if (v.length > 50) return 'Name is too long';
    return null;
  }

  String? _validateExpiry(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (v.length != 4) return 'Use YY/MM';
    final yy = int.tryParse(v.substring(0, 2));
    final month = int.tryParse(v.substring(2));
    if (month == null || month < 1 || month > 12) return 'Invalid month';
    if (yy == null) return 'Invalid year';
    final now = DateTime.now();
    final expiry = DateTime(2000 + yy, month + 1, 0);
    if (expiry.isBefore(DateTime(now.year, now.month, 1))) {
      return 'Card has expired';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    // Skip CVV validation for NUMO cards
    if (_isNumoCard) return null;

    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return widget.cvvRequired ? 'Enter the CVV' : null;
    }
    if (v.length < 3 || v.length > 4) return 'Invalid CVV';
    if (int.tryParse(v) == null) return 'Digits only';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _submitting = true);

    final ownsService = widget.service == null;
    final service = widget.service ?? MoamalatPaymentService(widget.config);
    final navigator = Navigator.of(context);

    try {
      final cardNumber =
          _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      final expiryDigits = _expiryController.text.replaceAll(RegExp(r'\D'), '');

      // For NUMO cards, send empty string for cvv2
      final cvv = _isNumoCard ? '' : _cvvController.text.trim();

      final response = await service.payByCard(
        cardNumber: cardNumber,
        cardHolderName: _cardHolderController.text.trim(),
        expiryDate: expiryDigits,
        cvv: cvv,
        secureHash: widget.config.secureHash,
      );

      if (response.success != true) {
        widget.onError(_gatewayError(response));
        return;
      }

      if (response.challengeRequired == true) {
        final threeDSUrl = response.threeDSUrl;
        if (threeDSUrl == null || threeDSUrl.isEmpty) {
          widget.onError(_gatewayError(
            response,
            fallbackMessage: '3DS challenge URL is missing',
          ));
          return;
        }
        final result = await navigator.push<Object?>(
          ThreeDSWebViewScreen.route(
            service: service,
            threeDSUrl: threeDSUrl,
            verifyTransactionStatus: widget.verifyTransactionStatusAfter3DS,
            isNaps: widget.isNaps,
            isOoredoo: widget.isOoredoo,
            title: widget.threeDSScreenTitle,
            secureHash: widget.config.secureHash,
          ),
        );
        if (!mounted) return;
        if (result is ThreeDSChallengeResult) {
          if (result.success) {
            widget.onSuccess(result.redirectResponse);
          } else {
            widget.onError(MoamalatPaymentError(
              result.redirectResponse.message?.isNotEmpty == true
                  ? result.redirectResponse.message!
                  : '3DS challenge failed',
            ));
          }
        } else if (result is MoamalatPaymentError) {
          widget.onError(result);
        } else {
          widget.onCancel?.call();
        }
        return;
      }

      if (response.actionCode != '00') {
        widget.onError(_gatewayError(response));
        return;
      }

      widget.onSuccess(response);
    } on MoamalatPaymentError catch (error) {
      if (mounted) widget.onError(error);
    } catch (error) {
      if (mounted) {
        widget.onError(
          MoamalatPaymentError('Unexpected error', cause: error),
        );
      }
    } finally {
      if (ownsService) service.close();
      if (mounted) setState(() => _submitting = false);
    }
  }

  MoamalatPaymentError _gatewayError(
    PayByCardResponse response, {
    String fallbackMessage = '',
  }) {
    final message = response.message;
    return MoamalatPaymentError(
      message == null || message.isEmpty ? fallbackMessage : message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _submitting,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            TextFormField(
              controller: _cardNumberController,
              decoration: _decoration(widget.cardNumberLabel),
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardNumber],
              inputFormatters: [CardNumberInputFormatter()],
              validator: _validateCardNumber,
            ),
            TextFormField(
              controller: _cardHolderController,
              decoration: _decoration(widget.cardHolderNameLabel),
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.creditCardName],
              inputFormatters: [
                LengthLimitingTextInputFormatter(50),
              ],
              validator: _validateCardHolder,
            ),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: _decoration(widget.expiryDateLabel),
                    keyboardType: TextInputType.number,
                    autofillHints: const [
                      AutofillHints.creditCardExpirationDate,
                    ],
                    inputFormatters: [ExpiryDateInputFormatter()],
                    validator: _validateExpiry,
                  ),
                ),
                if (!_isNumoCard)
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: _decoration(widget.cvvLabel),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      autofillHints: const [
                        AutofillHints.creditCardSecurityCode,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: _validateCvv,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                style: widget.payButtonStyle,
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.payButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

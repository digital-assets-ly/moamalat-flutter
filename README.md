# digital_assets_moamalat_pay

> **Disclaimer.** This package is built and maintained by **Digital Assets** as
> an unofficial helper around the **Moamalat** payment gateway. It is **not**
> affiliated with, endorsed by, or sponsored by Moamalat in any way. Moamalat is
> not a Digital Assets product. The package wraps the legacy / outdated PayLink
> REST endpoints (`PayByCard`, `CheckTxnStatus`) that the official Moamalat SDKs
> targeted, and ships an optional Material card-payment widget on top.

A Flutter package for accepting Moamalat card payments on iOS and Android, with
built-in 3DS / OTP handling.

## Install

```sh
flutter pub add digital_assets_moamalat_pay
```

Supported platforms: **iOS** and **Android** only. Web and desktop are not
supported because the embedded 3DS WebView relies on `webview_flutter`'s mobile
platform views.

Minimum platform versions (inherited from `webview_flutter` 4.x):

- iOS 12.0+
- Android `minSdk` 21+

## Quick start — using the bundled widget

```dart
import 'package:flutter/material.dart';
import 'package:digital_assets_moamalat_pay/digital_assets_moamalat_pay.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = MoamalatPaymentConfig(
      environment: MoamalatEnvironment.testing,
      merchantId: '<YOUR_MERCHANT_ID>',
      terminalId: '<YOUR_TERMINAL_ID>',
      secureHash: '<YOUR_HEX_SECURE_HASH>',
      amount: 250,
      currencyCode: 434, // ISO-4217 numeric (e.g. 434 = LYD)
      trnxRefNumber: 'order-1234',
      customerId: 'cust-42',
      customerMobile: '+218900000000',
      customerEmail: 'cust@example.com',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MoamalatCardPaymentForm(
          config: config,
          onSuccess: (response) {
            // PayByCardResponse — `success`, `transactionNo`, etc.
          },
          onError: (error) {
            // MoamalatPaymentError — `message`, `statusCode`, `cause`.
          },
        ),
      ),
    );
  }
}
```

Or push a full-screen sheet:

```dart
final result = await showMoamalatPaymentSheet(
  context,
  config: config,
);
// result is a PayByCardResponse on success, or null if the user cancelled.
```

## Quick start — headless (no widget)

```dart
final service = MoamalatPaymentService(config);
try {
  final response = await service.payByCard(
    cardNumber: '4111111111111111',
    cardHolderName: 'JANE DOE',
    expiryDate: '2512', // MMYY
    cvv: '123',
  );
  if (response.threeDSUrl != null && response.challengeRequired == true) {
    // Open the 3DS URL in a WebView yourself, then on the gateway redirect:
    final result = await service.handleThreeDSRedirect(redirectUri);
    // result.success == true if both the redirect and CheckTxnStatus passed.
  }
} on MoamalatPaymentError catch (e) {
  // network / decoding / non-2xx response
} finally {
  service.close();
}
```

## 3DS / OTP behaviour

When `PayByCardResponse.threeDSUrl` is non-null and
`PayByCardResponse.challengeRequired == true`, `MoamalatCardPaymentForm`
automatically pushes a full-screen WebView that:

1. Loads the gateway's 3DS challenge URL (the bank's OTP page).
2. Watches navigation events. When the gateway redirects back to your
   `returnUrl` (or the environment default) with a `Success` query parameter,
   the WebView intercepts that navigation, parses the redirect, and calls
   `CheckTxnStatus` to confirm the transaction was actually paid.
3. Closes itself with a `ThreeDSChallengeResult`. On success the form invokes
   `onSuccess`; on failure (or user back-button cancel) it invokes `onError` /
   `onCancel`.

You can disable the post-3DS `CheckTxnStatus` call by passing
`verifyTransactionStatusAfter3DS: false` to `MoamalatCardPaymentForm`.

## Playground

A runnable example app lives in [`example/`](example/). Plug in your test
merchant credentials and exercise the widget on a simulator or device:

```sh
cd example
flutter pub get
flutter run
```

Create `.env.dev` and `.env.prod` files in the `example/` directory with your credentials:

```
MOAMALAT_MERCHANT_ID=10081014649
MOAMALAT_TERMINAL_ID=99179395
MOAMALAT_SECURE_HASH=
DEMO_CARD_NUMBER=6395043835180860
DEMO_CARD_HOLDER=moamalat pay
DEMO_EXPIRY=0127
```

The environment files are optional; the playground also lets you type
credentials directly into the form.

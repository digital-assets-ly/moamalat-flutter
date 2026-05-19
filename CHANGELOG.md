## 0.1.0

Initial release.

- `MoamalatPaymentService` facade for `PayByCard` against
  the Moamalat PayLink REST gateway (testing + production environments).
- Typed request / response models: `PayByCardParameters`, `PayByCardResponse`,
  `ThreeDSChallengeResult`.
- `MoamalatCardPaymentForm` Material widget with PAN / cardholder / expiry /
  CVV fields, Luhn validation, and built-in 3DS / OTP handling via an embedded
  `webview_flutter` screen.
- `showMoamalatPaymentSheet(...)` convenience helper for full-screen flows.
- iOS and Android only.

### Fixed (vs. the pre-package single-file prototype)

- `PayByCardParameters.fromConfig` now actually forwards the caller-supplied
  `cvv` to the wire `cvv2` field. The prototype dropped it, so non-3DS flows
  always sent an empty CVV.

import 'package:intl/intl.dart';

/// Formats a `DateTime` as `yyMMddHHmmssSSS` in UTC, matching the format the
/// Moamalat PayLink gateway expects for `DateTimeLocalTrxn`.
class DateFormatter {
  const DateFormatter._();

  static final DateFormat _gatewayFormat = DateFormat(
    'yyMMddHHmmssSSS',
    'en_US',
  );

  static String now() => format(DateTime.now().toUtc());

  static String format(DateTime dateTime) {
    return _gatewayFormat.format(dateTime.toUtc());
  }
}

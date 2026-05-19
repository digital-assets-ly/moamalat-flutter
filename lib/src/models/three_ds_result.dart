import 'pay_by_card.dart';

class ThreeDSChallengeResult {
  final PayByCardResponse redirectResponse;

  const ThreeDSChallengeResult({
    required this.redirectResponse,
  });

  bool get success => redirectResponse.success == true;
}

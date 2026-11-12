abstract class RewardService {
  Future<bool> showRewardedAdForLife();
  Future<bool> claimDailyFreeHint();
}

class DefaultRewardService implements RewardService {
  DateTime? _lastHintClaimDate;

  @override
  Future<bool> showRewardedAdForLife() async {
    // Enabled via AppLovin AdService
    return true;
  }

  @override
  Future<bool> claimDailyFreeHint() async {
    // Grants 1 free hint once per calendar day
    final now = DateTime.now();
    if (_lastHintClaimDate != null &&
        _lastHintClaimDate!.year == now.year &&
        _lastHintClaimDate!.month == now.month &&
        _lastHintClaimDate!.day == now.day) {
      return false;
    }
    _lastHintClaimDate = now;
    return true;
  }
}

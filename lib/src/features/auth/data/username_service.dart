import 'package:cloud_functions/cloud_functions.dart';

class UsernameService {
  final _functions = FirebaseFunctions.instance;

  Future<bool> checkAvailability(String username) async {
    try {
      final r = await _functions.httpsCallable('reserveUsername').call({'username': username, 'dryRun': true});
      return r.data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reserve(String username) async {
    final r = await _functions.httpsCallable('reserveUsername').call({'username': username});
    return r.data['success'] == true;
  }

  Future<bool> applyReferral(String code) async {
    final r = await _functions.httpsCallable('applyReferralReward').call({'referralCode': code});
    return r.data['success'] == true;
  }
}

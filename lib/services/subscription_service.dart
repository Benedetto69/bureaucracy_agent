import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionState { free, trial, subscribed }

class SubscriptionStatus {
  final SubscriptionState state;
  final DateTime? trialEnds;

  const SubscriptionStatus({
    required this.state,
    this.trialEnds,
  });

  bool get isActive {
    if (state == SubscriptionState.subscribed) return true;
    final ends = trialEnds;
    if (state == SubscriptionState.trial && ends != null) {
      return ends.isAfter(DateTime.now());
    }
    return false;
  }

  int get trialDaysLeft {
    final ends = trialEnds;
    if (ends == null) return 0;
    final remaining = ends.difference(DateTime.now()).inDays;
    return remaining >= 0 ? remaining + 1 : 0;
  }

  String get label {
    switch (state) {
      case SubscriptionState.trial:
        return trialDaysLeft > 0
            ? 'Prova gratuita: $trialDaysLeft giorni rimanenti'
            : 'Prova in scadenza';
      case SubscriptionState.subscribed:
        return 'Abbonamento attivo';
      case SubscriptionState.free:
        return 'Piano gratuito';
    }
  }
}

class SubscriptionService {
  static const _stateKey = 'subscription_state';
  static const _trialEndsKey = 'subscription_trial_end';

  final SharedPreferences _prefs;

  SubscriptionService._(this._prefs);

  static Future<SubscriptionService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SubscriptionService._(prefs);
  }

  SubscriptionStatus loadStatus() {
    final rawState = _prefs.getString(_stateKey) ?? 'free';
    final trialEndsRaw = _prefs.getString(_trialEndsKey);
    var state = SubscriptionState.free;
    DateTime? trialEnds;
    if (trialEndsRaw != null) {
      final parsed = DateTime.tryParse(trialEndsRaw);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        trialEnds = parsed;
        state = SubscriptionState.trial;
      }
    }
    if (rawState == 'subscribed') {
      state = SubscriptionState.subscribed;
      trialEnds = null;
    } else if (rawState == 'trial' && trialEnds != null) {
      state = SubscriptionState.trial;
    }
    if (state == SubscriptionState.trial) {
      if (trialEnds == null || trialEnds.isBefore(DateTime.now())) {
        state = SubscriptionState.free;
        trialEnds = null;
        _prefs.setString(_stateKey, 'free');
        _prefs.remove(_trialEndsKey);
      }
    }
    return SubscriptionStatus(state: state, trialEnds: trialEnds);
  }

  Future<void> startTrial() async {
    final trialEnds = DateTime.now().add(const Duration(days: 7));
    await _prefs.setString(_stateKey, 'trial');
    await _prefs.setString(_trialEndsKey, trialEnds.toIso8601String());
  }

  Future<void> subscribe() async {
    await _prefs.setString(_stateKey, 'subscribed');
    await _prefs.remove(_trialEndsKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import '../models/trail_models.dart';

class OfflineStorageService {
  static const String _key = 'offline_trail_strategy_standalone_v2';

  Future<void> savePlan(StrategyPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, plan.toRawJson());
  }

  Future<StrategyPlan?> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return StrategyPlan.fromRawJson(raw);
    } catch (_) {
      return null;
    }
  }
}

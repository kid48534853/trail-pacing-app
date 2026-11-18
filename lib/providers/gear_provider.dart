import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gear_models.dart';

class GearNotifier extends AsyncNotifier<GearPlanState> {
  static const String _storageKey = 'offline_gear_plan_state_v1';

  @override
  Future<GearPlanState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return GearPlanState.fromRawJson(raw);
      } catch (_) {}
    }
    return GearPlanState.defaultTemplate();
  }

  Future<void> _persist(GearPlanState next) async {
    state = AsyncValue.data(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, next.toRawJson());
  }

  Future<void> addCategory(String name) async {
    final cur = state.valueOrNull ?? GearPlanState.defaultTemplate();
    const palette = [0xFF38BDF8, 0xFFF43F5E, 0xFFA855F7, 0xFF10B981, 0xFFF59E0B, 0xFF84CC16];
    final newCat = GearCategory(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      colorHex: palette[cur.categories.length % palette.length],
      items: const [],
    );
    await _persist(GearPlanState(tripTitle: cur.tripTitle, categories: [...cur.categories, newCat]));
  }

  Future<void> addItem(String catId, GearItem item) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final nextCats = cur.categories
        .map((c) => c.id == catId ? c.copyWith(items: [...c.items, item]) : c)
        .toList();
    await _persist(GearPlanState(tripTitle: cur.tripTitle, categories: nextCats));
  }

  Future<void> deleteItem(String catId, String itemId) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final nextCats = cur.categories
        .map((c) => c.id == catId
            ? c.copyWith(items: c.items.where((i) => i.id != itemId).toList())
            : c)
        .toList();
    await _persist(GearPlanState(tripTitle: cur.tripTitle, categories: nextCats));
  }

  Future<void> toggleCheck(String catId, String itemId, {required bool isStage2}) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final nextCats = cur.categories.map((c) {
      if (c.id != catId) return c;
      final nextItems = c.items.map((i) {
        if (i.id != itemId) return i;
        if (isStage2) {
          final nextS2 = !i.stage2;
          return i.copyWith(stage2: nextS2, stage1: nextS2 ? true : i.stage1);
        }
        return i.copyWith(stage1: !i.stage1);
      }).toList();
      return c.copyWith(items: nextItems);
    }).toList();
    await _persist(GearPlanState(tripTitle: cur.tripTitle, categories: nextCats));
  }

  Future<void> resetAllChecks() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final nextCats = cur.categories
        .map((c) => c.copyWith(
              items: c.items.map((i) => i.copyWith(stage1: false, stage2: false)).toList(),
            ))
        .toList();
    await _persist(GearPlanState(tripTitle: cur.tripTitle, categories: nextCats));
  }
}

final gearProvider = AsyncNotifierProvider<GearNotifier, GearPlanState>(GearNotifier.new);

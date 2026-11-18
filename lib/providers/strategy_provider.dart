import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trail_models.dart';
import '../services/offline_storage_service.dart';
import '../services/physiology_engine.dart';

final offlineStorageProvider = Provider<OfflineStorageService>((ref) => OfflineStorageService());

class StrategyNotifier extends AsyncNotifier<StrategyPlan?> {
  @override
  Future<StrategyPlan?> build() async {
    return ref.read(offlineStorageProvider).loadPlan();
  }

  Future<void> calculateOffline({
    required Uint8List gpxBytes,
    required String fileName,
    required int targetMaxHr,
    required int flatCruisingPaceSec,
    required double cpIntervalKm,
    required double ambientTempC,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final request = StrategyCalculationRequest(
        gpxBytes: gpxBytes,
        fileName: fileName,
        targetMaxHr: targetMaxHr,
        flatCruisingPaceSec: flatCruisingPaceSec,
        cpIntervalKm: cpIntervalKm,
        ambientTempC: ambientTempC,
      );
      final plan = await compute(PhysiologyEngine.runOfflinePipeline, request);
      await ref.read(offlineStorageProvider).savePlan(plan);
      return plan;
    });
  }
}

final strategyProvider =
    AsyncNotifierProvider<StrategyNotifier, StrategyPlan?>(StrategyNotifier.new);

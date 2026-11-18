import 'dart:math' as math;
import 'dart:typed_data';
import '../models/trail_models.dart';
import 'gpx_parser_engine.dart';

class StrategyCalculationRequest {
  final Uint8List gpxBytes;
  final String fileName;
  final int targetMaxHr;
  final int flatCruisingPaceSec;
  final double cpIntervalKm;
  final double ambientTempC;

  const StrategyCalculationRequest({
    required this.gpxBytes,
    required this.fileName,
    required this.targetMaxHr,
    required this.flatCruisingPaceSec,
    required this.cpIntervalKm,
    required this.ambientTempC,
  });
}

class PhysiologyEngine {
  static StrategyPlan runOfflinePipeline(StrategyCalculationRequest req) {
    final parsed = GpxParserEngine.parseGpxBytes(req.gpxBytes);
    final smoothed = GpxParserEngine.smoothElevation(parsed.points);
    final rawSegments = GpxParserEngine.splitIntoSegments(
      smoothed,
      parsed.waypoints,
      cpIntervalKm: req.cpIntervalKm,
    );

    double cumDistM = 0.0;
    double cumAscentM = 0.0;
    double cumDescentM = 0.0;
    double cumEp = 0.0;
    int cumTimeSec = 0;
    double cumCarbs = 0.0;
    double cumSodium = 0.0;
    final segmentsOut = <SegmentStrategy>[];

    for (final seg in rawSegments) {
      final result = _calculateSegment(
        segment: seg,
        flatCruisingPaceSec: req.flatCruisingPaceSec,
        targetMaxHr: req.targetMaxHr,
        ambientTempC: req.ambientTempC,
        cumEpBefore: cumEp,
        cumTimeSecBefore: cumTimeSec,
      );

      cumDistM += seg.distance3dM;
      cumAscentM += seg.ascentM;
      cumDescentM += seg.descentM;
      cumEp += result.effortPoints;
      cumTimeSec += result.estimatedSegmentTimeSec;
      cumCarbs += result.recommendedCarbsG;
      cumSodium += result.recommendedSodiumMg;

      final endPt = seg.points.last;
      segmentsOut.add(
        SegmentStrategy(
          segmentIndex: seg.segmentIndex,
          startCpName: seg.startCpName,
          endCpName: seg.endCpName,
          endCpLat: endPt.lat,
          endCpLon: endPt.lon,
          endCpEle: endPt.ele,
          distance3dKm: _round(seg.distance3dM / 1000.0, 2),
          cumulativeDistance3dKm: _round(cumDistM / 1000.0, 2),
          ascentM: seg.ascentM,
          descentM: seg.descentM,
          avgGradePct: result.avgGradePct,
          effortPoints: result.effortPoints,
          estimatedSegmentTimeSec: result.estimatedSegmentTimeSec,
          cumulativeTimeSec: cumTimeSec,
          cumulativeTimeFormatted: formatDurationHms(cumTimeSec),
          recommendedCarbsG: result.recommendedCarbsG,
          recommendedSodiumMg: result.recommendedSodiumMg,
          recommendedFluidMl: result.recommendedFluidMl,
          pacingAdvice: result.pacingAdvice,
        ),
      );
    }

    final cleanName = req.fileName.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
    return StrategyPlan(
      planName: cleanName.isEmpty ? '未命名越野路線' : cleanName,
      targetMaxHr: req.targetMaxHr,
      flatCruisingPaceSec: req.flatCruisingPaceSec,
      ambientTempC: req.ambientTempC,
      totalDistance3dKm: _round(cumDistM / 1000.0, 2),
      totalAscentM: _round(cumAscentM, 1),
      totalDescentM: _round(cumDescentM, 1),
      totalEffortPoints: _round(cumEp, 2),
      estimatedTotalTimeSec: cumTimeSec,
      estimatedTotalTimeFormatted: formatDurationHms(cumTimeSec),
      totalCarbsG: _round(cumCarbs, 1),
      totalSodiumMg: _round(cumSodium, 0),
      createdAtIso: DateTime.now().toIso8601String(),
      segments: segmentsOut,
      chartTrackPoints: GpxParserEngine.downsampleTrack(smoothed, maxPoints: 450),
    );
  }

  static double minettiCostRatio(double grade) {
    final i = grade.clamp(-0.45, 0.45);
    final i2 = i * i;
    final i3 = i2 * i;
    final i4 = i3 * i;
    final i5 = i4 * i;
    final cost = 155.4 * i5 - 30.4 * i4 - 43.3 * i3 + 46.3 * i2 + 19.5 * i + 3.6;
    return math.max(0.85, cost / 3.6);
  }

  static double _hrCapMultiplier(double grade, int targetMaxHr) {
    if (grade <= 0.12) return 1.0;
    final conservativeness = (160.0 / targetMaxHr).clamp(0.8, 1.35);
    return 1.0 + ((grade - 0.12) * 2.1 * conservativeness);
  }

  static double _estimateWindowTimeSec(
    List<TrackPoint> points,
    double flatPaceSecPerM,
    int targetMaxHr,
  ) {
    double totalSec = 0.0;
    var anchor = points.first;
    double acc2d = 0.0;
    double acc3d = 0.0;

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      acc2d += GpxParserEngine.haversine2dM(prev.lat, prev.lon, curr.lat, curr.lon);
      acc3d += GpxParserEngine.computeDistance3dM(prev, curr);

      final isLast = i == points.length - 1;
      if (acc3d >= 35.0 || isLast) {
        if (acc3d > 0.0) {
          final grade = (curr.ele - anchor.ele) / math.max(acc2d, 1.0);
          final ratio = minettiCostRatio(grade) * _hrCapMultiplier(grade, targetMaxHr);
          totalSec += acc3d * flatPaceSecPerM * ratio;
        }
        anchor = curr;
        acc2d = 0.0;
        acc3d = 0.0;
      }
    }
    return totalSec;
  }

  static ({
    double avgGradePct,
    double effortPoints,
    int estimatedSegmentTimeSec,
    double recommendedCarbsG,
    double recommendedSodiumMg,
    double recommendedFluidMl,
    String pacingAdvice,
  }) _calculateSegment({
    required SplitSegmentRaw segment,
    required int flatCruisingPaceSec,
    required int targetMaxHr,
    required double ambientTempC,
    required double cumEpBefore,
    required int cumTimeSecBefore,
  }) {
    final distKm = segment.distance3dM / 1000.0;
    final effortPoints = _round(distKm + (segment.ascentM / 100.0), 2);

    final fatigueFactor = cumEpBefore > 20.0
        ? math.min(1.35, 1.0 + (cumEpBefore - 20.0) * 0.003)
        : 1.0;

    final rawSec = _estimateWindowTimeSec(
      segment.points,
      flatCruisingPaceSec / 1000.0,
      targetMaxHr,
    );
    final estTimeSec = math.max(1, (rawSec * fatigueFactor).round());
    final segHours = estTimeSec / 3600.0;

    final epPerHour = effortPoints / math.max(segHours, 0.05);
    double carbRateHr = 60.0;
    if (epPerHour > 9.5) carbRateHr += 12.0;
    if (cumTimeSecBefore >= 7200) carbRateHr += 10.0;
    carbRateHr = carbRateHr.clamp(50.0, 90.0);

    final tempExcess = math.max(0.0, ambientTempC - 20.0);
    final ascentRateHr = segment.ascentM / math.max(segHours, 0.05);
    final sodiumRateHr =
        (550.0 + tempExcess * 28.0 + (ascentRateHr > 400.0 ? 100.0 : 0.0)).clamp(400.0, 1100.0);
    final fluidRateHr = (500.0 + tempExcess * 30.0).clamp(450.0, 1000.0);

    final netEle = segment.points.last.ele - segment.points.first.ele;
    final avgGradePct = _round((netEle / math.max(segment.distance3dM, 1.0)) * 100.0, 1);

    return (
      avgGradePct: avgGradePct,
      effortPoints: effortPoints,
      estimatedSegmentTimeSec: estTimeSec,
      recommendedCarbsG: _round(carbRateHr * segHours, 1),
      recommendedSodiumMg: _round(sodiumRateHr * segHours, 0),
      recommendedFluidMl: _round(fluidRateHr * segHours, 0),
      pacingAdvice: _buildAdvice(avgGradePct, targetMaxHr, segment.ascentM),
    );
  }

  static String _buildAdvice(double avgGradePct, int targetMaxHr, double ascentM) {
    if (avgGradePct >= 8.0 || ascentM >= 350.0) {
      return '長陡爬升段：切換高步頻登山杖快走，嚴守心率 <= $targetMaxHr bpm';
    }
    if (avgGradePct <= -6.0) {
      return '技術下坡段：縮短步幅減少股四頭肌離心衝擊，控制心率低於 ${targetMaxHr - 10} bpm';
    }
    return '可跑巡航段：維持穩定有氧節奏，心率控制在 ${targetMaxHr - 12}~$targetMaxHr bpm';
  }

  static String formatDurationHms(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static double _round(double value, int decimals) => double.parse(value.toStringAsFixed(decimals));
}

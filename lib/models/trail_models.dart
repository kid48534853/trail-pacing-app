import 'dart:convert';

class TrackPoint {
  final double lat;
  final double lon;
  final double ele;
  final double cumDist3dM;

  const TrackPoint({
    required this.lat,
    required this.lon,
    required this.ele,
    this.cumDist3dM = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'ele': ele,
        'd': double.parse(cumDist3dM.toStringAsFixed(1)),
      };

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        ele: (json['ele'] as num).toDouble(),
        cumDist3dM: (json['d'] as num).toDouble(),
      );
}

class WaypointMarker {
  final String name;
  final double lat;
  final double lon;

  const WaypointMarker({
    required this.name,
    required this.lat,
    required this.lon,
  });
}

class SplitSegmentRaw {
  final int segmentIndex;
  final String startCpName;
  final String endCpName;
  final List<TrackPoint> points;
  final double distance3dM;
  final double ascentM;
  final double descentM;

  const SplitSegmentRaw({
    required this.segmentIndex,
    required this.startCpName,
    required this.endCpName,
    required this.points,
    required this.distance3dM,
    required this.ascentM,
    required this.descentM,
  });
}

class SegmentStrategy {
  final int segmentIndex;
  final String startCpName;
  final String endCpName;
  final double endCpLat;
  final double endCpLon;
  final double endCpEle;
  final double distance3dKm;
  final double cumulativeDistance3dKm;
  final double ascentM;
  final double descentM;
  final double avgGradePct;
  final double effortPoints;
  final int estimatedSegmentTimeSec;
  final int cumulativeTimeSec;
  final String cumulativeTimeFormatted;
  final double recommendedCarbsG;
  final double recommendedSodiumMg;
  final double recommendedFluidMl;
  final String pacingAdvice;

  const SegmentStrategy({
    required this.segmentIndex,
    required this.startCpName,
    required this.endCpName,
    required this.endCpLat,
    required this.endCpLon,
    required this.endCpEle,
    required this.distance3dKm,
    required this.cumulativeDistance3dKm,
    required this.ascentM,
    required this.descentM,
    required this.avgGradePct,
    required this.effortPoints,
    required this.estimatedSegmentTimeSec,
    required this.cumulativeTimeSec,
    required this.cumulativeTimeFormatted,
    required this.recommendedCarbsG,
    required this.recommendedSodiumMg,
    required this.recommendedFluidMl,
    required this.pacingAdvice,
  });

  Map<String, dynamic> toJson() => {
        'segment_index': segmentIndex,
        'start_cp_name': startCpName,
        'end_cp_name': endCpName,
        'end_cp_lat': endCpLat,
        'end_cp_lon': endCpLon,
        'end_cp_ele': endCpEle,
        'distance_3d_km': distance3dKm,
        'cumulative_distance_3d_km': cumulativeDistance3dKm,
        'ascent_m': ascentM,
        'descent_m': descentM,
        'avg_grade_pct': avgGradePct,
        'effort_points': effortPoints,
        'estimated_segment_time_sec': estimatedSegmentTimeSec,
        'cumulative_time_sec': cumulativeTimeSec,
        'cumulative_time_formatted': cumulativeTimeFormatted,
        'recommended_carbs_g': recommendedCarbsG,
        'recommended_sodium_mg': recommendedSodiumMg,
        'recommended_fluid_ml': recommendedFluidMl,
        'pacing_advice': pacingAdvice,
      };

  factory SegmentStrategy.fromJson(Map<String, dynamic> json) => SegmentStrategy(
        segmentIndex: (json['segment_index'] as num).toInt(),
        startCpName: json['start_cp_name'] as String,
        endCpName: json['end_cp_name'] as String,
        endCpLat: (json['end_cp_lat'] as num).toDouble(),
        endCpLon: (json['end_cp_lon'] as num).toDouble(),
        endCpEle: (json['end_cp_ele'] as num).toDouble(),
        distance3dKm: (json['distance_3d_km'] as num).toDouble(),
        cumulativeDistance3dKm: (json['cumulative_distance_3d_km'] as num).toDouble(),
        ascentM: (json['ascent_m'] as num).toDouble(),
        descentM: (json['descent_m'] as num).toDouble(),
        avgGradePct: (json['avg_grade_pct'] as num).toDouble(),
        effortPoints: (json['effort_points'] as num).toDouble(),
        estimatedSegmentTimeSec: (json['estimated_segment_time_sec'] as num).toInt(),
        cumulativeTimeSec: (json['cumulative_time_sec'] as num).toInt(),
        cumulativeTimeFormatted: json['cumulative_time_formatted'] as String,
        recommendedCarbsG: (json['recommended_carbs_g'] as num).toDouble(),
        recommendedSodiumMg: (json['recommended_sodium_mg'] as num).toDouble(),
        recommendedFluidMl: (json['recommended_fluid_ml'] as num).toDouble(),
        pacingAdvice: json['pacing_advice'] as String,
      );
}

class StrategyPlan {
  final String planName;
  final int targetMaxHr;
  final int flatCruisingPaceSec;
  final double ambientTempC;
  final double totalDistance3dKm;
  final double totalAscentM;
  final double totalDescentM;
  final double totalEffortPoints;
  final int estimatedTotalTimeSec;
  final String estimatedTotalTimeFormatted;
  final double totalCarbsG;
  final double totalSodiumMg;
  final String createdAtIso;
  final List<SegmentStrategy> segments;
  final List<TrackPoint> chartTrackPoints;

  const StrategyPlan({
    required this.planName,
    required this.targetMaxHr,
    required this.flatCruisingPaceSec,
    required this.ambientTempC,
    required this.totalDistance3dKm,
    required this.totalAscentM,
    required this.totalDescentM,
    required this.totalEffortPoints,
    required this.estimatedTotalTimeSec,
    required this.estimatedTotalTimeFormatted,
    required this.totalCarbsG,
    required this.totalSodiumMg,
    required this.createdAtIso,
    required this.segments,
    required this.chartTrackPoints,
  });

  Map<String, dynamic> toJson() => {
        'plan_name': planName,
        'target_max_hr': targetMaxHr,
        'flat_cruising_pace_sec': flatCruisingPaceSec,
        'ambient_temp_c': ambientTempC,
        'total_distance_3d_km': totalDistance3dKm,
        'total_ascent_m': totalAscentM,
        'total_descent_m': totalDescentM,
        'total_effort_points': totalEffortPoints,
        'estimated_total_time_sec': estimatedTotalTimeSec,
        'estimated_total_time_formatted': estimatedTotalTimeFormatted,
        'total_carbs_g': totalCarbsG,
        'total_sodium_mg': totalSodiumMg,
        'created_at_iso': createdAtIso,
        'segments': segments.map((s) => s.toJson()).toList(),
        'chart_track_points': chartTrackPoints.map((p) => p.toJson()).toList(),
      };

  factory StrategyPlan.fromJson(Map<String, dynamic> json) => StrategyPlan(
        planName: json['plan_name'] as String,
        targetMaxHr: (json['target_max_hr'] as num).toInt(),
        flatCruisingPaceSec: (json['flat_cruising_pace_sec'] as num).toInt(),
        ambientTempC: (json['ambient_temp_c'] as num).toDouble(),
        totalDistance3dKm: (json['total_distance_3d_km'] as num).toDouble(),
        totalAscentM: (json['total_ascent_m'] as num).toDouble(),
        totalDescentM: (json['total_descent_m'] as num).toDouble(),
        totalEffortPoints: (json['total_effort_points'] as num).toDouble(),
        estimatedTotalTimeSec: (json['estimated_total_time_sec'] as num).toInt(),
        estimatedTotalTimeFormatted: json['estimated_total_time_formatted'] as String,
        totalCarbsG: (json['total_carbs_g'] as num).toDouble(),
        totalSodiumMg: (json['total_sodium_mg'] as num).toDouble(),
        createdAtIso: json['created_at_iso'] as String,
        segments: (json['segments'] as List<dynamic>)
            .map((e) => SegmentStrategy.fromJson(e as Map<String, dynamic>))
            .toList(),
        chartTrackPoints: (json['chart_track_points'] as List<dynamic>)
            .map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String toRawJson() => jsonEncode(toJson());

  factory StrategyPlan.fromRawJson(String raw) =>
      StrategyPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

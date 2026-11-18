import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:trail_pacing_app/models/trail_models.dart';
import 'package:trail_pacing_app/services/gpx_parser_engine.dart';
import 'package:trail_pacing_app/services/physiology_engine.dart';

const String _sampleGpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="TrailTest" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="24.1810" lon="120.7310"><name>CP1 觀音山鞍部</name></wpt>
  <trk><name>Test Trail</name><trkseg>
    <trkpt lat="24.1700" lon="120.7200"><ele>200.0</ele></trkpt>
    <trkpt lat="24.1750" lon="120.7250"><ele>280.0</ele></trkpt>
    <trkpt lat="24.1810" lon="120.7310"><ele>420.0</ele></trkpt>
    <trkpt lat="24.1860" lon="120.7360"><ele>350.0</ele></trkpt>
    <trkpt lat="24.1920" lon="120.7420"><ele>210.0</ele></trkpt>
  </trkseg></trk>
</gpx>
''';

void main() {
  test('完整離線管線應正確解析 GPX、吸附 CP 並計算心率 155 bpm 補給策略', () {
    final req = StrategyCalculationRequest(
      gpxBytes: Uint8List.fromList(utf8.encode(_sampleGpx)),
      fileName: 'dakeng_trail.gpx',
      targetMaxHr: 155,
      flatCruisingPaceSec: 360,
      cpIntervalKm: 5.0,
      ambientTempC: 26.0,
    );

    final plan = PhysiologyEngine.runOfflinePipeline(req);

    expect(plan.planName, 'dakeng_trail');
    expect(plan.segments.length, 2);
    expect(plan.segments.first.endCpName, 'CP1 觀音山鞍部');
    expect(plan.totalDistance3dKm, greaterThan(2.5));
    expect(plan.totalCarbsG, greaterThan(0));
    expect(plan.totalSodiumMg, greaterThan(0));
    expect(plan.segments.first.pacingAdvice, contains('155 bpm'));
  });

  test('±3m 垂直遲滯演算法應完全過濾微幅 GPS 高度漂移', () {
    final noisy = List.generate(
      12,
      (i) => TrackPoint(lat: 24.17, lon: 120.72, ele: 200.0 + (i.isOdd ? 1.8 : 0.0)),
    );
    final stats = GpxParserEngine.computeHysteresisElevation(noisy, thresholdM: 3.0);
    expect(stats.ascentM, 0.0);
    expect(stats.descentM, 0.0);
  });
}

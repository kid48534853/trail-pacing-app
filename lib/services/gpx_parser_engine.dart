import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:xml/xml.dart';
import '../core/app_exception.dart';
import '../models/trail_models.dart';

class GpxParserEngine {
  static const double _earthRadiusM = 6371000.0;
  static const int _defaultSmoothingWindow = 5;
  static const double _defaultHysteresisM = 3.0;

  static double haversine2dM(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final dPhi = (lat2 - lat1) * math.pi / 180.0;
    final dLambda = (lon2 - lon1) * math.pi / 180.0;

    final sinDPhi = math.sin(dPhi / 2.0);
    final sinDLambda = math.sin(dLambda / 2.0);
    final a = sinDPhi * sinDPhi + math.cos(phi1) * math.cos(phi2) * sinDLambda * sinDLambda;
    return 2.0 * _earthRadiusM * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
  }

  static double computeDistance3dM(TrackPoint p1, TrackPoint p2) {
    final d2d = haversine2dM(p1.lat, p1.lon, p2.lat, p2.lon);
    final dz = p2.ele - p1.ele;
    return math.sqrt(d2d * d2d + dz * dz);
  }

  static ({List<TrackPoint> points, List<WaypointMarker> waypoints}) parseGpxBytes(
    Uint8List rawBytes,
  ) {
    if (rawBytes.length > 15 * 1024 * 1024) {
      throw const AppException(code: 'FILE_TOO_LARGE', message: 'GPX 檔案不可超過 15 MB');
    }

    late final String xmlText;
    try {
      xmlText = utf8.decode(rawBytes, allowMalformed: false);
    } catch (_) {
      throw const AppException(code: 'INVALID_ENCODING', message: 'GPX 檔案必須為標準 UTF-8 編碼');
    }

    final head = xmlText.substring(0, math.min(2048, xmlText.length)).toUpperCase();
    if (head.contains('<!DOCTYPE') || head.contains('<!ENTITY')) {
      throw const AppException(code: 'UNSAFE_XML', message: '偵測到不安全的 XML 實體宣告，已拒絕解析');
    }

    late final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xmlText);
    } catch (e) {
      throw AppException(code: 'GPX_PARSE_ERROR', message: 'GPX 格式解析失敗：$e');
    }

    final points = <TrackPoint>[];
    double lastValidEle = 0.0;

    for (final trkpt in doc.findAllElements('trkpt')) {
      final lat = double.tryParse(trkpt.getAttribute('lat') ?? '');
      final lon = double.tryParse(trkpt.getAttribute('lon') ?? '');
      if (lat == null || lon == null) continue;

      final eleText = trkpt.getElement('ele')?.innerText.trim();
      final ele = double.tryParse(eleText ?? '') ?? lastValidEle;
      lastValidEle = ele;
      points.add(TrackPoint(lat: lat, lon: lon, ele: ele));
    }

    if (points.length < 2) {
      throw const AppException(code: 'INSUFFICIENT_POINTS', message: 'GPX 軌跡點不足（至少需 2 點）');
    }

    final waypoints = <WaypointMarker>[];
    var wptIndex = 1;
    for (final wpt in doc.findAllElements('wpt')) {
      final lat = double.tryParse(wpt.getAttribute('lat') ?? '');
      final lon = double.tryParse(wpt.getAttribute('lon') ?? '');
      if (lat == null || lon == null) continue;
      final name = (wpt.getElement('name')?.innerText.trim() ?? '').isNotEmpty
          ? wpt.getElement('name')!.innerText.trim()
          : 'CP$wptIndex';
      waypoints.add(WaypointMarker(name: name, lat: lat, lon: lon));
      wptIndex++;
    }

    return (points: points, waypoints: waypoints);
  }

  static List<TrackPoint> smoothElevation(
    List<TrackPoint> rawPoints, {
    int window = _defaultSmoothingWindow,
  }) {
    final half = window ~/ 2;
    final n = rawPoints.length;
    final smoothed = <TrackPoint>[];
    double cumDist = 0.0;

    for (var i = 0; i < n; i++) {
      final left = math.max(0, i - half);
      final right = math.min(n, i + half + 1);
      double sumEle = 0.0;
      for (var j = left; j < right; j++) {
        sumEle += rawPoints[j].ele;
      }
      final avgEle = double.parse((sumEle / (right - left)).toStringAsFixed(2));
      final pt = TrackPoint(lat: rawPoints[i].lat, lon: rawPoints[i].lon, ele: avgEle);

      if (i > 0) {
        cumDist += computeDistance3dM(smoothed[i - 1], pt);
      }
      smoothed.add(TrackPoint(lat: pt.lat, lon: pt.lon, ele: pt.ele, cumDist3dM: cumDist));
    }
    return smoothed;
  }

  static ({double ascentM, double descentM}) computeHysteresisElevation(
    List<TrackPoint> points, {
    double thresholdM = _defaultHysteresisM,
  }) {
    if (points.length < 2) return (ascentM: 0.0, descentM: 0.0);

    double anchorEle = points.first.ele;
    double ascent = 0.0;
    double descent = 0.0;

    for (var i = 1; i < points.length; i++) {
      final diff = points[i].ele - anchorEle;
      if (diff >= thresholdM) {
        ascent += diff;
        anchorEle = points[i].ele;
      } else if (diff <= -thresholdM) {
        descent += diff.abs();
        anchorEle = points[i].ele;
      }
    }
    return (
      ascentM: double.parse(ascent.toStringAsFixed(1)),
      descentM: double.parse(descent.toStringAsFixed(1)),
    );
  }

  static List<SplitSegmentRaw> splitIntoSegments(
    List<TrackPoint> smoothed,
    List<WaypointMarker> waypoints, {
    double cpIntervalKm = 5.0,
  }) {
    final middleCps = _matchWaypoints(smoothed, waypoints);
    final splits = middleCps.isNotEmpty ? middleCps : _autoSplitByDistance(smoothed, cpIntervalKm);

    final anchors = <({int idx, String name})>[
      (idx: 0, name: '起點 (Start)'),
      ...splits,
      (idx: smoothed.length - 1, name: '終點 (Finish)'),
    ];

    final segments = <SplitSegmentRaw>[];
    for (var i = 0; i < anchors.length - 1; i++) {
      final start = anchors[i];
      final end = anchors[i + 1];
      final segPts = smoothed.sublist(start.idx, end.idx + 1);
      final dist3d = segPts.last.cumDist3dM - segPts.first.cumDist3dM;
      final eleStats = computeHysteresisElevation(segPts);

      segments.add(
        SplitSegmentRaw(
          segmentIndex: i + 1,
          startCpName: start.name,
          endCpName: end.name,
          points: segPts,
          distance3dM: double.parse(dist3d.toStringAsFixed(2)),
          ascentM: eleStats.ascentM,
          descentM: eleStats.descentM,
        ),
      );
    }
    return segments;
  }

  static List<({int idx, String name})> _matchWaypoints(
    List<TrackPoint> points,
    List<WaypointMarker> waypoints,
  ) {
    final matched = <({int idx, String name})>[];
    for (final wpt in waypoints) {
      var bestIdx = -1;
      var bestDist = double.infinity;
      for (var i = 0; i < points.length; i++) {
        final d = haversine2dM(wpt.lat, wpt.lon, points[i].lat, points[i].lon);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      if (bestIdx > 0 && bestIdx < points.length - 1 && bestDist <= 500.0) {
        matched.add((idx: bestIdx, name: wpt.name));
      }
    }
    matched.sort((a, b) => a.idx.compareTo(b.idx));

    final deduped = <({int idx, String name})>[];
    for (final item in matched) {
      if (deduped.isEmpty || item.idx - deduped.last.idx >= 2) {
        deduped.add(item);
      }
    }
    return deduped;
  }

  static List<({int idx, String name})> _autoSplitByDistance(
    List<TrackPoint> points,
    double intervalKm,
  ) {
    final intervalM = math.max(1.0, intervalKm) * 1000.0;
    final totalDist = points.last.cumDist3dM;
    var nextTarget = intervalM;
    var cpNum = 1;
    final splits = <({int idx, String name})>[];

    for (var i = 1; i < points.length - 1; i++) {
      final d = points[i].cumDist3dM;
      if (d >= nextTarget && (totalDist - d) >= 500.0) {
        splits.add((idx: i, name: 'CP$cpNum (${(d / 1000.0).toStringAsFixed(1)}K)'));
        cpNum++;
        nextTarget += intervalM;
      }
    }
    return splits;
  }

  static List<TrackPoint> downsampleTrack(List<TrackPoint> points, {int maxPoints = 500}) {
    if (points.length <= maxPoints) return points;
    final step = (points.length - 1) / (maxPoints - 1);
    final sampled = <TrackPoint>[];
    for (var i = 0; i < maxPoints - 1; i++) {
      sampled.add(points[(i * step).round()]);
    }
    sampled.add(points.last);
    return sampled;
  }
}

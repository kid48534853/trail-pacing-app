import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trail_models.dart';

class TrailMapCard extends StatefulWidget {
  final StrategyPlan plan;

  const TrailMapCard({super.key, required this.plan});

  @override
  State<TrailMapCard> createState() => _TrailMapCardState();
}

class _TrailMapCardState extends State<TrailMapCard> {
  bool _offlineCanvasOnly = false;

  @override
  Widget build(BuildContext context) {
    final trackLatLngs = widget.plan.chartTrackPoints
        .map((p) => LatLng(p.lat, p.lon))
        .toList(growable: false);

    if (trackLatLngs.isEmpty) {
      return const SizedBox.shrink();
    }

    final bounds = LatLngBounds.fromPoints(trackLatLngs);
    final markers = _buildMarkers(trackLatLngs.first);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('路線地圖與 CP 檢查站', style: Theme.of(context).textTheme.titleMedium),
                FilterChip(
                  label: Text(_offlineCanvasOnly ? '純離線軌跡模式' : '等高線底圖'),
                  selected: _offlineCanvasOnly,
                  onSelected: (v) => setState(() => _offlineCanvasOnly = v),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: FlutterMap(
              key: ValueKey('${widget.plan.planName}_${widget.plan.createdAtIso}'),
              options: MapOptions(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(36),
                ),
              ),
              children: [
                if (!_offlineCanvasOnly)
                  TileLayer(
                    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.trailpacing.offlineapp',
                    maxZoom: 17,
                  ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackLatLngs,
                      strokeWidth: 4.0,
                      color: Colors.tealAccent.shade700,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(LatLng startPoint) {
    final markers = <Marker>[
      Marker(
        point: startPoint,
        width: 34,
        height: 34,
        child: const Tooltip(
          message: '起點 (Start)',
          child: CircleAvatar(
            backgroundColor: Colors.green,
            child: Text('S', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ),
    ];

    for (var i = 0; i < widget.plan.segments.length; i++) {
      final seg = widget.plan.segments[i];
      final isFinish = i == widget.plan.segments.length - 1;
      markers.add(
        Marker(
          point: LatLng(seg.endCpLat, seg.endCpLon),
          width: 36,
          height: 36,
          child: Tooltip(
            message: '${seg.endCpName} (${seg.cumulativeTimeFormatted})',
            child: CircleAvatar(
              backgroundColor: isFinish ? Colors.red.shade700 : Colors.orange.shade700,
              child: Text(
                isFinish ? 'F' : '${seg.segmentIndex}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

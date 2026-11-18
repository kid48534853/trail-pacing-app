import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/trail_models.dart';

class ElevationChartCard extends StatelessWidget {
  final StrategyPlan plan;

  const ElevationChartCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final pts = plan.chartTrackPoints;
    if (pts.length < 2) return const SizedBox.shrink();

    final spots = pts
        .map((p) => FlSpot(p.cumDist3dM / 1000.0, p.ele))
        .toList(growable: false);

    final minEle = pts.map((p) => p.ele).reduce(math.min);
    final maxEle = pts.map((p) => p.ele).reduce(math.max);
    final elePadding = math.max(30.0, (maxEle - minEle) * 0.15);

    final cpLines = plan.segments
        .take(math.max(0, plan.segments.length - 1))
        .map(
          (seg) => VerticalLine(
            x: seg.cumulativeDistance3dKm,
            color: Colors.orange.withValues(alpha: 0.75),
            strokeWidth: 1.5,
            dashArray: const [5, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              labelResolver: (_) => 'CP${seg.segmentIndex}',
            ),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('海拔剖面與 CP 切分點', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spots.last.x,
                  minY: (minEle - elePadding).floorToDouble(),
                  maxY: (maxEle + elePadding).ceilToDouble(),
                  extraLinesData: ExtraLinesData(verticalLines: cpLines),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('距離 (km)', style: TextStyle(fontSize: 11)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) => Text(
                          val.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('海拔 (m)', style: TextStyle(fontSize: 11)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (s) => LineTooltipItem(
                              '${s.x.toStringAsFixed(2)} km\n${s.y.toInt()} m',
                              const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Colors.teal,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

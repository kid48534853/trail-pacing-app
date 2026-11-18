import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/trail_models.dart';
import '../providers/strategy_provider.dart';
import '../services/physiology_engine.dart';
import '../widgets/elevation_chart_card.dart';
import '../widgets/trail_map_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hrController = TextEditingController(text: '155');
  final _paceMinController = TextEditingController(text: '6');
  final _paceSecController = TextEditingController(text: '00');
  final _cpIntervalController = TextEditingController(text: '1.5');
  final _tempController = TextEditingController(text: '24.0');

  Uint8List? _selectedBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _hrController.dispose();
    _paceMinController.dispose();
    _paceSecController.dispose();
    _cpIntervalController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  Future<void> _pickTrackFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final lowerName = file.name.toLowerCase();
      if (!lowerName.endsWith('.gpx') &&
          !lowerName.endsWith('.tcx') &&
          !lowerName.endsWith('.fit')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('不支援的檔案格式：${file.name}（請選擇 .gpx、.tcx 或 .fit）')),
        );
        return;
      }

      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法讀取檔案內容，請確認檔案未損毀')),
        );
        return;
      }

      setState(() {
        _selectedBytes = bytes;
        _selectedFileName = file.name;
      });
      await _runOfflineCalculation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開啟檔案選擇器失敗：$e')),
      );
    }
  }

  Future<void> _runOfflineCalculation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBytes == null || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先匯入 .gpx / .tcx / .fit 檔案')),
      );
      return;
    }

    final paceSec = int.parse(_paceMinController.text.trim()) * 60 +
        int.parse(_paceSecController.text.trim());

    await ref.read(strategyProvider.notifier).calculateOffline(
          gpxBytes: _selectedBytes!,
          fileName: _selectedFileName!,
          targetMaxHr: int.parse(_hrController.text.trim()),
          flatCruisingPaceSec: paceSec,
          cpIntervalKm: double.parse(_cpIntervalController.text.trim()),
          ambientTempC: double.parse(_tempController.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final strategyState = ref.watch(strategyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📡 GPX / TCX / FIT 軌跡與數據分析')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(strategyState.isLoading),
            const SizedBox(height: 14),
            _buildResultSection(strategyState),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(bool isLoading) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '100% 本機離線解析 .GPX / .TCX / Garmin .FIT',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isLoading ? null : _pickTrackFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedFileName ?? '📂 匯入 GPX / TCX / FIT 檔案'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '有氧心率上限 (bpm)'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 100 || n > 220) ? '100~220' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cpIntervalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '技術切分距離 (km)'),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 0.5 || n > 50) ? '0.5~50' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paceMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '平地配速 (分)'),
                      validator: (v) => (int.tryParse(v ?? '') == null) ? '必填' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _paceSecController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '配速 (秒)'),
                      validator: (v) => (int.tryParse(v ?? '') == null) ? '必填' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '氣溫 (°C)'),
                      validator: (v) => (double.tryParse(v ?? '') == null) ? '必填' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _runOfflineCalculation,
                icon: const Icon(Icons.refresh),
                label: Text(isLoading ? '離線計算中...' : '套用參數重新計算'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(AsyncValue<StrategyPlan?> state) {
    return state.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (err, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(err.toString(), style: const TextStyle(color: AppTheme.accentRed)),
        ),
      ),
      data: (plan) {
        if (plan == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '請點擊上方綠色按鈕匯入 .gpx / .tcx / .fit 檔案，系統會自動計算 3D 距離、平滑爬升、GAP 配速、心率控場佔比與 T1~T5 技術難度。',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildKpiGrid(plan),
            const SizedBox(height: 12),
            TrailMapCard(plan: plan),
            const SizedBox(height: 12),
            ElevationChartCard(plan: plan),
            const SizedBox(height: 12),
            ...plan.segments.map(_buildSegmentCard),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(StrategyPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                '3D 總距離 / 平滑爬升',
                '${plan.totalDistance3dKm} km / +${plan.totalAscentM.toInt()} m',
                AppTheme.accentGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiTile(
                '實際配速 / GAP 等效平地',
                '${PhysiologyEngine.formatPace(plan.avgPaceSecKm)} / ${PhysiologyEngine.formatPace(plan.avgGapPaceSecKm)}',
                AppTheme.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                '平均心率 / ≤${plan.targetMaxHr}bpm 佔比',
                '${plan.avgHr != null ? "${plan.avgHr} bpm" : "無資料"} / ${plan.hrUnderCapPct != null ? "${plan.hrUnderCapPct}%" : "--"}',
                AppTheme.accentRed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiTile(
                '平均步頻 / 心率效率 EF',
                '${plan.avgCad != null ? "${plan.avgCad} spm" : "無資料"} / ${plan.efficiencyFactor ?? "--"}',
                AppTheme.accentBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(SegmentStrategy seg) {
    final techColor = Color(seg.techColorHex);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Seg ${seg.segmentIndex}: ${seg.startCpName} → ${seg.endCpName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: techColor.withOpacity(0.18),
                    border: Border.all(color: techColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(seg.techCode, style: TextStyle(color: techColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '距離 ${seg.distance3dKm} km | +${seg.ascentM.toInt()}m / -${seg.descentM.toInt()}m | 均坡 ${seg.avgGradePct}% (最大 ${seg.maxAbsGradePct}%)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (seg.actualPaceSecKm != null || seg.avgHr != null) ...[
              const SizedBox(height: 4),
              Text(
                '實測：配速 ${PhysiologyEngine.formatPace(seg.actualPaceSecKm)} | GAP ${PhysiologyEngine.formatPace(seg.gapPaceSecKm)} | 心率 ${seg.avgHr ?? '--'} bpm | 步頻 ${seg.avgCad ?? '--'} spm',
                style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '補給：碳水 ${seg.recommendedCarbsG}g / 鈉 ${seg.recommendedSodiumMg.toInt()}mg / 水 ${seg.recommendedFluidMl.toInt()}ml | 累計 ${seg.cumulativeTimeFormatted}',
              style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

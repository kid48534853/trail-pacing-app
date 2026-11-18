import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trail_models.dart';
import '../providers/strategy_provider.dart';
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
  final _cpIntervalController = TextEditingController(text: '5.0');
  final _tempController = TextEditingController(text: '24.0');

  Uint8List? _selectedGpxBytes;
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

  Future<void> _pickGpxFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gpx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return;

    setState(() {
      _selectedGpxBytes = bytes;
      _selectedFileName = file.name;
    });
  }

  Future<void> _runOfflineCalculation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGpxBytes == null || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇一個 .gpx 軌跡檔案')),
      );
      return;
    }

    final paceSec = int.parse(_paceMinController.text.trim()) * 60 +
        int.parse(_paceSecController.text.trim());

    await ref.read(strategyProvider.notifier).calculateOffline(
          gpxBytes: _selectedGpxBytes!,
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
      appBar: AppBar(
        title: const Text('越野跑補給與配速策略計算器 (離線版)'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildInputCard(strategyState.isLoading),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildResultSection(strategyState),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputCard(strategyState.isLoading),
                const SizedBox(height: 20),
                _buildResultSection(strategyState),
              ],
            ),
          );
        },
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
              Text('本機離線參數設定', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _pickGpxFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedFileName ?? '選取本機 GPX 檔案 (.gpx)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '目標心率上限 (bpm)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 100 || n > 220) ? '請輸入 100～220' : null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paceMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '平地配速 (分)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 3 || n > 14) ? '3~14分' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paceSecController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '平地配速 (秒)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 0 || n > 59) ? '0~59秒' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cpIntervalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '無 CP 切分間距 (km)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < 1 || n > 50) ? '1~50 km' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '環境氣溫 (°C)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n < -10 || n > 45) ? '-10~45°C' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isLoading ? null : _runOfflineCalculation,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.offline_bolt),
                label: Text(isLoading ? '離線運算中...' : '離線計算配速與補給策略'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(AsyncValue<StrategyPlan?> state) {
    return state.when(
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
      ),
      error: (err, _) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            err.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      ),
      data: (plan) {
        if (plan == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('無需網路連線：請直接選取本機 .gpx 檔案開始計算。'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryHeader(plan),
            const SizedBox(height: 16),
            TrailMapCard(plan: plan),
            const SizedBox(height: 16),
            ElevationChartCard(plan: plan),
            const SizedBox(height: 16),
            ...plan.segments.map(_buildSegmentCard),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(StrategyPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.planName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                Chip(label: Text('3D 距離: ${plan.totalDistance3dKm} km')),
                Chip(label: Text('總爬升: +${plan.totalAscentM} m')),
                Chip(label: Text('預估完賽: ${plan.estimatedTotalTimeFormatted}')),
                Chip(label: Text('總碳水: ${plan.totalCarbsG} g')),
                Chip(label: Text('總鈉量: ${plan.totalSodiumMg.toInt()} mg')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentCard(SegmentStrategy seg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Seg ${seg.segmentIndex}: ${seg.startCpName} → ${seg.endCpName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '累計 ${seg.cumulativeTimeFormatted}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '距離 ${seg.distance3dKm} km | 爬升 +${seg.ascentM}m / 下降 -${seg.descentM}m | 均坡 ${seg.avgGradePct}% | EP ${seg.effortPoints}',
            ),
            const SizedBox(height: 6),
            Text(
              '補給建議：碳水 ${seg.recommendedCarbsG}g / 鈉 ${seg.recommendedSodiumMg.toInt()}mg / 水分 ${seg.recommendedFluidMl.toInt()}ml',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '控場指令：${seg.pacingAdvice}',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

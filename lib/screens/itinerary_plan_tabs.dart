import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../models/gear_models.dart';
import '../providers/gear_provider.dart';

class ItineraryTabScreen extends ConsumerWidget {
  const ItineraryTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gearProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('🗺️ 路線與每日 EP / EPH 規劃')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDayDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增一天'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (plan) {
          final totalKm = plan.itinerary.fold(0.0, (s, d) => s + d.distKm);
          final totalGain = plan.itinerary.fold(0.0, (s, d) => s + d.gainM);
          final totalEp = totalKm + (totalGain / 100.0);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('總天數: ${plan.days} 天')),
                      Chip(label: Text('總距離: ${totalKm.toStringAsFixed(1)} km')),
                      Chip(label: Text('總爬升: +${totalGain.toInt()} m')),
                      Chip(
                        label: Text(
                          '全程負荷: ${totalEp.toStringAsFixed(1)} EP',
                          style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...plan.itinerary.asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('DAY ${idx + 1}: ${day.route}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.distKm} km | +${day.gainM.toInt()}m / -${day.lossM.toInt()}m | 預計 ${day.estHours} hr',
                            style: const TextStyle(color: AppTheme.accentGreen),
                          ),
                          Text(
                            'EP: ${day.ep.toStringAsFixed(1)} | 目標配速: ${day.eph.toStringAsFixed(2)} EPH',
                            style: const TextStyle(color: AppTheme.accentBlue),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                      onPressed: () => ref.read(gearProvider.notifier).deleteItineraryDay(day.id),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddDayDialog(BuildContext context, WidgetRef ref) async {
    final routeCtrl = TextEditingController();
    final distCtrl = TextEditingController(text: '12');
    final gainCtrl = TextEditingController(text: '800');
    final hrCtrl = TextEditingController(text: '6.0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增行程天數'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: routeCtrl, decoration: const InputDecoration(labelText: '當日路線區段')),
            const SizedBox(height: 8),
            TextField(controller: distCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '距離 (km)')),
            const SizedBox(height: 8),
            TextField(controller: gainCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '總爬升 (+m)')),
            const SizedBox(height: 8),
            TextField(controller: hrCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '預計時數 (hr)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('新增')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(gearProvider.notifier).addItineraryDay(
            ItineraryDay(
              id: 'day-${DateTime.now().millisecondsSinceEpoch}',
              route: routeCtrl.text.trim().isEmpty ? '新行程路線' : routeCtrl.text.trim(),
              distKm: double.tryParse(distCtrl.text) ?? 10,
              gainM: double.tryParse(gainCtrl.text) ?? 500,
              lossM: double.tryParse(gainCtrl.text) ?? 500,
              estHours: double.tryParse(hrCtrl.text) ?? 5,
            ),
          );
    }
  }
}

class PlanDocTabScreen extends ConsumerWidget {
  const PlanDocTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gearProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('📝 登山 / 越野跑安全計畫書')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (plan) {
          final doc = plan.planDoc;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              FilledButton.icon(
                onPressed: () {
                  final text = '''
【登山 / 越野跑安全計畫書】
路線：${doc.routeRegion} (${plan.days} 天)
日期：${doc.dates}
領隊：${doc.leader}
留守人：${doc.homeContact}
回報機制：${doc.checkInSchedule}
🚨 報案死線：${doc.alarmDeadline}
撤退計畫：${doc.escapeRoute}
裝備基礎重：${(plan.baseG / 1000).toStringAsFixed(2)} kg / 總重：${(plan.totalG / 1000).toStringAsFixed(2)} kg
二次確認進度：${plan.stage2Done} / ${plan.totalItemRows} 項
''';
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已複製完整留守計畫書，可直接貼給留守人！')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('📋 一鍵複製完整計畫書傳給留守人'),
              ),
              const SizedBox(height: 14),
              _editField('目標山域 / 路線', doc.routeRegion, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(routeRegion: v))),
              _editField('活動日期', doc.dates, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(dates: v))),
              _editField('領隊 / 隊員', doc.leader, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(leader: v))),
              _editField('留守人聯絡方式', doc.homeContact, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(homeContact: v))),
              _editField('約定回報時間', doc.checkInSchedule, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(checkInSchedule: v))),
              _editField('🚨 逾時報案死線', doc.alarmDeadline, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(alarmDeadline: v))),
              _editField('撤退計畫 (C-Plan)', doc.escapeRoute, (v) => ref.read(gearProvider.notifier).updatePlanDoc(doc.copyWith(escapeRoute: v)), maxLines: 3),
            ],
          );
        },
      ),
    );
  }

  Widget _editField(String label, String initial, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}

class NutritionTabScreen extends ConsumerWidget {
  const NutritionTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gearProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('💧 飲水熱量與負重試算')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (plan) {
          final days = plan.days;
          final totalKcal = (days * plan.dailyKcal).round();
          final recFoodG = ((plan.dailyKcal / plan.foodDensity) * 100 * days).round();
          final waterG = (plan.waterLiters * 1000).round();
          final simPackKg = (plan.baseG + recFoodG + waterG) / 1000.0;
          final ratioPct = (simPackKg / plan.userWeightKg) * 100.0;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _numField('體重 (kg)', plan.userWeightKg, (v) => ref.read(gearProvider.notifier).updateNutrition(userWeightKg: v)),
                      const SizedBox(height: 10),
                      _numField('每日消耗熱量 (kcal)', plan.dailyKcal, (v) => ref.read(gearProvider.notifier).updateNutrition(dailyKcal: v)),
                      const SizedBox(height: 10),
                      _numField('糧食熱量密度 (kcal/100g)', plan.foodDensity, (v) => ref.read(gearProvider.notifier).updateNutrition(foodDensity: v)),
                      const SizedBox(height: 10),
                      _numField('預計背水量 (公升 L)', plan.waterLiters, (v) => ref.read(gearProvider.notifier).updateNutrition(waterLiters: v)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _metricCard('$days 天總熱量需求', '$totalKcal kcal', AppTheme.accentAmber),
              _metricCard('建議攜帶乾糧總重', '${(recFoodG / 1000).toStringAsFixed(2)} kg ($recFoodG g)', AppTheme.accentGreen),
              _metricCard('起登滿載背包總重 (基重+糧+水)', '${simPackKg.toStringAsFixed(2)} kg (佔體重 ${ratioPct.toStringAsFixed(1)}%)',
                  ratioPct <= 15 ? AppTheme.accentBlue : AppTheme.accentRed),
            ],
          );
        },
      ),
    );
  }

  Widget _numField(String label, double val, ValueChanged<double> onChanged) {
    return TextFormField(
      initialValue: val.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (s) {
        final v = double.tryParse(s);
        if (v != null && v > 0) onChanged(v);
      },
    );
  }

  Widget _metricCard(String title, String val, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        subtitle: Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

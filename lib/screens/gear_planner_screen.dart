import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gear_models.dart';
import '../providers/gear_provider.dart';

class GearPlannerScreen extends ConsumerStatefulWidget {
  const GearPlannerScreen({super.key});

  @override
  ConsumerState<GearPlannerScreen> createState() => _GearPlannerScreenState();
}

class _GearPlannerScreenState extends ConsumerState<GearPlannerScreen> {
  bool _onlyUnchecked = false;

  @override
  Widget build(BuildContext context) {
    final gearState = ref.watch(gearProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('輕便包 Pro — 裝備重量與二次確認'),
        actions: [
          IconButton(
            tooltip: '重置所有勾選',
            onPressed: () => ref.read(gearProvider.notifier).resetAllChecks(),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('新增分類'),
      ),
      body: gearState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入裝備表失敗：$e')),
        data: (plan) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            _buildSummaryCard(context, plan),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('裝備分類清單', style: Theme.of(context).textTheme.titleMedium),
                FilterChip(
                  label: const Text('僅顯示未上包'),
                  selected: _onlyUnchecked,
                  onSelected: (v) => setState(() => _onlyUnchecked = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...plan.categories.map((cat) => _buildCategoryCard(context, cat)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, GearPlanState plan) {
    final baseKg = plan.baseG / 1000.0;
    final packPct = plan.totalItemRows > 0 ? plan.stage2Done / plan.totalItemRows : 0.0;
    final tierLabel = baseKg < 3.0
        ? 'Sub-UL 極致超輕'
        : baseKg < 4.5
            ? 'Ultralight 超輕量'
            : baseKg < 9.0
                ? 'Lightweight 輕量化'
                : 'Traditional 重裝';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('重量統計總覽', style: Theme.of(context).textTheme.titleMedium),
                Chip(label: Text(tierLabel)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('總重: ${(plan.totalG / 1000).toStringAsFixed(2)} kg')),
                Chip(label: Text('基礎重: ${baseKg.toStringAsFixed(2)} kg')),
                Chip(label: Text('消耗品: ${(plan.consumableG / 1000).toStringAsFixed(2)} kg')),
                Chip(label: Text('穿戴: ${(plan.wornG / 1000).toStringAsFixed(2)} kg')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('出發前二次確認上包進度', style: TextStyle(fontSize: 12)),
                Text('${plan.stage2Done} / ${plan.totalItemRows} (${(packPct * 100).round()}%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: packPct),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, GearCategory cat) {
    final visibleItems = _onlyUnchecked ? cat.items.where((i) => !i.stage2).toList() : cat.items;
    final catColor = Color(cat.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(radius: 8, backgroundColor: catColor),
        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('小計 ${(cat.totalWeightG / 1000).toStringAsFixed(2)} kg · ${cat.items.length} 項'),
        trailing: IconButton(
          tooltip: '新增裝備到此分類',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddItemDialog(context, cat.id, cat.name),
        ),
        children: [
          if (visibleItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('此分類目前無待檢核項目', style: TextStyle(fontSize: 12)),
            ),
          ...visibleItems.map((item) => ListTile(
                title: Text(
                  '${item.mandatory ? "🛡️ " : ""}${item.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: item.stage2 ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${item.desc.isNotEmpty ? "${item.desc} · " : ""}${item.weightG.toInt()}g × ${item.qty}'
                  '${item.worn ? " [穿戴]" : ""}${item.consumable ? " [消耗]" : ""}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('初檢', style: TextStyle(fontSize: 11)),
                      selected: item.stage1,
                      onSelected: (_) => ref
                          .read(gearProvider.notifier)
                          .toggleCheck(cat.id, item.id, isStage2: false),
                    ),
                    FilterChip(
                      label: const Text('上包', style: TextStyle(fontSize: 11)),
                      selected: item.stage2,
                      onSelected: (_) => ref
                          .read(gearProvider.notifier)
                          .toggleCheck(cat.id, item.id, isStage2: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => ref.read(gearProvider.notifier).deleteItem(cat.id, item.id),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增裝備分類系統'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '分類名稱 (例如：宿營系統、3C產品)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('新增')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(gearProvider.notifier).addCategory(ctrl.text.trim());
    }
  }

  Future<void> _showAddItemDialog(BuildContext context, String catId, String catName) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '100');
    var worn = false;
    var consumable = false;
    var mandatory = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('新增裝備至【$catName】'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '裝備名稱 *')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '品牌 / 描述')),
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '單件重量 (克 g)'),
                ),
                CheckboxListTile(
                  title: const Text('穿戴於身上 (Worn)'),
                  value: worn,
                  onChanged: (v) => setLocal(() => worn = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('消耗品 (Consumable)'),
                  value: consumable,
                  onChanged: (v) => setLocal(() => consumable = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('強制/關鍵安全裝備'),
                  value: mandatory,
                  onChanged: (v) => setLocal(() => mandatory = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('加入')),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      final item = GearItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        desc: descCtrl.text.trim(),
        weightG: double.tryParse(weightCtrl.text.trim()) ?? 0.0,
        worn: worn,
        consumable: consumable,
        mandatory: mandatory,
      );
      await ref.read(gearProvider.notifier).addItem(catId, item);
    }
  }
}

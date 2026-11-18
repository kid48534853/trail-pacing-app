import 'dart:convert';

class GearItem {
  final String id;
  final String name;
  final String desc;
  final double weightG;
  final int qty;
  final bool worn;
  final bool consumable;
  final bool mandatory;
  final bool stage1;
  final bool stage2;

  const GearItem({
    required this.id,
    required this.name,
    this.desc = '',
    required this.weightG,
    this.qty = 1,
    this.worn = false,
    this.consumable = false,
    this.mandatory = false,
    this.stage1 = false,
    this.stage2 = false,
  });

  double get totalWeightG => weightG * qty;

  GearItem copyWith({
    String? name,
    String? desc,
    double? weightG,
    int? qty,
    bool? worn,
    bool? consumable,
    bool? mandatory,
    bool? stage1,
    bool? stage2,
  }) {
    return GearItem(
      id: id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      weightG: weightG ?? this.weightG,
      qty: qty ?? this.qty,
      worn: worn ?? this.worn,
      consumable: consumable ?? this.consumable,
      mandatory: mandatory ?? this.mandatory,
      stage1: stage1 ?? this.stage1,
      stage2: stage2 ?? this.stage2,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
        'weightG': weightG,
        'qty': qty,
        'worn': worn,
        'consumable': consumable,
        'mandatory': mandatory,
        'stage1': stage1,
        'stage2': stage2,
      };

  factory GearItem.fromJson(Map<String, dynamic> json) => GearItem(
        id: json['id'] as String,
        name: json['name'] as String,
        desc: (json['desc'] as String?) ?? '',
        weightG: (json['weightG'] as num).toDouble(),
        qty: (json['qty'] as num? ?? 1).toInt(),
        worn: (json['worn'] as bool?) ?? false,
        consumable: (json['consumable'] as bool?) ?? false,
        mandatory: (json['mandatory'] as bool?) ?? false,
        stage1: (json['stage1'] as bool?) ?? false,
        stage2: (json['stage2'] as bool?) ?? false,
      );
}

class GearCategory {
  final String id;
  final String name;
  final int colorHex;
  final List<GearItem> items;

  const GearCategory({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.items,
  });

  double get totalWeightG => items.fold(0.0, (sum, i) => sum + i.totalWeightG);

  GearCategory copyWith({String? name, int? colorHex, List<GearItem>? items}) => GearCategory(
        id: id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory GearCategory.fromJson(Map<String, dynamic> json) => GearCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: (json['colorHex'] as num? ?? 0xFF84CC16).toInt(),
        items: (json['items'] as List<dynamic>)
            .map((e) => GearItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GearPlanState {
  final String tripTitle;
  final List<GearCategory> categories;

  const GearPlanState({required this.tripTitle, required this.categories});

  double get totalG => categories.fold(0.0, (s, c) => s + c.totalWeightG);

  double get consumableG => categories
      .expand((c) => c.items)
      .where((i) => i.consumable)
      .fold(0.0, (s, i) => s + i.totalWeightG);

  double get wornG => categories
      .expand((c) => c.items)
      .where((i) => i.worn && !i.consumable)
      .fold(0.0, (s, i) => s + i.totalWeightG);

  double get baseG => totalG - consumableG - wornG;
  double get packG => totalG - wornG;

  int get totalItemRows => categories.fold(0, (s, c) => s + c.items.length);
  int get stage1Done => categories.expand((c) => c.items).where((i) => i.stage1).length;
  int get stage2Done => categories.expand((c) => c.items).where((i) => i.stage2).length;

  Map<String, dynamic> toJson() => {
        'tripTitle': tripTitle,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory GearPlanState.fromJson(Map<String, dynamic> json) => GearPlanState(
        tripTitle: (json['tripTitle'] as String?) ?? '輕量化裝備表',
        categories: (json['categories'] as List<dynamic>)
            .map((e) => GearCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String toRawJson() => jsonEncode(toJson());
  factory GearPlanState.fromRawJson(String raw) =>
      GearPlanState.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static GearPlanState defaultTemplate() => const GearPlanState(
        tripTitle: 'Fastpacking / 越野跑輕量化裝備表',
        categories: [
          GearCategory(
            id: 'cat-pack',
            name: '背負系統',
            colorHex: 0xFFE11D48,
            items: [
              GearItem(id: 'i-1', name: '越野跑水袋背心 / 快速包', desc: 'RB36 / Adv Skin 12', weightG: 480, mandatory: true),
              GearItem(id: 'i-2', name: '背包內層防水袋', desc: '輕量化防水內襯', weightG: 29, mandatory: true),
            ],
          ),
          GearCategory(
            id: 'cat-body',
            name: '身體部品與強制安全',
            colorHex: 0xFF9333EA,
            items: [
              GearItem(id: 'i-3', name: '防水風雨衣', desc: 'Gore-Tex 輕量外層', weightG: 220, mandatory: true),
              GearItem(id: 'i-4', name: '頭燈 + 救生毯 + 求生哨', desc: 'NU25 UL + SOL 應變組', weightG: 185, mandatory: true),
              GearItem(id: 'i-5', name: '越野跑鞋 + 碳纖登山杖', desc: '身上穿戴 (Worn)', weightG: 990, worn: true),
            ],
          ),
          GearCategory(
            id: 'cat-food',
            name: '飲食與補給系統',
            colorHex: 0xFFEA580C,
            items: [
              GearItem(id: 'i-6', name: '濾水器與軟水袋', desc: 'Katadyn BeFree 1L', weightG: 120, mandatory: true),
              GearItem(id: 'i-7', name: '行進飲水 (1L) + 能量膠/鹽錠', desc: '消耗品', weightG: 1350, consumable: true, mandatory: true),
            ],
          ),
        ],
      );
}

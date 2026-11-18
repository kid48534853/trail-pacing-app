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
  }) =>
      GearItem(
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

  double get totalWeightG => items.fold(0.0, (s, i) => s + i.totalWeightG);

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

class ItineraryDay {
  final String id;
  final String route;
  final double distKm;
  final double gainM;
  final double lossM;
  final double estHours;
  final String water;
  final String camp;

  const ItineraryDay({
    required this.id,
    required this.route,
    required this.distKm,
    required this.gainM,
    required this.lossM,
    required this.estHours,
    this.water = '',
    this.camp = '',
  });

  double get ep => distKm + (gainM / 100.0);
  double get eph => estHours > 0 ? ep / estHours : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'route': route,
        'distKm': distKm,
        'gainM': gainM,
        'lossM': lossM,
        'estHours': estHours,
        'water': water,
        'camp': camp,
      };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        id: json['id'] as String,
        route: (json['route'] as String?) ?? '',
        distKm: (json['distKm'] as num? ?? 0).toDouble(),
        gainM: (json['gainM'] as num? ?? 0).toDouble(),
        lossM: (json['lossM'] as num? ?? 0).toDouble(),
        estHours: (json['estHours'] as num? ?? 0).toDouble(),
        water: (json['water'] as String?) ?? '',
        camp: (json['camp'] as String?) ?? '',
      );
}

class SafetyPlanDoc {
  final String routeRegion;
  final String dates;
  final String leader;
  final String homeContact;
  final String checkInSchedule;
  final String alarmDeadline;
  final String escapeRoute;

  const SafetyPlanDoc({
    this.routeRegion = '谷關G4 / 百岳縱走',
    this.dates = '2026-11-20 ~ 2026-11-21',
    this.leader = '林子傑',
    this.homeContact = '留守人姓名 / 09xx-xxx-xxx',
    this.checkInSchedule = '每日 18:30 抵達營地回報座標',
    this.alarmDeadline = '最後日 20:00 未歸且失聯即通報 119',
    this.escapeRoute = '遇豪雨或失溫風險立即原路撤退下山',
  });

  SafetyPlanDoc copyWith({
    String? routeRegion,
    String? dates,
    String? leader,
    String? homeContact,
    String? checkInSchedule,
    String? alarmDeadline,
    String? escapeRoute,
  }) =>
      SafetyPlanDoc(
        routeRegion: routeRegion ?? this.routeRegion,
        dates: dates ?? this.dates,
        leader: leader ?? this.leader,
        homeContact: homeContact ?? this.homeContact,
        checkInSchedule: checkInSchedule ?? this.checkInSchedule,
        alarmDeadline: alarmDeadline ?? this.alarmDeadline,
        escapeRoute: escapeRoute ?? this.escapeRoute,
      );

  Map<String, dynamic> toJson() => {
        'routeRegion': routeRegion,
        'dates': dates,
        'leader': leader,
        'homeContact': homeContact,
        'checkInSchedule': checkInSchedule,
        'alarmDeadline': alarmDeadline,
        'escapeRoute': escapeRoute,
      };

  factory SafetyPlanDoc.fromJson(Map<String, dynamic> json) => SafetyPlanDoc(
        routeRegion: (json['routeRegion'] as String?) ?? '',
        dates: (json['dates'] as String?) ?? '',
        leader: (json['leader'] as String?) ?? '',
        homeContact: (json['homeContact'] as String?) ?? '',
        checkInSchedule: (json['checkInSchedule'] as String?) ?? '',
        alarmDeadline: (json['alarmDeadline'] as String?) ?? '',
        escapeRoute: (json['escapeRoute'] as String?) ?? '',
      );
}

class GearPlanState {
  final String tripTitle;
  final List<GearCategory> categories;
  final List<ItineraryDay> itinerary;
  final SafetyPlanDoc planDoc;
  final double userWeightKg;
  final double dailyKcal;
  final double foodDensity;
  final double waterLiters;

  const GearPlanState({
    required this.tripTitle,
    required this.categories,
    required this.itinerary,
    required this.planDoc,
    this.userWeightKg = 65.0,
    this.dailyKcal = 2800.0,
    this.foodDensity = 420.0,
    this.waterLiters = 1.5,
  });

  double get totalG => categories.fold(0.0, (s, c) => s + c.totalWeightG);
  double get consumableG =>
      categories.expand((c) => c.items).where((i) => i.consumable).fold(0.0, (s, i) => s + i.totalWeightG);
  double get wornG => categories
      .expand((c) => c.items)
      .where((i) => i.worn && !i.consumable)
      .fold(0.0, (s, i) => s + i.totalWeightG);
  double get baseG => totalG - consumableG - wornG;
  double get packG => totalG - wornG;

  int get totalItemRows => categories.fold(0, (s, c) => s + c.items.length);
  int get stage1Done => categories.expand((c) => c.items).where((i) => i.stage1).length;
  int get stage2Done => categories.expand((c) => c.items).where((i) => i.stage2).length;
  int get days => itinerary.isEmpty ? 1 : itinerary.length;

  GearPlanState copyWith({
    String? tripTitle,
    List<GearCategory>? categories,
    List<ItineraryDay>? itinerary,
    SafetyPlanDoc? planDoc,
    double? userWeightKg,
    double? dailyKcal,
    double? foodDensity,
    double? waterLiters,
  }) =>
      GearPlanState(
        tripTitle: tripTitle ?? this.tripTitle,
        categories: categories ?? this.categories,
        itinerary: itinerary ?? this.itinerary,
        planDoc: planDoc ?? this.planDoc,
        userWeightKg: userWeightKg ?? this.userWeightKg,
        dailyKcal: dailyKcal ?? this.dailyKcal,
        foodDensity: foodDensity ?? this.foodDensity,
        waterLiters: waterLiters ?? this.waterLiters,
      );

  Map<String, dynamic> toJson() => {
        'tripTitle': tripTitle,
        'categories': categories.map((c) => c.toJson()).toList(),
        'itinerary': itinerary.map((d) => d.toJson()).toList(),
        'planDoc': planDoc.toJson(),
        'userWeightKg': userWeightKg,
        'dailyKcal': dailyKcal,
        'foodDensity': foodDensity,
        'waterLiters': waterLiters,
      };

  factory GearPlanState.fromJson(Map<String, dynamic> json) => GearPlanState(
        tripTitle: (json['tripTitle'] as String?) ?? '谷關G4 輕量化裝備表',
        categories: ((json['categories'] as List<dynamic>?) ?? const [])
            .map((e) => GearCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        itinerary: ((json['itinerary'] as List<dynamic>?) ?? const [])
            .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        planDoc: json['planDoc'] is Map<String, dynamic>
            ? SafetyPlanDoc.fromJson(json['planDoc'] as Map<String, dynamic>)
            : const SafetyPlanDoc(),
        userWeightKg: (json['userWeightKg'] as num? ?? 65.0).toDouble(),
        dailyKcal: (json['dailyKcal'] as num? ?? 2800.0).toDouble(),
        foodDensity: (json['foodDensity'] as num? ?? 420.0).toDouble(),
        waterLiters: (json['waterLiters'] as num? ?? 1.5).toDouble(),
      );

  String toRawJson() => jsonEncode(toJson());
  factory GearPlanState.fromRawJson(String raw) =>
      GearPlanState.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static GearPlanState defaultTemplate() => const GearPlanState(
        tripTitle: '谷關G4 Fastpacking',
        planDoc: SafetyPlanDoc(),
        itinerary: [
          ItineraryDay(
            id: 'day-1',
            route: '裡冷登山口 ➔ 唐麻丹山 ➔ 東卯山 ➔ 谷關大道院',
            distKm: 18.5,
            gainM: 1750,
            lossM: 1750,
            estHours: 7.5,
            water: '自背 1.5L + 濾水器',
            camp: '第一日營地',
          ),
          ItineraryDay(
            id: 'day-2',
            route: '白毛山 ➔ 阿冷山 ➔ 裡冷林道返程',
            distKm: 15.6,
            gainM: 1751,
            lossM: 1751,
            estHours: 7.0,
            water: '溪底活水過濾',
            camp: '下山賦歸',
          ),
        ],
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
        ],
      );
}

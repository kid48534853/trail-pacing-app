import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'providers/gear_provider.dart';
import 'screens/gear_planner_screen.dart';
import 'screens/home_screen.dart';
import 'screens/itinerary_plan_tabs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TrailPacingApp()));
}

class TrailPacingApp extends StatelessWidget {
  const TrailPacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '輕便包 Pro × 越野跑全能離線版',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedIndex = 5;

  static const _pages = <Widget>[
    GearPlannerScreen(),
    GearPlannerScreen(),
    ItineraryTabScreen(),
    PlanDocTabScreen(),
    NutritionTabScreen(),
    HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final gearState = ref.watch(gearProvider).valueOrNull;
    final totalKg = gearState != null ? (gearState.totalG / 1000).toStringAsFixed(2) : '0.00';
    final checkStr = gearState != null ? '${gearState.stage2Done}/${gearState.totalItemRows}' : '0/0';
    final daysStr = gearState != null ? '${gearState.days}天' : '1天';

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.bgSidebar,
        selectedItemColor: AppTheme.accentGreen,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.backpack_outlined), label: '裝備\n${totalKg}kg'),
          BottomNavigationBarItem(icon: const Icon(Icons.fact_check_outlined), label: '二次確認\n$checkStr'),
          BottomNavigationBarItem(icon: const Icon(Icons.map_outlined), label: '路線\n$daysStr'),
          const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: '計畫書'),
          const BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), label: '負重試算'),
          const BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: '數據分析'),
        ],
      ),
    );
  }
}

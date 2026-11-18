import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/gear_planner_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TrailPacingApp()));
}

class TrailPacingApp extends StatelessWidget {
  const TrailPacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '輕便包 Pro × 越野跑策略 (二合一離線版)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    GearPlannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain),
            label: '軌跡與補給',
          ),
          NavigationDestination(
            icon: Icon(Icons.backpack_outlined),
            selectedIcon: Icon(Icons.backpack),
            label: '輕便包 Pro',
          ),
        ],
      ),
    );
  }
}

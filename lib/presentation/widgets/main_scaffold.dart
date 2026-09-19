import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/app_state.dart';
import '../../core/strings.dart';
import '../../core/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/my_parking_screen.dart';
import '../screens/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);

    final pages = [
      const HomeScreen(),
      const MyParkingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Theme.of(context).cardTheme.color,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primary),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_parking_outlined),
            selectedIcon:
                const Icon(Icons.local_parking_rounded, color: AppColors.primary),
            label: s.myParking,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}

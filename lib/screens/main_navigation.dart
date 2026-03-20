import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'habit_form/habits_list_screen.dart';
import 'stats/stats_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _dashboardRefreshVersion = 0;
  int _habitsRefreshVersion = 0;
  int _statsRefreshVersion = 0;

  List<Widget> _buildScreens() {
    return [
      DashboardScreen(key: ValueKey('dashboard_$_dashboardRefreshVersion')),
      HabitsListScreen(key: ValueKey('habits_$_habitsRefreshVersion')),
      StatsScreen(key: ValueKey('stats_$_statsRefreshVersion')),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _dashboardRefreshVersion++;
            } else if (index == 1) {
              _habitsRefreshVersion++;
            } else if (index == 2) {
              _statsRefreshVersion++;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

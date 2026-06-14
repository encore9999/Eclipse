import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/statistics/presentation/screens/statistics_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: isDark ? AppColors.darkNavBar : Theme.of(context).colorScheme.surface,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: 'home'.tr()),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart_rounded), label: 'statistics'.tr()),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: 'settings'.tr()),
        ],
      ),
    );
  }
}
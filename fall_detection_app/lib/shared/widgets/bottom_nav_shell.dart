import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Persistent bottom navigation shell used by StatefulShellRoute.
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map),
      label: 'Map',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.watch_outlined),
      activeIcon: Icon(Icons.watch),
      label: 'Device',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primaryLight,
              unselectedItemColor: AppColors.textTertiary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: _items,
            ),
          ),
        ),
      ),
    );
  }
}

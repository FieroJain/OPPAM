
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fall_detection_app/features/auth/screens/splash_screen.dart';
import 'package:fall_detection_app/features/auth/screens/sign_in_screen.dart';
import 'package:fall_detection_app/features/auth/screens/sign_up_screen.dart';
import 'package:fall_detection_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:fall_detection_app/features/map/screens/map_screen.dart';
import 'package:fall_detection_app/features/history/screens/history_screen.dart';
import 'package:fall_detection_app/features/device/screens/device_pairing_screen.dart';
import 'package:fall_detection_app/features/device/screens/device_health_screen.dart';
import 'package:fall_detection_app/features/contacts/screens/contacts_screen.dart';
import 'package:fall_detection_app/features/settings/screens/settings_screen.dart';
import 'package:fall_detection_app/features/alert/screens/emergency_alert_screen.dart';
import 'package:fall_detection_app/features/patient/screens/patient_home_screen.dart';
import 'package:fall_detection_app/features/patient/screens/where_to_screen.dart';
import 'package:fall_detection_app/features/hospitals/screens/hospitals_screen.dart';
import 'package:fall_detection_app/screens/threshold_history.dart'; // ADDED
import 'package:fall_detection_app/shared/widgets/bottom_nav_shell.dart';
// Auth cubit used by auth routes internally

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/alert',
      builder: (context, state) => const EmergencyAlertScreen(),
    ),
    GoRoute(
      path: '/threshold-history',
      builder: (context, state) => const ThresholdHistoryScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/device-health',
      builder: (context, state) => const DeviceHealthScreen(),
    ),
    // Patient home screen
    GoRoute(
      path: '/patient',
      builder: (context, state) => const PatientHomeScreen(),
    ),
    // Where To? screen (patient)
    GoRoute(
      path: '/where-to',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return WhereToScreen(
          lat: extra?['lat'] as double?,
          lon: extra?['lon'] as double?,
        );
      },
    ),
    // Nearby Hospitals (caregiver)
    GoRoute(
      path: '/hospitals',
      builder: (context, state) => const HospitalsScreen(),
    ),
  
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/device',
            builder: (context, state) => const DevicePairingScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ]),
      ],
    ),
  ],
);
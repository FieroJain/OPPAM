import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fall_detection_app/app.dart';
import 'package:fall_detection_app/features/auth/screens/splash_screen.dart';
import 'package:fall_detection_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:fall_detection_app/features/alert/screens/emergency_alert_screen.dart';
import 'package:fall_detection_app/features/auth/cubit/auth_cubit.dart';
import 'package:fall_detection_app/features/alert/cubit/alert_cubit.dart';
import 'package:fall_detection_app/features/device/cubit/device_cubit.dart';
import 'package:fall_detection_app/features/map/cubit/geofence_cubit.dart';

/// Helper to wrap a widget with all required Cubits.
Widget _wrapWithProviders(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => AuthCubit()),
      BlocProvider(create: (_) => AlertCubit()),
      BlocProvider(create: (_) => DeviceCubit()),
      BlocProvider(create: (_) => GeofenceCubit()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('App Smoke Tests', () {
    testWidgets('FallDetectionApp renders without error', (tester) async {
      await tester.pumpWidget(const FallDetectionApp());
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('SplashScreen has Get Started button', (tester) async {
      await tester.pumpWidget(const FallDetectionApp());
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsOneWidget);
    });
  });

  group('Dashboard Tests', () {
    testWidgets('DashboardScreen loads core widgets', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const DashboardScreen()));
      await tester.pump();
      expect(find.text('Good Morning, Fiero'), findsOneWidget);
      expect(find.text('Fiero AI'), findsOneWidget);
    });
  });

  group('Alert Tests', () {
    testWidgets('EmergencyAlertScreen shows FALL DETECTED', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const EmergencyAlertScreen()));
      await tester.pump();
      expect(find.text('FALL DETECTED'), findsOneWidget);
      expect(find.text('DISPATCH NOW'), findsOneWidget);
    });
  });
}

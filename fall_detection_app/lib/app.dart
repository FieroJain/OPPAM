import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/alert/cubit/alert_cubit.dart';
import 'features/device/cubit/device_cubit.dart';
import 'features/map/cubit/geofence_cubit.dart';

class FallDetectionApp extends StatelessWidget {
  const FallDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => AlertCubit()),
        BlocProvider(create: (_) => DeviceCubit()),
        BlocProvider(create: (_) => GeofenceCubit()),
      ],
      child: MaterialApp.router(
        title: 'Fiero AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
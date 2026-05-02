import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../cubit/geofence_cubit.dart';
import '../../alert/cubit/alert_cubit.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeofenceCubit, GeofenceState>(
      builder: (context, geoState) {
        return BlocBuilder<AlertCubit, AlertState>(
          builder: (context, alertState) {
            final hasSOS = alertState.status == AlertStatus.sosTriggered ||
                alertState.status == AlertStatus.dispatched;
            return Scaffold(
              backgroundColor: AppColors.backgroundDark,
              body: Stack(
                children: [
                  _buildMapBackground(geoState, hasSOS),
                  _buildTopBar(context),
                  _buildStatusBanner(geoState, hasSOS),
                  _buildZoomControls(),
                  _buildBottomSheet(context, geoState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapBackground(GeofenceState state, bool hasSOS) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hasSOS
              ? [const Color(0xFFC89191), const Color(0xFFD49C9C)]
              : [
                  state.isInsideZone
                      ? const Color(0xFFC8B891)
                      : const Color(0xFF91A8C8),
                  state.isInsideZone
                      ? const Color(0xFFD4C49C)
                      : const Color(0xFF9CB0D4),
                ],
        ),
      ),
      child: Center(
        child: _buildGeofenceCircle(state, hasSOS),
      ),
    );
  }

  Widget _buildGeofenceCircle(GeofenceState state, bool hasSOS) {
    final size = (state.radiusMeters / 500) * 260;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${state.radiusMeters.toInt()}m Radius',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: size.clamp(120, 320),
          height: size.clamp(120, 320),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasSOS
                        ? Colors.red.withOpacity(0.6)
                        : Colors.blue.withOpacity(0.4),
                    width: hasSOS ? 2.5 : 1.5,
                  ),
                  color: hasSOS
                      ? Colors.red.withOpacity(0.08)
                      : Colors.blue.withOpacity(0.05),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Patient marker
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSOS ? Colors.red.shade600 : Colors.blue.shade600,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: hasSOS
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      hasSOS ? Icons.sos : Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Timestamp chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.patientLat != null
                          ? 'Updated ${state.patientLocationTime}'
                          : 'Waiting for patient...',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Address display
        if (state.patientAddress.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    state.patientAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        if (state.patientAddress.isNotEmpty) const SizedBox(height: 8),

        // Coordinates display
        if (state.patientLat != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '📍 ${state.patientLat!.toStringAsFixed(4)}, ${state.patientLon!.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),

        // SOS badge
        if (hasSOS) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.danger, width: 1.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sos, color: Colors.red, size: 18),
                SizedBox(width: 6),
                Text(
                  'SOS ACTIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(
                Icons.arrow_back,
                () => Navigator.of(context).maybePop(),
              ),
              _circleButton(Icons.settings, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBanner(GeofenceState state, bool hasSOS) {
    final Color bannerColor;
    final IconData bannerIcon;
    final String bannerText;

    if (hasSOS) {
      bannerColor = AppColors.danger;
      bannerIcon = Icons.sos;
      bannerText = '🚨 SOS Alert Active — Patient needs help!';
    } else if (state.patientLat != null) {
      bannerColor = AppColors.safe;
      bannerIcon = Icons.location_on;
      bannerText = 'Patient location received';
    } else {
      bannerColor = AppColors.danger;
      bannerIcon = Icons.location_off;
      bannerText = 'Waiting for patient location...';
    }

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(bannerIcon, color: bannerColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(color: bannerColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 300,
      child: Column(
        children: [
          _circleButton(Icons.add, () {}),
          const SizedBox(height: 8),
          _circleButton(Icons.remove, () {}),
          const SizedBox(height: 8),
          _circleButton(Icons.navigation, () {}),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, GeofenceState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: state.radiusMeters,
                min: 100,
                max: 1000,
                activeColor: AppColors.blueFg,
                onChanged: (v) {
                  context.read<GeofenceCubit>().setRadius(v);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
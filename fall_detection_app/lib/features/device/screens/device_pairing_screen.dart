import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../cubit/device_cubit.dart';
import '../../../shared/models/device_info.dart';

/// Device pairing screen.
class DevicePairingScreen extends StatelessWidget {
  const DevicePairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 16),
                  _buildWatchHero(state),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, state),
                  const SizedBox(height: 32),
                  _buildDiagnostics(state),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              AppStrings.devicePairing,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textTertiary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWatchHero(DeviceState state) {
    final isConnected =
        state.device.connectionState == DeviceConnectionState.connected;
    final statusText = isConnected
        ? 'Connected'
        : state.device.connectionState == DeviceConnectionState.searching
            ? AppStrings.searchingSignal
            : 'Disconnected';
    final statusColor = isConnected ? AppColors.accent : AppColors.blueFg;

    return Column(
      children: [
        // Watch with rings
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textTertiary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textTertiary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              // Dot accents
              Positioned(
                top: 40,
                left: 30,
                child: _dot(AppColors.accent.withValues(alpha: 0.6), 4),
              ),
              Positioned(
                top: 80,
                right: 20,
                child: _dot(AppColors.blueFg.withValues(alpha: 0.4), 5),
              ),
              // Watch image placeholder
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F2030), Color(0xFF051015)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blueFg.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.watch,
                  size: 64,
                  color: AppColors.blueFg.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.device.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DeviceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<DeviceCubit>().connectDevice();
              },
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text(AppStrings.scanQr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<DeviceCubit>().connectDevice();
              },
              icon: Icon(Icons.keyboard, size: 20, color: AppColors.textSecondary),
              label: Text(
                AppStrings.enterDeviceId,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics(DeviceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.deviceDiagnostics,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.greenGlow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.battery_charging_full,
                                color: AppColors.greenFg, size: 18),
                          ),
                          const Spacer(),
                          Text(
                            'GOOD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${state.device.batteryPercent}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Est. 12h remaining',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.device.batteryPercent / 100,
                          backgroundColor: AppColors.glassDark,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blueFg.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.cell_tower,
                                color: AppColors.blueFg, size: 18),
                          ),
                          const Spacer(),
                          Text(
                            'LTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blueFg,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${state.device.signalDbm} ',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'dBm',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Strong Connection',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Signal bars
                      Row(
                        children: List.generate(5, (i) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: i < 4
                                    ? AppColors.blueFg
                                    : AppColors.glassDark,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

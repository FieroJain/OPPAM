import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../cubit/device_cubit.dart';

/// Device health screen with battery ring, signal chart, and info cards.
class DeviceHealthScreen extends StatelessWidget {
  const DeviceHealthScreen({super.key});

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
                  const SizedBox(height: 20),
                  _buildBatteryRing(state),
                  const SizedBox(height: 32),
                  _buildSignalStrength(state),
                  const SizedBox(height: 24),
                  _buildInfoCards(context, state),
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
              AppStrings.deviceHealth,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textTertiary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryRing(DeviceState state) {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _BatteryRingPainter(
          percent: state.device.batteryPercent / 100,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: AppColors.accent, size: 28),
              const SizedBox(height: 4),
              Text(
                '${state.device.batteryPercent}%',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                state.device.estimatedLife,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalStrength(DeviceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.cell_tower, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SIGNAL STRENGTH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    state.device.signalQuality,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Mock signal bar chart
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _SignalBarPainter(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _signalLabel('-95 dBm'),
                _signalLabel('Stable Connection'),
                _signalLabel('0 Packet Loss'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _signalLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, DeviceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  Icon(Icons.developer_board, color: AppColors.textTertiary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Firmware',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v2.1.4',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        context.read<DeviceCubit>().updateFirmware();
                      },
                      child: Text(
                        state.isUpdating ? 'Updating...' : 'Check Update',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blueFg,
                        ),
                      ),
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
                children: [
                  Icon(Icons.sensors, color: AppColors.textTertiary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Sensors',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All Active',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Diagnostics',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blueFg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular battery indicator.
class _BatteryRingPainter extends CustomPainter {
  final double percent;

  _BatteryRingPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.cardDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          AppColors.accent,
          Color(0xFF34D399),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepAngle = 2 * pi * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryRingPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}

/// Mock signal strength bar chart.
class _SignalBarPainter extends CustomPainter {
  final _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = 2.0;
    final count = (size.width / (barWidth + gap)).floor();

    for (var i = 0; i < count; i++) {
      final height = 15.0 + _random.nextDouble() * (size.height - 20);
      final x = i * (barWidth + gap);

      final paint = Paint()
        ..color = AppColors.blueFg.withValues(
          alpha: 0.3 + _random.nextDouble() * 0.7,
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, barWidth, height),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

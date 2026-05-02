import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/ai_suggestion_service.dart';
import '../cubit/where_to_cubit.dart';

class WhereToScreen extends StatelessWidget {
  final double? lat;
  final double? lon;

  const WhereToScreen({super.key, this.lat, this.lon});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WhereToCubit()
        ..loadData(lat: lat ?? 12.971, lon: lon ?? 77.594),
      child: _WhereToView(lat: lat, lon: lon),
    );
  }
}

class _WhereToView extends StatefulWidget {
  final double? lat;
  final double? lon;

  const _WhereToView({this.lat, this.lon});

  @override
  State<_WhereToView> createState() => _WhereToViewState();
}

class _WhereToViewState extends State<_WhereToView> {
  final _destinationController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhereToCubit, WhereToState>(
      listener: (context, state) {
        if (state.status == WhereToStatus.submitted) {
          _showGoingOutConfirmation(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 24),
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildDestinationField(context),
                  const SizedBox(height: 20),
                  if (state.status == WhereToStatus.loading)
                    _buildLoading()
                  else ...[
                    _buildWeatherCard(state),
                    const SizedBox(height: 16),
                    if (state.suggestion != null)
                      _buildSuggestionCard(state),
                    const SizedBox(height: 16),
                    _buildFallHistoryCard(state),
                    const SizedBox(height: 32),
                    _buildActionButtons(context, state),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Where To?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blueFg.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.blueFg.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation, color: AppColors.blueFg, size: 14),
              SizedBox(width: 4),
              Text(
                'AI CHECK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueFg,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plan Your Trip 🗺️',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'AI checks weather, time & your health before you go',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorderLight),
      ),
      child: TextField(
        controller: _destinationController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Enter your destination...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blueFg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.place,
                color: AppColors.blueFg,
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        onChanged: (value) {
          context.read<WhereToCubit>().updateDestination(value);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.blueFg),
            SizedBox(height: 16),
            Text(
              'Analyzing conditions...',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(WhereToState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A4A),
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.blueFg.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.blueFg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(state.weatherCondition),
              color: AppColors.blueFg,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Weather',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.temperature.toStringAsFixed(0)}°C • ${state.weatherCondition}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (state.isRaining)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop,
                            color: AppColors.blueFg, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'Rain detected — slippery surfaces!',
                          style: TextStyle(
                            color: AppColors.blueFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(WhereToState state) {
    final suggestion = state.suggestion!;
    Color cardColor;
    Color borderColor;
    Color iconColor;
    IconData iconData;

    switch (suggestion.riskLevel) {
      case RiskLevel.safe:
        cardColor = const Color(0xFF0A2A1A);
        borderColor = AppColors.accent.withValues(alpha: 0.4);
        iconColor = AppColors.accent;
        iconData = Icons.check_circle;
        break;
      case RiskLevel.caution:
        cardColor = const Color(0xFF2A2A0A);
        borderColor = AppColors.warning.withValues(alpha: 0.4);
        iconColor = AppColors.warning;
        iconData = Icons.warning_amber;
        break;
      case RiskLevel.danger:
        cardColor = const Color(0xFF2A0A0A);
        borderColor = AppColors.danger.withValues(alpha: 0.4);
        iconColor = AppColors.danger;
        iconData = Icons.dangerous;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'AI RECOMMENDATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.message,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallHistoryCard(WhereToState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: state.recentFallCount > 0
                  ? AppColors.danger.withValues(alpha: 0.15)
                  : AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              color: state.recentFallCount > 0
                  ? AppColors.danger
                  : AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Fall History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.recentFallCount == 0
                      ? 'No falls in the last 7 days ✅'
                      : '${state.recentFallCount} fall(s) in the last 7 days ⚠️',
                  style: TextStyle(
                    color: state.recentFallCount > 0
                        ? AppColors.warning
                        : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WhereToState state) {
    final isSubmitting = state.status == WhereToStatus.submitting;
    return Column(
      children: [
        // GO NOW button
        GestureDetector(
          onTap: isSubmitting || state.destination.trim().isEmpty
              ? null
              : () {
                  context.read<WhereToCubit>().goNow(
                        lat: widget.lat,
                        lon: widget.lon,
                      );
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: state.destination.trim().isEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
              color: state.destination.trim().isEmpty
                  ? AppColors.glassDark
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: state.destination.trim().isNotEmpty
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSubmitting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.navigation, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  isSubmitting ? 'NOTIFYING CAREGIVER...' : 'GO NOW',
                  style: TextStyle(
                    color: state.destination.trim().isEmpty
                        ? AppColors.textTertiary
                        : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // STAY HOME button
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorderLight),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, color: AppColors.textSecondary, size: 22),
                SizedBox(width: 8),
                Text(
                  'STAY HOME',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGoingOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0A1A15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.accent, size: 28),
            SizedBox(width: 10),
            Text(
              'Caregiver Notified!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          '✅ Your caregiver has been notified.\n'
          '📍 Your destination and location were shared.\n'
          '🛡️ Stay safe out there!',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.7,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop(); // Return to patient home
            },
            child: const Text(
              'OK, GOT IT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }
}

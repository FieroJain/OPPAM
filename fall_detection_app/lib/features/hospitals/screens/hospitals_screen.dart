import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/hospital.dart';
import '../cubit/hospitals_cubit.dart';

/// Nearby hospitals screen — fetches real data from Overpass API.
class HospitalsScreen extends StatelessWidget {
  const HospitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HospitalsCubit()..loadHospitals(),
      child: const _HospitalsView(),
    );
  }
}

class _HospitalsView extends StatelessWidget {
  const _HospitalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: BlocBuilder<HospitalsCubit, HospitalsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case HospitalsStatus.initial:
                    case HospitalsStatus.loading:
                      return _buildLoading();
                    case HospitalsStatus.error:
                      return _buildError(context, state.errorMessage);
                    case HospitalsStatus.loaded:
                      if (state.hospitals.isEmpty) {
                        return _buildEmpty(context);
                      }
                      return _buildLoaded(context, state);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Expanded(
                child: Text(
                  'Nearby Hospitals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital,
                        color: AppColors.danger, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'EMERGENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Find the closest hospital and get help fast',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.glassBorder, height: 1),
        ],
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding nearby hospitals...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds...',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.danger,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Could not load hospitals',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<HospitalsCubit>().loadHospitals(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            color: AppColors.textTertiary,
            size: 56,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hospitals found within 5 km',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try again or expand your search area',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<HospitalsCubit>().loadHospitals(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loaded State ───────────────────────────────────────────────────────

  Widget _buildLoaded(BuildContext context, HospitalsState state) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.cardDark,
      onRefresh: () =>
          context.read<HospitalsCubit>().loadHospitals(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: state.hospitals.length + 1, // +1 for banner
        itemBuilder: (context, index) {
          if (index == 0) return _buildBanner(state);
          return _HospitalCard(
            hospital: state.hospitals[index - 1],
            patientLat: state.patientLat,
            patientLon: state.patientLon,
          );
        },
      ),
    );
  }

  // ── Location Banner ────────────────────────────────────────────────────

  Widget _buildBanner(HospitalsState state) {
    final isPatient = state.locationSource == 'patient';
    final text = isPatient
        ? '📍 Showing hospitals near patient'
        : '📍 Showing hospitals near your location';

    return Container(
      margin: const EdgeInsets.only(bottom: 14, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blueFg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blueFg.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPatient ? Icons.person_pin_circle : Icons.my_location,
            color: AppColors.blueFg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.blueFg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hospital Card ──────────────────────────────────────────────────────────

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final double? patientLat;
  final double? patientLon;

  const _HospitalCard({
    required this.hospital,
    this.patientLat,
    this.patientLon,
  });

  Color get _distanceColor {
    if (hospital.distanceKm < 2) return AppColors.accent;
    if (hospital.distanceKm <= 5) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hospital.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        hospital.address!,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Info chips ──────────────────────────────────────────
          Row(
            children: [
              _buildChip(
                Icons.navigation,
                '${hospital.distanceKm} km',
                _distanceColor,
              ),
              const SizedBox(width: 10),
              _buildChip(
                hospital.type == 'clinic'
                    ? Icons.medical_services
                    : Icons.local_hospital,
                (hospital.type ?? 'hospital').toUpperCase(),
                AppColors.purpleFg,
              ),
              if (hospital.phone != null) ...[
                const SizedBox(width: 10),
                _buildChip(
                  Icons.phone,
                  'Has Phone',
                  AppColors.greenFg,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // ── Action buttons ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: hospital.phone != null
                      ? Icons.call
                      : Icons.search,
                  label: hospital.phone != null
                      ? 'CALL NOW'
                      : 'FIND NUMBER',
                  color: hospital.phone != null
                      ? AppColors.accent
                      : AppColors.warning,
                  onTap: () => _onCallOrSearch(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.notifications_active,
                  label: 'ALERT',
                  color: AppColors.danger,
                  onTap: () => _onAlert(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.directions,
                  label: 'DIRECTIONS',
                  color: AppColors.blueFg,
                  onTap: () => _onDirections(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chip widget ──────────────────────────────────────────────────────

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action button widget ─────────────────────────────────────────────

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _onCallOrSearch(BuildContext context) async {
    Uri uri;
    if (hospital.phone != null) {
      uri = Uri.parse('tel:${hospital.phone}');
    } else {
      // Open Google Maps centered on the hospital — user can find phone there
      final query = Uri.encodeComponent(hospital.name);
      uri = Uri.parse(
        'https://www.google.com/maps/search/$query/@${hospital.lat},${hospital.lon},15z',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hospital.phone != null
                ? 'Could not open dialer'
                : 'Could not open maps'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _onAlert(BuildContext context) async {
    final firebase = FirebaseService();
    await firebase.writeHospitalAlert(
      hospitalName: hospital.name,
      hospitalPhone: hospital.phone ?? 'N/A',
      patientLat: patientLat,
      patientLon: patientLon,
      distanceKm: hospital.distanceKm,
    );

    if (context.mounted) {
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
              Expanded(
                child: Text(
                  'Hospital Alerted!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '🏥 ${hospital.name} has been alerted.\n'
            '📍 Patient location shared.\n'
            '📏 Distance: ${hospital.distanceKm} km\n'
            '🚑 Ambulance dispatch initiated.',
            style: const TextStyle(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'OK',
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
  }

  Future<void> _onDirections(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${hospital.lat},${hospital.lon}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

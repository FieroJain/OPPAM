import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/phone_utils.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/alert_cubit.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final userId =
          context.read<AuthCubit>().state.userId ?? 'default_user';
      final contacts = await FirebaseService().getContacts(userId);
      // Sort: high → family → caregiver
      const order = {'high': 0, 'family': 1, 'caregiver': 2};
      contacts.sort((a, b) {
        final pa = order[a['priority']] ?? 9;
        final pb = order[b['priority']] ?? 9;
        return pa.compareTo(pb);
      });
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  Future<void> _callContact(String rawPhone) async {
    final dialNumber = cleanPhoneForDial(rawPhone);
    final uri = Uri.parse('tel:$dialNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for $dialNumber'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AlertCubit, AlertState>(
      listener: (context, state) {
        if (state.status == AlertStatus.cancelled) {
          context.go('/dashboard');
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.alertBgGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildAlertIcon(),
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildPatientInfo(),
                    const SizedBox(height: 20),
                    _buildMapPreview(),
                    const SizedBox(height: 24),
                    _buildCountdownRing(state),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.autoConnecting,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDispatchButton(context),
                    const SizedBox(height: 12),
                    _buildHospitalsButton(context),
                    const SizedBox(height: 20),
                    _buildContactsSection(),
                    const SizedBox(height: 12),
                    _buildCancelButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.contacts, color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            const Text(
              'EMERGENCY CONTACTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/contacts'),
              child: Text(
                'Manage →',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingContacts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (_contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.person_add,
                    color: AppColors.textTertiary, size: 32),
                const SizedBox(height: 8),
                Text(
                  'No emergency contacts saved',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ADD CONTACTS',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else
          ..._contacts.map((contact) => _buildContactCard(contact)).toList(),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['name']?.toString() ?? 'Unknown';
    final phone = contact['phone']?.toString() ?? '';
    final role = contact['role']?.toString() ?? 'Contact';
    final priority = contact['priority']?.toString() ?? '';

    Color priorityColor;
    String priorityLabel;
    switch (priority) {
      case 'high':
        priorityColor = AppColors.danger;
        priorityLabel = 'HIGH';
        break;
      case 'family':
        priorityColor = AppColors.warning;
        priorityLabel = 'FAMILY';
        break;
      case 'caregiver':
        priorityColor = AppColors.accent;
        priorityLabel = 'CAREGIVER';
        break;
      default:
        priorityColor = AppColors.textTertiary;
        priorityLabel = 'CONTACT';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1A15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priorityColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: priorityColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$role • ${phone.isNotEmpty ? formatPhone(phone) : 'No number'}',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Call button
            ElevatedButton.icon(
              onPressed:
                  phone.isNotEmpty ? () => _callContact(phone) : null,
              icon: const Icon(Icons.call, size: 16),
              label: const Text(
                'CALL',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: priorityColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.textTertiary.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, color: AppColors.danger, size: 16),
              const SizedBox(width: 6),
              Text(
                AppStrings.criticalAlert,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.4),
            blurRadius: 24,
          ),
        ],
      ),
      child: const Icon(Icons.elderly, color: Colors.white, size: 36),
    );
  }

  Widget _buildTitle() {
    return const Text(
      AppStrings.fallDetected,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Column(
      children: [
        Text(
          AppStrings.patientName,
          style:
              TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on,
                color: AppColors.textTertiary, size: 16),
            const SizedBox(width: 4),
            Text(
              AppStrings.patientAddress,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF0F2518)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.terrain,
              size: 60, color: Colors.green.withValues(alpha: 0.2)),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownRing(AlertState state) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter:
            _CountdownRingPainter(progress: state.countdownSeconds / 10.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.callingIn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.countdownSeconds.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                AppStrings.seconds,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.read<AlertCubit>().dispatchNow(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              AppStrings.dispatchNow,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push('/hospitals'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A2A4A),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.blueFg.withValues(alpha: 0.4)),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, color: AppColors.blueFg, size: 20),
            SizedBox(width: 10),
            Text(
              'FIND NEARBY HOSPITALS',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueFg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.read<AlertCubit>().cancelAlert(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A3A),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel,
                color: Colors.white.withValues(alpha: 0.7), size: 20),
            const SizedBox(width: 8),
            Text(
              AppStrings.cancelAlert,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  _CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.danger.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [
            AppColors.danger.withValues(alpha: 0.4),
            AppColors.danger,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) =>
      old.progress != progress;
}
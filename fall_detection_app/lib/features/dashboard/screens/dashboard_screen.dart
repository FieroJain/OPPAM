import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/heartbeat_painter.dart';
import '../../alert/cubit/alert_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _heartbeatController;
  final FlutterTts _tts = FlutterTts();
  final FirebaseService _firebase = FirebaseService();

  String _userId = 'default_user';
  double _confidence = 0.0;
  bool _isMonitoring = true;
  String _statusText = 'Safe';
  bool _alertShown = false;
  bool _sosShown = false;
  bool _goingOutShown = false;

  double _rlThreshold = 2.5;
  String _actionTaken = 'HOLD';

  bool _preFallWarning = false;
  double _preFallError = 0.0;
  double _estimatedSeconds = 0.0;

  Map<String, double> _lastSensorData = {
    'ax': 0.0, 'ay': 0.0, 'az': 1.0,
    'gx': 0.0, 'gy': 0.0, 'gz': 0.0,
  };

  Map<String, dynamic>? _lastExplanation;

  @override
  void initState() {
    super.initState();

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    try {
      _userId = context.read<AuthCubit>().state.userId ?? 'default_user';
    } catch (_) {}

    print("🟢 Dashboard initialized — starting Firebase listeners");
    _listenToFalls();
    _listenToConfidence();
    _listenToSOS();
    _listenToGoingOut();
  }

  void _listenToFalls() {
    print("🟢 Setting up fall listener...");
    _firebase.fallStream.listen(
      (fallEvent) {
        print("🔥 FALL EVENT RECEIVED: $fallEvent");
        if (fallEvent != null && mounted && !_alertShown) {
          _alertShown = true;
          NotificationService.showFallAlert(confidence: _confidence);
          _tts.setLanguage("en-US");
          _tts.setSpeechRate(0.5);
          _tts.speak("Warning! Fall detected! Contacting caregiver immediately!");
          _autoCallEmergencyContact();
          context.read<AlertCubit>().triggerFallDetected(fall: fallEvent);
          context.push('/alert');
          Future.delayed(const Duration(seconds: 30), () {
            _alertShown = false;
          });
        }
      },
      onError: (error) {
        print("❌ Firebase listener error: $error");
      },
    );
  }

  void _listenToConfidence() {
    _firebase.liveStream.listen((live) {
      if (live != null && mounted) {
        setState(() {
          _confidence = (live['confidence'] ?? 0.0).toDouble();
          final preFallErr = (live['pre_fall_error'] ?? 0.0).toDouble();
          final preFallWarn = live['pre_fall_warning'] == true;

          if (_confidence > 0.5) {
            _statusText = '⚠️ Fall Risk High';
          } else if (preFallWarn && preFallErr > 10) {
            _confidence = (preFallErr / 100).clamp(0.0, 0.95);
            _statusText = '⚡ Instability Detected';
          } else if (preFallWarn) {
            _confidence = (preFallErr / 100).clamp(0.0, 0.5);
            _statusText = '⚡ Movement Detected';
          } else {
            _confidence = 0.05;
            _statusText = 'Safe';
          }

          _rlThreshold = (live['rl_threshold'] ?? 2.5).toDouble();
          _actionTaken = (live['rl_action'] ?? 'HOLD').toString();

          _preFallWarning = live['pre_fall_warning'] == true;
          _preFallError = (live['pre_fall_error'] ?? 0.0).toDouble();
          if (_preFallWarning && _preFallError > 0) {
            _estimatedSeconds =
                (5.0 - (_preFallError / 3.5) * 3).clamp(0.0, 10.0);
          }

          _lastSensorData = {
            'ax': (live['ax'] ?? 0.0).toDouble(),
            'ay': (live['ay'] ?? 0.0).toDouble(),
            'az': (live['az'] ?? 1.0).toDouble(),
            'gx': (live['gx'] ?? 0.0).toDouble(),
            'gy': (live['gy'] ?? 0.0).toDouble(),
            'gz': (live['gz'] ?? 0.0).toDouble(),
          };
        });
      }
    });
  }

  void _listenToSOS() {
    print("[Dashboard] 🟢 Setting up SOS listener...");
    _firebase.sosStream.listen(
      (sosData) {
        print("[Dashboard] 🆘 SOS RECEIVED: $sosData");
        if (sosData != null && mounted && !_sosShown) {
          _sosShown = true;

          final rawTs = sosData['timestamp']?.toString() ?? '';
          String displayTime = rawTs;
          try {
            final dt = DateTime.parse(rawTs).toLocal();
            displayTime =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
          } catch (_) {}

          final lat = sosData['lat'];
          final lon = sosData['lon'];
          final userId = sosData['userId']?.toString() ?? 'Unknown';
          final severity = sosData['severity']?.toString() ?? 'critical';

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF1C0404),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.danger, width: 2),
              ),
              title: Row(
                children: [
                  Icon(Icons.sos, color: AppColors.danger, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'SOS ALERT!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient pressed the SOS button!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _sosInfoRow(Icons.access_time, 'Time: $displayTime'),
                  const SizedBox(height: 6),
                  _sosInfoRow(Icons.person, 'User: $userId'),
                  const SizedBox(height: 6),
                  _sosInfoRow(Icons.warning,
                      'Severity: ${severity.toUpperCase()}'),
                  if (lat != null && lon != null) ...[
                    const SizedBox(height: 6),
                    _sosInfoRow(
                      Icons.location_on,
                      'Location: ${(lat as num).toStringAsFixed(4)}, ${(lon as num).toStringAsFixed(4)}',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.priority_high,
                            color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Patient needs immediate assistance!',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _sosShown = false;
                  },
                  child: Text(
                    'I AM RESPONDING',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _sosShown = false;
                    context
                        .read<AlertCubit>()
                        .triggerSOSFromFirebase(sosData);
                    context.push('/alert');
                  },
                  child: const Text('DISPATCH NOW',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ).then((_) {
            Future.delayed(const Duration(seconds: 5), () {
              _sosShown = false;
            });
          });
        }
      },
      onError: (error) {
        print("[Dashboard] ❌ SOS listener error: $error");
      },
    );
  }

  Widget _sosInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ),
      ],
    );
  }

  void _listenToGoingOut() {
    print("[Dashboard] 🚶 Setting up going-out listener...");
    _firebase.goingOutStream.listen(
      (data) {
        print("[Dashboard] 🚶 Going out event: $data");
        if (data != null && mounted && !_goingOutShown) {
          _goingOutShown = true;

          final destination = data['destination']?.toString() ?? 'Unknown';
          final weather = data['weather']?.toString() ?? 'Unknown';
          final aiSuggestion = data['ai_suggestion']?.toString() ?? '';
          final rawTs = data['timestamp']?.toString() ?? '';
          String displayTime = rawTs;
          try {
            final dt = DateTime.parse(rawTs).toLocal();
            displayTime =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {}

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF0A1A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: AppColors.blueFg.withValues(alpha: 0.5), width: 2),
              ),
              title: Row(
                children: [
                  Icon(Icons.directions_walk,
                      color: AppColors.blueFg, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Patient Going Out!',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _goingOutInfoRow(Icons.place, 'Destination: $destination'),
                  const SizedBox(height: 8),
                  _goingOutInfoRow(Icons.cloud, 'Weather: $weather'),
                  const SizedBox(height: 8),
                  _goingOutInfoRow(Icons.smart_toy, 'AI says: $aiSuggestion'),
                  const SizedBox(height: 8),
                  _goingOutInfoRow(Icons.access_time, 'Time: $displayTime'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blueFg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.blueFg.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.blueFg, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Patient has decided to go out.',
                            style: TextStyle(
                                color: AppColors.blueFg,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _goingOutShown = false;
                    context.push('/map');
                  },
                  child: const Text('TRACK LOCATION',
                      style: TextStyle(
                          color: AppColors.blueFg,
                          fontWeight: FontWeight.w700)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    _goingOutShown = false;
                    final uri = Uri.parse('tel:+911234567890');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: const Text('CALL PATIENT',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ).then((_) {
            Future.delayed(const Duration(seconds: 5), () {
              _goingOutShown = false;
            });
          });
        }
      },
      onError: (error) {
        print("[Dashboard] ❌ Going out listener error: $error");
      },
    );
  }

  Widget _goingOutInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _autoCallEmergencyContact() async {
    try {
      final contacts = await _firebase.getContacts(_userId);
      if (contacts.isEmpty) return;
      const order = {'high': 0, 'family': 1, 'caregiver': 2};
      contacts.sort((a, b) {
        final pa = order[a['priority']] ?? 9;
        final pb = order[b['priority']] ?? 9;
        return pa.compareTo(pb);
      });
      final phone = contacts.first['phone']?.toString() ?? '';
      if (phone.isEmpty) return;
      await Future.delayed(const Duration(seconds: 4));
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      print('[Dashboard] ❌ Auto-call error: $e');
    }
  }

  Future<void> _showExplanationDialog() async {
    try {
      final result = await ApiService.getExplanation(_lastSensorData);
      if (!mounted || result.containsKey('error')) return;

      _lastExplanation = result;
      final importance =
          Map<String, dynamic>.from(result['importance'] ?? {});
      final topFeature = result['top_feature'] ?? '';
      final interpretation = result['interpretation'] ?? '';
      final features = ['ax', 'ay', 'az', 'gx', 'gy', 'gz'];
      final values =
          features.map((f) => (importance[f] ?? 0.0).toDouble()).toList();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side:
                BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.accent, size: 24),
              SizedBox(width: 10),
              Text('Why this prediction?',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 1.0,
                      barGroups: List.generate(6, (i) {
                        final isTop = features[i] == topFeature;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: isTop
                                  ? AppColors.danger
                                  : AppColors.accent,
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < features.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    features[idx],
                                    style: TextStyle(
                                      color: features[idx] == topFeature
                                          ? AppColors.danger
                                          : AppColors.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 0.25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  interpretation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load explanation: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildGreeting(),
              if (_preFallWarning)
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Instability detected — sit down slowly',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Est. ${_estimatedSeconds.toStringAsFixed(1)}s | Error: ${_preFallError.toStringAsFixed(4)}',
                              style: TextStyle(
                                color:
                                    AppColors.warning.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              _buildHeartbeatLine(),
              _buildRLThresholdCard(),
              _buildPatientHeroCard(),
              _buildConfidenceBar(),
              _buildMetricsGrid(),
              _buildQuickActions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.medical_services,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMonitoring ? 'MONITORING ACTIVE' : 'MONITORING OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _isMonitoring ? AppColors.accent : AppColors.danger,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isMonitoring = !_isMonitoring),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isMonitoring
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _isMonitoring
                        ? AppColors.accent
                        : AppColors.danger),
              ),
              child: Text(
                _isMonitoring ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      _isMonitoring ? AppColors.accent : AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.goodMorning,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.monitoringSince,
              style:
                  TextStyle(fontSize: 14, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildHeartbeatLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: AnimatedBuilder(
              animation: _heartbeatController,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, 60),
                painter: HeartbeatPainter(
                    animationValue: _heartbeatController.value),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('60 BPM',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('LIVE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                ],
              ),
              Text('120 BPM',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _confidence > 0.95
                ? AppColors.danger.withValues(alpha: 0.5)
                : AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fall Risk Level',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _confidence > 0.95
                        ? AppColors.danger
                        : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _confidence,
                minHeight: 8,
                backgroundColor: AppColors.glassDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _confidence > 0.95
                      ? AppColors.danger
                      : _confidence > 0.5
                          ? AppColors.warning
                          : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeroCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3A2A), Color(0xFF0A1A15)],
            ),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4), width: 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.withValues(alpha: 0.1),
                          AppColors.backgroundDark.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.person,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.backgroundDark.withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: _confidence > 0.95
                            ? '⚠️ FALL DETECTED'
                            : AppStrings.statusSafe,
                      ),
                      const SizedBox(height: 8),
                      const Text(AppStrings.patientName,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(AppStrings.patientLocation,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(AppStrings.liveCam,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.directions_walk,
                  iconBgColor: AppColors.blueGlow,
                  iconColor: AppColors.blueFg,
                  value: '1,240',
                  label: 'Steps Taken',
                  topRight: 'Today',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricTile(
                  icon: Icons.favorite,
                  iconBgColor: AppColors.redGlow,
                  iconColor: AppColors.redFg,
                  value: '72',
                  unit: 'bpm',
                  label: 'Resting Rate',
                  topRight: 'Avg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.battery_full,
                  iconBgColor: AppColors.greenGlow,
                  iconColor: AppColors.greenFg,
                  value: '94%',
                  label: 'Device Battery',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricTile(
                  icon: Icons.wifi,
                  iconBgColor: AppColors.purpleGlow,
                  iconColor: AppColors.purpleFg,
                  value: 'Strong',
                  label: 'Signal Quality',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.quickActions,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.contacts,
                  label: 'Contacts',
                  gradient: AppColors.callGradient,
                  onTap: () => context.push('/contacts'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  icon: Icons.emergency_share,
                  label: AppStrings.sosAlert,
                  gradient: AppColors.sosGradient,
                  onTap: () {
                    context.read<AlertCubit>().triggerSOS();
                    context.push('/alert');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRLThresholdCard() {
    final isLow = _rlThreshold < 2.5;
    final thresholdColor = isLow ? AppColors.accent : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GestureDetector(
        onTap: () => context.push('/threshold-history'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: thresholdColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: thresholdColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune, color: thresholdColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adaptive Threshold',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      '${_rlThreshold.toStringAsFixed(2)} g',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: thresholdColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: thresholdColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_actionTaken,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: thresholdColor)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _showExplanationDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purpleGlow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology,
                                  color: AppColors.purpleFg, size: 12),
                              SizedBox(width: 4),
                              Text('Why?',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purpleFg)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right,
                          color: AppColors.textTertiary, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
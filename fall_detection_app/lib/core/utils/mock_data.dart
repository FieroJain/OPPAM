import 'package:fall_detection_app/shared/models/fall_event.dart';
import 'package:fall_detection_app/shared/models/emergency_contact.dart';
import 'package:fall_detection_app/shared/models/device_info.dart';

/// Centralized mock data for prototyping all screens.
class MockData {
  MockData._();

  // ── Fall Events ──────────────────────────────────────────────────
  static final List<FallEvent> fallEvents = [
    FallEvent(
      id: '1',
      title: 'Hard Fall Detected',
      location: 'Living Room',
      zone: 'Zone B',
      timestamp: DateTime.now().subtract(const Duration(hours: 20)),
      severity: FallSeverity.high,
      responseTime: '45s',
      detail: 'Impact detected via accelerometer spike',
    ),
    FallEvent(
      id: '2',
      title: 'Unusual Gait',
      location: 'Kitchen',
      zone: 'Zone A',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      severity: FallSeverity.medium,
      metric: 'Balance -15%',
    ),
    FallEvent(
      id: '3',
      title: 'System Check',
      location: '',
      zone: '',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      severity: FallSeverity.info,
      detail: 'Automated diagnostics complete',
    ),
  ];

  // ── Weekly Chart Data (days of the week, value 0-10) ─────────────
  static const List<double> weeklyChartData = [3, 5, 6, 4, 7, 5, 8];

  // ── Emergency Contacts ───────────────────────────────────────────
  static final List<EmergencyContact> contacts = [
    const EmergencyContact(
      id: '1',
      name: 'Dr. Emily Chen',
      role: 'Primary Physician',
      priority: ContactPriority.high,
      detail: 'St. Mary...',
      isEnabled: true,
    ),
    const EmergencyContact(
      id: '2',
      name: 'Mark Thom...',
      role: 'Son',
      priority: ContactPriority.family,
      detail: '(555) 123-4567',
      phone: '(555) 123-4567',
      isEnabled: true,
    ),
    const EmergencyContact(
      id: '3',
      name: 'Sarah Je...',
      role: 'Live-in Nurse',
      priority: ContactPriority.caregiver,
      detail: 'Shift: Days',
      isEnabled: false,
    ),
    const EmergencyContact(
      id: '4',
      name: 'John Doe',
      role: 'Next Door',
      priority: ContactPriority.neighbor,
      detail: '(555) 987-6543',
      phone: '(555) 987-6543',
      isEnabled: false,
    ),
  ];

  // ── Device Info ──────────────────────────────────────────────────
  static const DeviceInfo device = DeviceInfo(
    name: 'Sentinel X1',
    batteryPercent: 84,
    estimatedLife: 'Est. 4 Days',
    signalDbm: -65,
    signalQuality: 'EXCELLENT',
    connectionState: DeviceConnectionState.searching,
  );
}

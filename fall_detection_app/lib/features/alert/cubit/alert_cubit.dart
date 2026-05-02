import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/fall_event.dart';

enum AlertStatus { idle, fallDetected, sosTriggered, dispatched, cancelled }

class AlertState {
  final AlertStatus status;
  final int countdownSeconds;
  final FallEvent? latestFall;
  // SOS metadata from Firebase
  final String? sosUserId;
  final double? sosLat;
  final double? sosLon;
  final String? sosTimestamp;
  final String? sosSeverity;
  final String? sosMessage;

  const AlertState({
    this.status = AlertStatus.idle,
    this.countdownSeconds = 10,
    this.latestFall,
    this.sosUserId,
    this.sosLat,
    this.sosLon,
    this.sosTimestamp,
    this.sosSeverity,
    this.sosMessage,
  });

  AlertState copyWith({
    AlertStatus? status,
    int? countdownSeconds,
    FallEvent? latestFall,
    String? sosUserId,
    double? sosLat,
    double? sosLon,
    String? sosTimestamp,
    String? sosSeverity,
    String? sosMessage,
  }) {
    return AlertState(
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      latestFall: latestFall ?? this.latestFall,
      sosUserId: sosUserId ?? this.sosUserId,
      sosLat: sosLat ?? this.sosLat,
      sosLon: sosLon ?? this.sosLon,
      sosTimestamp: sosTimestamp ?? this.sosTimestamp,
      sosSeverity: sosSeverity ?? this.sosSeverity,
      sosMessage: sosMessage ?? this.sosMessage,
    );
  }
}

class AlertCubit extends Cubit<AlertState> {
  Timer? _timer;

  AlertCubit() : super(const AlertState());

  void triggerFallDetected({FallEvent? fall}) {
    _timer?.cancel();
    emit(state.copyWith(
      status: AlertStatus.fallDetected,
      countdownSeconds: 10,
      latestFall: fall,
    ));
    _startCountdown();
  }

  /// Local SOS trigger (e.g. caregiver presses SOS button on dashboard).
  void triggerSOS() {
    _timer?.cancel();
    emit(state.copyWith(
      status: AlertStatus.sosTriggered,
      countdownSeconds: 10,
    ));
    _startCountdown();
  }

  /// SOS triggered from Firebase stream with full metadata.
  void triggerSOSFromFirebase(Map<String, dynamic> sosData) {
    _timer?.cancel();
    print('[AlertCubit] 🆘 SOS from Firebase: $sosData');
    emit(AlertState(
      status: AlertStatus.sosTriggered,
      countdownSeconds: 10,
      sosUserId: sosData['userId']?.toString(),
      sosLat: (sosData['lat'] as num?)?.toDouble(),
      sosLon: (sosData['lon'] as num?)?.toDouble(),
      sosTimestamp: sosData['timestamp']?.toString(),
      sosSeverity: sosData['severity']?.toString() ?? 'critical',
      sosMessage: sosData['message']?.toString(),
    ));
    _startCountdown();
  }

  void dispatchNow() {
    _timer?.cancel();
    emit(state.copyWith(status: AlertStatus.dispatched));
  }

  void cancelAlert() {
    _timer?.cancel();
    emit(state.copyWith(status: AlertStatus.cancelled));
    Future.delayed(const Duration(seconds: 1), () {
      if (!isClosed) emit(const AlertState());
    });
  }

  void reset() {
    _timer?.cancel();
    emit(const AlertState());
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCount = state.countdownSeconds - 1;
      if (newCount <= 0) {
        timer.cancel();
        emit(state.copyWith(
          status: AlertStatus.dispatched,
          countdownSeconds: 0,
        ));
      } else {
        emit(state.copyWith(countdownSeconds: newCount));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
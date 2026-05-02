import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firebase_service.dart';

class GeofenceState {
  final bool isInsideZone;
  final double radiusMeters;
  final double? patientLat;
  final double? patientLon;
  final String patientLocationTime;
  final String patientAddress;

  const GeofenceState({
    this.isInsideZone = true,
    this.radiusMeters = 500,
    this.patientLat,
    this.patientLon,
    this.patientLocationTime = 'No location yet',
    this.patientAddress = '',
  });

  GeofenceState copyWith({
    bool? isInsideZone,
    double? radiusMeters,
    double? patientLat,
    double? patientLon,
    String? patientLocationTime,
    String? patientAddress,
  }) {
    return GeofenceState(
      isInsideZone: isInsideZone ?? this.isInsideZone,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      patientLat: patientLat ?? this.patientLat,
      patientLon: patientLon ?? this.patientLon,
      patientLocationTime: patientLocationTime ?? this.patientLocationTime,
      patientAddress: patientAddress ?? this.patientAddress,
    );
  }
}

class GeofenceCubit extends Cubit<GeofenceState> {
  final FirebaseService _firebase = FirebaseService();
  StreamSubscription? _locationSub;

  GeofenceCubit() : super(const GeofenceState()) {
    _listenToPatientLocation();
  }

  void _listenToPatientLocation() {
    print('[GeofenceCubit] 📍 Starting patient location listener...');
    _locationSub = _firebase.patientLocationStream.listen((data) async {
      if (data == null) return;

      try {
        final lat = (data['lat'] ?? 0.0).toDouble();
        final lon = (data['lon'] ?? 0.0).toDouble();
        final timestamp = data['timestamp']?.toString() ?? '';

        print('[GeofenceCubit] 📍 Location update received: '
            'lat=$lat, lon=$lon, timestamp=$timestamp');

        // Emit coordinates immediately
        emit(state.copyWith(
          patientLat: lat,
          patientLon: lon,
          patientLocationTime: _formatTime(timestamp),
        ));

        // Reverse geocode in background
        final address = await _firebase.reverseGeocode(lat, lon);
        if (!isClosed) {
          emit(state.copyWith(patientAddress: address));
          print('[GeofenceCubit] 🗺️ Address resolved: $address');
        }
      } catch (e) {
        print('[GeofenceCubit] ❌ Location parse error: $e');
      }
    });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void toggleZoneStatus() {
    emit(state.copyWith(isInsideZone: !state.isInsideZone));
  }

  void setRadius(double radius) {
    emit(state.copyWith(radiusMeters: radius));
  }

  @override
  Future<void> close() {
    _locationSub?.cancel();
    return super.close();
  }
}
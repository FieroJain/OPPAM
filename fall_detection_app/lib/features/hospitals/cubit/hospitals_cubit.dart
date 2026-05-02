import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/hospital_service.dart';
import '../../../shared/models/hospital.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum HospitalsStatus { initial, loading, loaded, error }

class HospitalsState {
  final HospitalsStatus status;
  final List<Hospital> hospitals;
  final String? errorMessage;
  /// "patient" if using Firebase GPS, "device" if using device GPS.
  final String locationSource;
  final double? patientLat;
  final double? patientLon;

  const HospitalsState({
    this.status = HospitalsStatus.initial,
    this.hospitals = const [],
    this.errorMessage,
    this.locationSource = 'device',
    this.patientLat,
    this.patientLon,
  });

  HospitalsState copyWith({
    HospitalsStatus? status,
    List<Hospital>? hospitals,
    String? errorMessage,
    String? locationSource,
    double? patientLat,
    double? patientLon,
  }) {
    return HospitalsState(
      status: status ?? this.status,
      hospitals: hospitals ?? this.hospitals,
      errorMessage: errorMessage ?? this.errorMessage,
      locationSource: locationSource ?? this.locationSource,
      patientLat: patientLat ?? this.patientLat,
      patientLon: patientLon ?? this.patientLon,
    );
  }
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class HospitalsCubit extends Cubit<HospitalsState> {
  HospitalsCubit() : super(const HospitalsState());

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Load nearby hospitals.
  /// Step 1: Try patient location from Firebase /patient_location
  /// Step 2: Fallback to device GPS via Geolocator
  /// Step 3: Query Overpass API via HospitalService
  Future<void> loadHospitals() async {
    emit(state.copyWith(status: HospitalsStatus.loading));

    try {
      double lat;
      double lon;
      String source;

      // Step 1 — try Firebase patient location
      final snapshot = await _db.child('patient_location').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final fbLat = (data['lat'] as num?)?.toDouble();
        final fbLon = (data['lon'] as num?)?.toDouble();
        if (fbLat != null && fbLon != null) {
          lat = fbLat;
          lon = fbLon;
          source = 'patient';
          print('[HospitalsCubit] 📍 Using Firebase patient location: '
              '$lat, $lon');
        } else {
          final pos = await _getDevicePosition();
          lat = pos.latitude;
          lon = pos.longitude;
          source = 'device';
        }
      } else {
        // Step 2 — fallback to device GPS
        final pos = await _getDevicePosition();
        lat = pos.latitude;
        lon = pos.longitude;
        source = 'device';
      }

      // Step 3 — fetch hospitals from Overpass API
      final hospitals =
          await HospitalService.getNearbyHospitals(lat, lon);

      print('[HospitalsCubit] 🏥 Found ${hospitals.length} hospitals '
          '(source: $source)');

      emit(state.copyWith(
        status: HospitalsStatus.loaded,
        hospitals: hospitals,
        locationSource: source,
        patientLat: lat,
        patientLon: lon,
      ));
    } catch (e) {
      print('[HospitalsCubit] ❌ Error loading hospitals: $e');
      emit(state.copyWith(
        status: HospitalsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<Position> _getDevicePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    print('[HospitalsCubit] 📍 Using device GPS');
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}

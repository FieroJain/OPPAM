import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import '../../shared/models/fall_event.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  DateTime? _listenStartTime;

  void resetListenTime() {
    _listenStartTime = DateTime.now();
    print('[FirebaseService] ⏱️ Listen time reset to $_listenStartTime');
  }

  bool _isNew(String? timestampStr) {
    _listenStartTime ??= DateTime.now();
    if (timestampStr == null) return false;
    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return true; // if can't parse assume new
    return timestamp.isAfter(
        _listenStartTime!.subtract(const Duration(seconds: 10)));
  }

  // ── SOS: Write ────────────────────────────────────────────────────
  /// Centralized SOS write — called from Patient UI.
  Future<void> sendSOS({
    required double? lat,
    required double? lon,
    String? userId,
    String severity = 'critical',
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      await _db.child('sos').push().set({
        'sos': true,
        'timestamp': timestamp,
        'lat': lat,
        'lon': lon,
        'userId': userId ?? 'unknown',
        'severity': severity,
        'message': 'SOS button pressed by patient!',
      });
      print('[FirebaseService] 🆘 SOS written to Firebase | '
          'userId=$userId, severity=$severity, '
          'lat=$lat, lon=$lon, timestamp=$timestamp');
    } catch (e) {
      print('[FirebaseService] ❌ SOS write error: $e');
    }
  }

  // ── SOS: Stream ───────────────────────────────────────────────────
  /// Stream of real-time SOS events (for Caregiver side).
  Stream<Map<String, dynamic>?> get sosStream {
    _listenStartTime ??= DateTime.now();
    print('[FirebaseService] 🆘 SOS stream listener started at $_listenStartTime');
    return _db.child('sos').onChildAdded.map((event) {
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final timestampStr = data['timestamp']?.toString();
        final isNew = _isNew(timestampStr);
        print('[FirebaseService] 🆘 SOS received: '
            'timestamp=$timestampStr, isNew=$isNew, '
            'userId=${data['userId']}, severity=${data['severity']}');
        if (!isNew) return null;
        return data;
      } catch (e) {
        print('[FirebaseService] ❌ SOS parse error: $e');
        return null;
      }
    }).where((event) => event != null);
  }

  // ── Falls: Stream ─────────────────────────────────────────────────
  Stream<FallEvent?> get fallStream {
    _listenStartTime ??= DateTime.now();
    print('[FirebaseService] 📡 Fall stream listener started at $_listenStartTime');
    return _db.child('falls').onChildAdded.map((event) {
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final timestampStr = data['timestamp']?.toString();
        final isNew = _isNew(timestampStr);
        print('[FirebaseService] 📡 Fall received: '
            'timestamp=$timestampStr, isNew=$isNew');
        if (!isNew) return null;
        final timestamp =
            DateTime.tryParse(timestampStr ?? '') ?? DateTime.now();
        return FallEvent(
          id: event.snapshot.key ?? DateTime.now().toString(),
          title: 'Fall Detected',
          location: 'ESP32 Sensor',
          zone: 'Home',
          timestamp: timestamp,
          severity: FallSeverity.high,
          metric:
              'Confidence: ${((data['confidence'] ?? 0) * 100).toStringAsFixed(0)}%',
        );
      } catch (e) {
        print('[FirebaseService] ❌ Fall parse error: $e');
        return null;
      }
    }).where((event) => event != null);
  }

  // ── Patient Location: Write ───────────────────────────────────────
  /// Centralized location write — called from Patient UI.
  Future<void> updatePatientLocation({
    required double lat,
    required double lon,
    required double accuracy,
    String? userId,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      await _db.child('patient_location').set({
        'lat': lat,
        'lon': lon,
        'timestamp': timestamp,
        'accuracy': accuracy,
        'userId': userId ?? 'unknown',
      });
      print('[FirebaseService] 📍 Location written: '
          'lat=$lat, lon=$lon, accuracy=$accuracy, timestamp=$timestamp');
    } catch (e) {
      print('[FirebaseService] ❌ Location write error: $e');
    }
  }

  // ── Patient Location: Stream ──────────────────────────────────────
  Stream<Map<String, dynamic>?> get patientLocationStream {
    print('[FirebaseService] 📍 Patient location stream listener started');
    return _db.child('patient_location').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      try {
        final data =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        print('[FirebaseService] 📍 Location update: '
            'lat=${data['lat']}, lon=${data['lon']}, '
            'timestamp=${data['timestamp']}');
        return data;
      } catch (e) {
        print('[FirebaseService] ❌ Location parse error: $e');
        return null;
      }
    });
  }

  // ── Fall History ──────────────────────────────────────────────────
  Future<List<FallEvent>> getFallHistory() async {
    final snapshot = await _db.child('falls').get();
    if (!snapshot.exists) return [];
    final List<FallEvent> events = [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data.forEach((key, value) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        events.add(FallEvent(
          id: key,
          title: 'Fall Detected',
          location: 'ESP32 Sensor',
          zone: 'Home',
          timestamp:
              DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
          severity: FallSeverity.high,
          metric:
              'Confidence: ${((map['confidence'] ?? 0) * 100).toStringAsFixed(0)}%',
        ));
      } catch (e) {
        print('[FirebaseService] ❌ History parse error: $e');
      }
    });
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  // ── Live Confidence Stream ────────────────────────────────────────
  Stream<double> get confidenceStream {
    return _db.child('live').onValue.map((event) {
      if (!event.snapshot.exists) return 0.0;
      try {
        final data =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        return (data['confidence'] ?? 0.0).toDouble();
      } catch (e) {
        return 0.0;
      }
    });
  }
 // ── Live Full Data Stream (RL + LSTM + Confidence) ────────────────
  Stream<Map<String, dynamic>?> get liveStream {
    return _db.child('live').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      try {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      } catch (e) {
        return null;
      }
    });
  }

  // ── Reverse Geocoding Helper ──────────────────────────────────────
  /// Converts lat/lon to a human-readable address string.
  Future<String> reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
        ];
        final address =
            parts.isNotEmpty ? parts.join(', ') : '$lat, $lon';
        print('[FirebaseService] 🗺️ Reverse geocoded: $address');
        return address;
      }
    } catch (e) {
      print('[FirebaseService] ⚠️ Reverse geocode error: $e');
    }
    return '$lat, $lon';
  }

  // ── Patient Going Out: Write ──────────────────────────────────────
  Future<void> writePatientGoingOut({
    required String destination,
    required String weather,
    required String aiSuggestion,
    required double? lat,
    required double? lon,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      await _db.child('patient_going_out').push().set({
        'destination': destination,
        'timestamp': timestamp,
        'weather': weather,
        'ai_suggestion': aiSuggestion,
        'patient_lat': lat,
        'patient_lon': lon,
      });
      print('[FirebaseService] 🚶 Patient going out: '
          'destination=$destination, weather=$weather');
    } catch (e) {
      print('[FirebaseService] ❌ Going out write error: $e');
    }
  }

  // ── Patient Going Out: Stream (for Caregiver) ─────────────────────
  Stream<Map<String, dynamic>?> get goingOutStream {
    _listenStartTime ??= DateTime.now();
    print('[FirebaseService] 🚶 Going out stream started at $_listenStartTime');
    return _db.child('patient_going_out').onChildAdded.map((event) {
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final timestampStr = data['timestamp']?.toString();
        final isNew = _isNew(timestampStr);
        print('[FirebaseService] 🚶 Going out event: '
            'timestamp=$timestampStr, isNew=$isNew');
        if (!isNew) return null;
        return data;
      } catch (e) {
        print('[FirebaseService] ❌ Going out parse error: $e');
        return null;
      }
    }).where((event) => event != null);
  }

  // ── Hospital Alert: Write ─────────────────────────────────────────
  Future<void> writeHospitalAlert({
    required String hospitalName,
    required String hospitalPhone,
    required double? patientLat,
    required double? patientLon,
    double? fallConfidence,
    double? distanceKm,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    try {
      await _db.child('hospital_alerts').push().set({
        'hospital_name': hospitalName,
        'hospital_phone': hospitalPhone,
        'patient_lat': patientLat,
        'patient_lon': patientLon,
        'distance_km': distanceKm,
        'fall_confidence': fallConfidence ?? 0.0,
        'timestamp': timestamp,
        'status': 'alerted',
      });
      print('[FirebaseService] 🏥 Hospital alerted: $hospitalName');
    } catch (e) {
      print('[FirebaseService] ❌ Hospital alert error: $e');
    }
  }

  // ── Recent Fall Count ─────────────────────────────────────────────
  Future<int> getRecentFallCount({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _db.child('falls').get();
    if (!snapshot.exists) return 0;
    int count = 0;
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data.forEach((key, value) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        final ts = DateTime.tryParse(map['timestamp'] ?? '');
        if (ts != null && ts.isAfter(cutoff)) count++;
      } catch (_) {}
    });
    print('[FirebaseService] 📊 Recent falls (last $days days): $count');
    return count;
  }

  // ── Contacts CRUD ─────────────────────────────────────────────────
  Future<void> saveContact({
    required String userId,
    required String name,
    required String phone,
    required String role,
    required String priority,
    String? contactId,
  }) async {
    final ref = contactId != null
        ? _db.child('contacts/$userId/$contactId')
        : _db.child('contacts/$userId').push();
    try {
      await ref.set({
        'name': name,
        'phone': phone,
        'role': role,
        'priority': priority,
        'isEnabled': true,
      });
      print('[FirebaseService] 📇 Contact saved: $name ($phone)');
    } catch (e) {
      print('[FirebaseService] ❌ Contact save error: $e');
    }
  }

  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _db.child('contacts/$userId/$contactId').remove();
      print('[FirebaseService] 🗑️ Contact deleted: $contactId');
    } catch (e) {
      print('[FirebaseService] ❌ Contact delete error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    final snapshot = await _db.child('contacts/$userId').get();
    if (!snapshot.exists) return [];
    final List<Map<String, dynamic>> contacts = [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data.forEach((key, value) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        map['id'] = key;
        contacts.add(map);
      } catch (e) {
        print('[FirebaseService] ❌ Contact parse error: $e');
      }
    });
    return contacts;
  }
}
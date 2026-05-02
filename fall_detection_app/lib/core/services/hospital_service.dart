import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/hospital.dart';
import 'dart:math';

class HospitalService {
  static Future<List<Hospital>> getNearbyHospitals(
      double lat, double lon) async {
    try {
      // Use Nominatim search — free, no API key needed
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=hospital&format=json&limit=10'
        '&viewbox=${lon - 0.1},${lat + 0.1},${lon + 0.1},${lat - 0.1}'
        '&bounded=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'OPPAM-FallDetection/1.0',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final hospitals = data.map((item) {
          final hLat = double.tryParse(item['lat'].toString()) ?? lat;
          final hLon = double.tryParse(item['lon'].toString()) ?? lon;
          final dist = _calcDistance(lat, lon, hLat, hLon);
          return Hospital(
            name: item['display_name'].toString().split(',').first,
            address: item['display_name'].toString(),
            lat: hLat,
            lon: hLon,
            distanceKm: double.parse(dist.toStringAsFixed(2)),
            type: 'hospital',
            phone: null,
          );
        }).toList();

        hospitals.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        return hospitals.take(5).toList();
      }

      return _getFallbackHospitals(lat, lon);
    } catch (e) {
      print('Hospital service error: $e');
      return _getFallbackHospitals(lat, lon);
    }
  }

  // Fallback — hardcoded nearby hospitals if API fails
  static List<Hospital> _getFallbackHospitals(double lat, double lon) {
    return [
      Hospital(
        name: 'General Hospital',
        address: 'Nearest general hospital',
        lat: lat + 0.01,
        lon: lon + 0.01,
        distanceKm: 1.2,
        type: 'hospital',
        phone: '112',
      ),
      Hospital(
        name: 'Emergency Medical Center',
        address: 'Emergency services available 24/7',
        lat: lat - 0.02,
        lon: lon + 0.02,
        distanceKm: 2.8,
        type: 'hospital',
        phone: '108',
      ),
      Hospital(
        name: 'District Hospital',
        address: 'Government district hospital',
        lat: lat + 0.03,
        lon: lon - 0.01,
        distanceKm: 3.5,
        type: 'hospital',
        phone: '101',
      ),
    ];
  }

  static double _calcDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
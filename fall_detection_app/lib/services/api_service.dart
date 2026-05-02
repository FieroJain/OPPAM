import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Fall Detection FastAPI server.
///
/// All methods are static for convenience. Change [baseUrl] to point
/// to your server (e.g. local IP for development).
class ApiService {
  // Change this to your server's address
  static const String baseUrl = 'http://192.168.137.1:8000'; // Android emulator → localhost

  // ── Original predict method (PRESERVED) ────────────────────────────

  /// Calls the original `/predict` CNN-only endpoint.
  static Future<Map<String, dynamic>> predictFall(
      Map<String, double> sensorData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sensorData),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Server returned ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ADDED — /predict_rl  (CNN + RL Ensemble)
  /// Calls `/predict_rl` for CNN + RL ensemble fall detection.
  ///
  /// Returns a map with keys:
  /// - `fall_detected` (bool)
  /// - `cnn_confidence` (double)
  /// - `rl_threshold` (double)
  /// - `action_taken` (String)
  /// - `ensemble_decision` (String)
  static Future<Map<String, dynamic>> predictRL(
      Map<String, double> sensorData) async {
    // ADDED
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict_rl'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sensorData),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Server returned ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ADDED — /pre_fall  (LSTM Pre-Fall Warning)
  /// Calls `/pre_fall` to get pre-fall instability warning.
  ///
  /// Returns a map with keys:
  /// - `warning` (bool)
  /// - `error_score` (double)
  /// - `estimated_seconds` (double)
  static Future<Map<String, dynamic>> getPreFallWarning(
      Map<String, double> sensorData) async {
    // ADDED
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/pre_fall'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sensorData),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'warning': false, 'error_score': 0.0, 'estimated_seconds': 0.0};
    } catch (e) {
      return {'warning': false, 'error_score': 0.0, 'estimated_seconds': 0.0};
    }
  }

  // ADDED — /explain  (XAI SHAP Explanation)
  /// Calls `/explain` for SHAP-based feature importance.
  ///
  /// Returns a map with keys:
  /// - `importance` (Map<String, double>)
  /// - `top_feature` (String)
  /// - `top_value` (double)
  /// - `interpretation` (String)
  static Future<Map<String, dynamic>> getExplanation(
      Map<String, double> sensorData) async {
    // ADDED
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/explain'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sensorData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Server returned ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/firebase_service.dart';
import '../../../core/services/ai_suggestion_service.dart';

// ── State ──────────────────────────────────────────────────────────────

enum WhereToStatus { initial, loading, loaded, submitting, submitted, error }

class WhereToState {
  final WhereToStatus status;
  final String destination;
  // Weather
  final String weatherCondition;
  final String weatherIcon;
  final double temperature;
  final bool isRaining;
  // AI
  final AISuggestion? suggestion;
  final int recentFallCount;
  // Error
  final String? errorMessage;

  const WhereToState({
    this.status = WhereToStatus.initial,
    this.destination = '',
    this.weatherCondition = '',
    this.weatherIcon = '01d',
    this.temperature = 0,
    this.isRaining = false,
    this.suggestion,
    this.recentFallCount = 0,
    this.errorMessage,
  });

  WhereToState copyWith({
    WhereToStatus? status,
    String? destination,
    String? weatherCondition,
    String? weatherIcon,
    double? temperature,
    bool? isRaining,
    AISuggestion? suggestion,
    int? recentFallCount,
    String? errorMessage,
  }) {
    return WhereToState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      temperature: temperature ?? this.temperature,
      isRaining: isRaining ?? this.isRaining,
      suggestion: suggestion ?? this.suggestion,
      recentFallCount: recentFallCount ?? this.recentFallCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Cubit ──────────────────────────────────────────────────────────────

class WhereToCubit extends Cubit<WhereToState> {
  final FirebaseService _firebase = FirebaseService();

  /// Replace with your free OpenWeatherMap API key.
  static const String _weatherApiKey = '67759a192b5d1a10b96a7431b23a13de';

  WhereToCubit() : super(const WhereToState());

  /// Load weather + recent falls for valid AI suggestion.
  Future<void> loadData({
    required double lat,
    required double lon,
  }) async {
    emit(state.copyWith(status: WhereToStatus.loading));
    try {
      // Fetch weather and fall count in parallel
      final results = await Future.wait([
        _fetchWeather(lat, lon),
        _firebase.getRecentFallCount(days: 7),
      ]);

      final weatherData = results[0] as Map<String, dynamic>?;
      final fallCount = results[1] as int;

      String condition = 'Clear';
      String icon = '01d';
      double temp = 25.0;
      bool raining = false;

      if (weatherData != null) {
        final weather = (weatherData['weather'] as List?)?.firstOrNull;
        condition = weather?['main']?.toString() ?? 'Clear';
        icon = weather?['icon']?.toString() ?? '01d';
        temp = ((weatherData['main']?['temp'] ?? 298.15) as num).toDouble() -
            273.15; // Kelvin → Celsius
        raining = condition.toLowerCase().contains('rain') ||
            condition.toLowerCase().contains('drizzle') ||
            condition.toLowerCase().contains('thunderstorm');
      }

      final hour = DateTime.now().hour;
      final suggestion = AISuggestionService.getSuggestion(
        weatherCondition: condition,
        temperature: temp,
        recentFallCount: fallCount,
        hourOfDay: hour,
        isRaining: raining,
      );

      emit(state.copyWith(
        status: WhereToStatus.loaded,
        weatherCondition: condition,
        weatherIcon: icon,
        temperature: temp,
        isRaining: raining,
        recentFallCount: fallCount,
        suggestion: suggestion,
      ));
    } catch (e) {
      print('[WhereToCubit] ❌ Load error: $e');
      // Still provide AI suggestion even if weather fails
      final hour = DateTime.now().hour;
      final suggestion = AISuggestionService.getSuggestion(
        weatherCondition: 'Unknown',
        temperature: 25,
        recentFallCount: 0,
        hourOfDay: hour,
        isRaining: false,
      );
      emit(state.copyWith(
        status: WhereToStatus.loaded,
        suggestion: suggestion,
        errorMessage: 'Could not fetch weather data',
      ));
    }
  }

  void updateDestination(String destination) {
    emit(state.copyWith(destination: destination));
  }

  /// Patient presses GO NOW → write to Firebase.
  Future<void> goNow({
    required double? lat,
    required double? lon,
  }) async {
    if (state.destination.trim().isEmpty) return;
    emit(state.copyWith(status: WhereToStatus.submitting));
    await _firebase.writePatientGoingOut(
      destination: state.destination.trim(),
      weather: '${state.weatherCondition}, ${state.temperature.toStringAsFixed(0)}°C',
      aiSuggestion: state.suggestion?.message ?? 'No suggestion',
      lat: lat,
      lon: lon,
    );
    emit(state.copyWith(status: WhereToStatus.submitted));
  }

  Future<Map<String, dynamic>?> _fetchWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=$_weatherApiKey',
      );
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      print('[WhereToCubit] ⚠️ Weather API status: ${response.statusCode}');
    } catch (e) {
      print('[WhereToCubit] ⚠️ Weather fetch error: $e');
    }
    return null;
  }
}

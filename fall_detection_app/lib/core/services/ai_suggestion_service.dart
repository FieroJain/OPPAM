/// Rule-based AI travel suggestion engine.
///
/// Returns a suggestion message and risk level based on weather,
/// time of day, and recent fall history.
enum RiskLevel { safe, caution, danger }

class AISuggestion {
  final String message;
  final RiskLevel riskLevel;

  const AISuggestion({required this.message, required this.riskLevel});
}

class AISuggestionService {
  AISuggestionService._();

  static AISuggestion getSuggestion({
    required String weatherCondition,
    required double temperature,
    required int recentFallCount,
    required int hourOfDay,
    required bool isRaining,
  }) {
    // Night time
    if (hourOfDay < 6 || hourOfDay > 20) {
      return const AISuggestion(
        message:
            'DANGER: It is night time. Please stay home or call a cab.',
        riskLevel: RiskLevel.danger,
      );
    }

    // Recent falls – high risk
    if (recentFallCount >= 3) {
      return AISuggestion(
        message:
            'DANGER: You had $recentFallCount falls recently. '
            'Please do not go alone.',
        riskLevel: RiskLevel.danger,
      );
    }

    // Raining
    if (isRaining) {
      return const AISuggestion(
        message:
            'CAUTION: It is raining. Wet floors are slippery. '
            'Take a cab if possible.',
        riskLevel: RiskLevel.caution,
      );
    }

    // Extreme temperature
    if (temperature > 38 || temperature < 10) {
      return const AISuggestion(
        message:
            'CAUTION: Extreme temperature. Limit outdoor time '
            'and carry water.',
        riskLevel: RiskLevel.caution,
      );
    }

    // Recent falls – moderate risk
    if (recentFallCount >= 1) {
      return AISuggestion(
        message:
            'CAUTION: You had $recentFallCount fall(s) recently. '
            'Take care and inform your caregiver.',
        riskLevel: RiskLevel.caution,
      );
    }

    // Safe
    return const AISuggestion(
      message:
          'SAFE: Conditions look good. Have a safe trip! '
          'Caregiver has been notified.',
      riskLevel: RiskLevel.safe,
    );
  }
}

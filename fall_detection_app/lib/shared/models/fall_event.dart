/// Model for a fall/incident event.
class FallEvent {
  final String id;
  final String title;
  final String location;
  final String zone;
  final DateTime timestamp;
  final FallSeverity severity;
  final String? responseTime;
  final String? detail;
  final String? metric;

  const FallEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.zone,
    required this.timestamp,
    required this.severity,
    this.responseTime,
    this.detail,
    this.metric,
  });
}

enum FallSeverity { high, medium, info }

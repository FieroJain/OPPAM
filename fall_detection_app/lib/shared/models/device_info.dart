/// Model for device information.
class DeviceInfo {
  final String name;
  final int batteryPercent;
  final String estimatedLife;
  final int signalDbm;
  final String signalQuality;
  final DeviceConnectionState connectionState;

  const DeviceInfo({
    required this.name,
    required this.batteryPercent,
    required this.estimatedLife,
    required this.signalDbm,
    required this.signalQuality,
    required this.connectionState,
  });
}

enum DeviceConnectionState { disconnected, searching, connected }

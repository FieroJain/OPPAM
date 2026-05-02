/// Data model representing a nearby hospital or clinic from OpenStreetMap.
class Hospital {
  final String name;
  final double lat;
  final double lon;
  final double distanceKm;
  final String? phone;
  final String? address;
  final String? type; // "hospital" or "clinic"

  const Hospital({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    this.phone,
    this.address,
    this.type,
  });

  Hospital copyWith({
    String? name,
    double? lat,
    double? lon,
    double? distanceKm,
    String? phone,
    String? address,
    String? type,
  }) {
    return Hospital(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      distanceKm: distanceKm ?? this.distanceKm,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
    );
  }

  @override
  String toString() =>
      'Hospital(name: $name, dist: ${distanceKm.toStringAsFixed(1)}km, '
      'type: $type, phone: $phone)';
}

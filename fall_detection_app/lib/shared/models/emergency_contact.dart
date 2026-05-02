import '../../core/utils/phone_utils.dart';

/// Model for an emergency contact.
class EmergencyContact {
  final String id;
  final String name;
  final String role;
  final ContactPriority priority;
  final String detail;
  final String? phone;
  final String? avatarUrl;
  final bool isEnabled;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.role,
    required this.priority,
    required this.detail,
    this.phone,
    this.avatarUrl,
    this.isEnabled = true,
  });

  /// Returns the phone number formatted for display.
  /// e.g. +91XXXXXXXXXX → +91 XXXXX XXXXX
  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return 'No phone';
    return formatPhone(phone!);
  }

  EmergencyContact copyWith({bool? isEnabled}) {
    return EmergencyContact(
      id: id,
      name: name,
      role: role,
      priority: priority,
      detail: detail,
      phone: phone,
      avatarUrl: avatarUrl,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

enum ContactPriority { high, family, caregiver, neighbor }


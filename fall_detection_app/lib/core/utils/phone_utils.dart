/// Shared phone number utilities — formatting, cleaning, validation, storage.

/// Formats a phone number for display.
/// +91XXXXXXXXXX → +91 XXXXX XXXXX
/// 10-digit      → XXXXX XXXXX
/// 91XXXXXXXXXX  → +91 XXXXX XXXXX
String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

  // +91 with 13 chars total
  if (digits.startsWith('+91') && digits.length == 13) {
    return '+91 ${digits.substring(3, 8)} ${digits.substring(8)}';
  }

  // 10 digit Indian number
  if (digits.length == 10) {
    return '${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  // Starts with 91, 12 digits
  if (digits.startsWith('91') && digits.length == 12) {
    return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
  }

  return phone;
}

/// Cleans a raw phone number for use with tel: scheme.
/// Removes spaces/dashes/brackets, adds +91 if 10-digit Indian number.
String cleanPhoneForDial(String rawPhone) {
  final cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  if (cleaned.length == 10 && !cleaned.startsWith('+')) {
    return '+91$cleaned';
  }
  return cleaned;
}

/// Cleans a phone number for consistent Firebase storage.
/// Always stores in +91XXXXXXXXXX format for Indian numbers.
String cleanForStorage(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

  if (digits.length == 10) return '+91$digits';
  if (digits.startsWith('91') && digits.length == 12) return '+$digits';
  return digits;
}

/// Validates a phone number string.
/// Returns error message if invalid, null if valid.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone number is required';
  }
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length < 10) {
    return 'Enter a valid 10-digit phone number';
  }
  if (digits.length > 13) {
    return 'Phone number too long';
  }
  return null; // valid
}

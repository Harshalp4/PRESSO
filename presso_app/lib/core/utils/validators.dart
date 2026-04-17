class AppValidators {
  AppValidators._();

  // -------------------------------------------------------------------------
  // Phone
  // -------------------------------------------------------------------------

  /// Validates an Indian mobile number (10 digits, optionally prefixed with +91).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final withoutCountryCode =
        cleaned.startsWith('+91') ? cleaned.substring(3) : cleaned;
    if (withoutCountryCode.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(withoutCountryCode)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Email
  // -------------------------------------------------------------------------

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates an optional email — returns null when empty.
  static String? emailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  // -------------------------------------------------------------------------
  // Name
  // -------------------------------------------------------------------------

  /// Validates a person's full name.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 60) {
      return 'Name must be at most 60 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'\-\.]+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, and hyphens';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Pincode
  // -------------------------------------------------------------------------

  /// Validates an Indian 6-digit pincode.
  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // OTP
  // -------------------------------------------------------------------------

  /// Validates a 6-digit OTP.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Required fields
  // -------------------------------------------------------------------------

  /// Generic required field validator.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum character length.
  static String? minLength(String? value, int min,
      {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum character length.
  static String? maxLength(String? value, int max,
      {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) return null;
    if (value.trim().length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Referral code
  // -------------------------------------------------------------------------

  /// Validates a referral code (alphanumeric, 6-12 chars).
  static String? referralCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Referral code is required';
    }
    if (!RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid referral code';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Address fields
  // -------------------------------------------------------------------------

  /// Validates an address line.
  static String? addressLine(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }
    if (value.trim().length > 200) {
      return 'Address must be at most 200 characters';
    }
    return null;
  }

  /// Validates a city name.
  static String? city(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value.trim())) {
      return 'Enter a valid city name';
    }
    return null;
  }
}

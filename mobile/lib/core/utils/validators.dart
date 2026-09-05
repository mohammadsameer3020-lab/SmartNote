class AppValidators {
  AppValidators._();

  // ============================================================
  // Username
  // ============================================================

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your username";
    }

    if (value.trim().length < 3) {
      return "Username must be at least 3 characters";
    }

    return null;
  }

  // ============================================================
  // Email
  // ============================================================

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your email";
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email";
    }

    return null;
  }

  // ============================================================
  // Password
  // ============================================================

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your password";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }

  // ============================================================
  // Confirm Password
  // ============================================================

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }

    if (value != password) {
      return "Passwords do not match";
    }

    return null;
  }

  // ============================================================
  // Required Field
  // ============================================================

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }

    return null;
  }

  // ============================================================
  // Phone
  // ============================================================

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your phone number";
    }

    if (value.trim().length < 9) {
      return "Enter a valid phone number";
    }

    return null;
  }
}

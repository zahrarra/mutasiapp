// lib/core/validators/form_validators.dart
//
// Form validators standar aplikasi MutasiKu.
// Sumber: PROJECT-SETUP.md §22, TECHNICAL-DESIGN.md.

abstract final class FormValidators {
  /// Validator field wajib diisi.
  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validator email.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validator min length password.
  static String? minLength(String? value, int min, [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }
}

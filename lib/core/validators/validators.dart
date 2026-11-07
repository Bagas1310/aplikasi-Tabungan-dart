class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != password) {
      return 'Kata sandi tidak cocok';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nominal wajib diisi';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'Nominal harus lebih dari nol';
    }
    return null;
  }
}

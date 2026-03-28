class Validators {
  static String? validateRollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Roll number or email is required';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return validateEmail(trimmed);
    }
    if (trimmed.length < 3 || trimmed.length > 20) {
      return 'Invalid roll number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? validateMarks(String? value, {double? maxMarks}) {
    if (value == null || value.trim().isEmpty) return 'Marks are required';
    final marks = double.tryParse(value.trim());
    if (marks == null || marks < 0) return 'Enter valid marks (>= 0)';
    if (maxMarks != null && marks > maxMarks) return 'Marks cannot exceed $maxMarks';
    return null;
  }
}

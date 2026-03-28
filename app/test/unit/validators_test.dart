import 'package:flutter_test/flutter_test.dart';
import 'package:university_portal/core/utils/validators.dart';

void main() {
  group('Validators.validateRollNumber', () {
    test('returns null for valid roll number', () {
      expect(Validators.validateRollNumber('2024CS001'), isNull);
    });

    test('returns null for valid email as identifier', () {
      expect(Validators.validateRollNumber('admin@university.edu'), isNull);
    });

    test('returns error for empty string', () {
      expect(Validators.validateRollNumber(''), isNotNull);
    });

    test('returns error for null', () {
      expect(Validators.validateRollNumber(null), isNotNull);
    });

    test('returns error for roll number that is too short', () {
      expect(Validators.validateRollNumber('AB'), isNotNull);
    });
  });

  group('Validators.validateEmail', () {
    test('returns null for valid email', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.validateEmail('not-an-email'), isNotNull);
    });

    test('returns error for empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns null for valid password', () {
      expect(Validators.validatePassword('SecurePass1'), isNull);
    });

    test('returns error for password shorter than 8 chars', () {
      expect(Validators.validatePassword('abc123'), isNotNull);
    });

    test('returns error for empty password', () {
      expect(Validators.validatePassword(''), isNotNull);
    });
  });

  group('Validators.validateMarks', () {
    test('returns null for valid marks within range', () {
      expect(Validators.validateMarks('85', maxMarks: 100), isNull);
    });

    test('returns error for marks exceeding maxMarks', () {
      expect(Validators.validateMarks('110', maxMarks: 100), isNotNull);
    });

    test('returns error for negative marks', () {
      expect(Validators.validateMarks('-5'), isNotNull);
    });

    test('returns error for non-numeric input', () {
      expect(Validators.validateMarks('abc'), isNotNull);
    });
  });
}

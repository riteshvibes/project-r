import 'package:flutter_test/flutter_test.dart';
import 'package:university_portal/core/constants/app_constants.dart';

void main() {
  group('AppConstants.getGrade', () {
    test('returns O for 90+', () {
      expect(AppConstants.getGrade(90), equals('O'));
      expect(AppConstants.getGrade(100), equals('O'));
    });

    test('returns A+ for 80-89', () {
      expect(AppConstants.getGrade(80), equals('A+'));
      expect(AppConstants.getGrade(89), equals('A+'));
    });

    test('returns A for 70-79', () {
      expect(AppConstants.getGrade(70), equals('A'));
      expect(AppConstants.getGrade(79), equals('A'));
    });

    test('returns B+ for 60-69', () {
      expect(AppConstants.getGrade(60), equals('B+'));
    });

    test('returns B for 50-59', () {
      expect(AppConstants.getGrade(50), equals('B'));
    });

    test('returns C for 40-49', () {
      expect(AppConstants.getGrade(40), equals('C'));
    });

    test('returns F for below 40', () {
      expect(AppConstants.getGrade(39), equals('F'));
      expect(AppConstants.getGrade(0), equals('F'));
    });
  });

  group('AppConstants file constraints', () {
    test('max file size is 10MB', () {
      expect(AppConstants.maxFileSizeMB, equals(10));
      expect(AppConstants.maxFileSizeBytes, equals(10 * 1024 * 1024));
    });

    test('allowed PDF MIME types list is correct', () {
      expect(AppConstants.allowedPdfTypes, contains('application/pdf'));
    });

    test('max periods per day is 8', () {
      expect(AppConstants.maxPeriodsPerDay, equals(8));
    });
  });
}

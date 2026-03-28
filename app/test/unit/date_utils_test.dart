import 'package:flutter_test/flutter_test.dart';
import 'package:university_portal/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils.formatDisplayDate', () {
    test('formats date correctly', () {
      final date = DateTime(2024, 3, 15);
      expect(AppDateUtils.formatDisplayDate(date), equals('15 Mar 2024'));
    });
  });

  group('AppDateUtils.formatDbDate', () {
    test('formats as ISO date string', () {
      final date = DateTime(2024, 3, 15);
      expect(AppDateUtils.formatDbDate(date), equals('2024-03-15'));
    });
  });

  group('AppDateUtils.getDayName', () {
    test('returns correct day names (0=Sunday convention)', () {
      expect(AppDateUtils.getDayName(0), equals('Sunday'));
      expect(AppDateUtils.getDayName(1), equals('Monday'));
      expect(AppDateUtils.getDayName(5), equals('Friday'));
      expect(AppDateUtils.getDayName(6), equals('Saturday'));
    });

    test('clamps out-of-range values', () {
      expect(AppDateUtils.getDayName(-1), equals('Sunday'));
      expect(AppDateUtils.getDayName(10), equals('Saturday'));
    });
  });

  group('AppDateUtils.getSemesterLabel', () {
    test('returns correct labels for semesters 1-8', () {
      expect(AppDateUtils.getSemesterLabel(1), equals('1st Semester'));
      expect(AppDateUtils.getSemesterLabel(2), equals('2nd Semester'));
      expect(AppDateUtils.getSemesterLabel(3), equals('3rd Semester'));
      expect(AppDateUtils.getSemesterLabel(8), equals('8th Semester'));
    });
  });

  group('AppDateUtils.getRelativeTime', () {
    test('returns "Just now" for very recent times', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(AppDateUtils.getRelativeTime(now), equals('Just now'));
    });

    test('returns minutes ago', () {
      final recent = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AppDateUtils.getRelativeTime(recent), equals('5m ago'));
    });

    test('returns hours ago', () {
      final recent = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppDateUtils.getRelativeTime(recent), equals('3h ago'));
    });

    test('returns days ago for recent dates', () {
      final recent = DateTime.now().subtract(const Duration(days: 2));
      expect(AppDateUtils.getRelativeTime(recent), equals('2d ago'));
    });
  });
}

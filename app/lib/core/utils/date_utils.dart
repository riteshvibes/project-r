import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dbDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayTimeFormat = DateFormat('hh:mm a');
  static final DateFormat _displayDateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDisplayDate(DateTime date) => _displayDateFormat.format(date);
  static String formatDbDate(DateTime date) => _dbDateFormat.format(date);
  static String formatDisplayTime(DateTime time) => _displayTimeFormat.format(time);
  static String formatDisplayDateTime(DateTime dateTime) => _displayDateTimeFormat.format(dateTime);

  static DateTime parseDbDate(String date) => DateTime.parse(date);
  
  static String getDayName(int dayOfWeek) {
    // Matches PostgreSQL/JavaScript convention used in the database: 0=Sunday, 1=Monday … 6=Saturday
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek.clamp(0, 6)];
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 7) return formatDisplayDate(dateTime);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  static String getSemesterLabel(int semester) {
    const labels = ['', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
    if (semester < 1 || semester > 8) return '${semester}th';
    return '${labels[semester]} Semester';
  }
}

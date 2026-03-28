class AppConstants {
  static const String appName = 'University Portal';
  static const String appVersion = '1.0.0';
  
  // Supabase bucket names
  static const String hallTicketsBucket = 'hall-tickets';
  static const String documentsBucket = 'documents';
  static const String profilePhotosBucket = 'profile-photos';
  
  // File constraints
  static const int maxFileSizeMB = 10;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  static const List<String> allowedPdfTypes = ['application/pdf'];
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/png'];
  
  // Attendance
  static const int maxPeriodsPerDay = 8;
  static const List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Attendance status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  
  // Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';
  
  // Grades
  static const Map<String, String> gradeRanges = {
    'O': '90-100',
    'A+': '80-89',
    'A': '70-79',
    'B+': '60-69',
    'B': '50-59',
    'C': '40-49',
    'F': '0-39',
  };

  static String getGrade(double percentage) {
    if (percentage >= 90) return 'O';
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B+';
    if (percentage >= 50) return 'B';
    if (percentage >= 40) return 'C';
    return 'F';
  }
}

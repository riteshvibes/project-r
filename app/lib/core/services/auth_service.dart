import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static Stream<AuthState> get authStateChanges =>
      SupabaseService.client.auth.onAuthStateChange;

  static Future<Map<String, dynamic>> signIn({
    required String identifier,
    required String password,
  }) async {
    final response = await SupabaseService.signIn(
      identifier: identifier.trim(),
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign in failed');
    }
    final profile = await SupabaseService.getUserProfile();
    if (profile == null) {
      throw Exception('User profile not found. Contact admin.');
    }
    return profile;
  }

  static Future<void> signOut() => SupabaseService.signOut();

  static Future<Map<String, dynamic>?> getCurrentProfile() =>
      SupabaseService.getUserProfile();

  static bool get isSignedIn => SupabaseService.currentUser != null;

  static String? get currentUserId => SupabaseService.currentUserId;
}

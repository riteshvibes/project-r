import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static User? get currentUser => client.auth.currentUser;
  
  static String? get currentUserId => currentUser?.id;

  /// Initialize Supabase with environment-provided config.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );
  }

  /// Sign in with roll number (email format: rollnumber@portal.local) or email.
  static Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    final email = identifier.contains('@') ? identifier : '$identifier@portal.local';
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get current user profile.
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  /// Upload file to storage bucket with size and type validation.
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    int maxSizeBytes = 10 * 1024 * 1024,
    List<String>? allowedMimeTypes,
  }) async {
    if (bytes.length > maxSizeBytes) {
      throw Exception('File size exceeds ${maxSizeBytes ~/ (1024 * 1024)}MB limit');
    }
    if (allowedMimeTypes != null && !allowedMimeTypes.contains(mimeType)) {
      throw Exception('Invalid file type. Allowed: ${allowedMimeTypes.join(', ')}');
    }
    
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );
    return path;
  }

  /// Get a signed URL for a stored file (TTL = 1 hour by default).
  static Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    return await client.storage
        .from(bucket)
        .createSignedUrl(path, expiresInSeconds);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Content Planner Supabase Configuration
class SupabaseConfig {
  static const String supabaseUrl = 'https://zvjkjnqpnhzjewcfrygx.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2amtqbnFwbmh6amV3Y2ZyeWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4NjA1MDIsImV4cCI6MjA3MDQzNjUwMn0.OIxyaUlqEJEhbROF6oEWYXYpkL2HG5ICGPpaNETebTA';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase not initialized. Please check your connection and try again.');
    }
  }
  
  static GoTrueClient get auth {
    try {
      return client.auth;
    } catch (e) {
      throw Exception('Supabase auth not available. Please check your connection and try again.');
    }
  }
}

/// Authentication service - Remove this class if your project doesn't need auth
class SupabaseAuth {
  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: userData,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.letsplan://login-callback/',
      );

      // User profile is now automatically created by database trigger
      // Wait a moment for the trigger to complete
      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify user profile was created
        await _verifyUserProfile(response.user!);
      }

      return response;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Get current user
  static User? get currentUser {
    try {
      return SupabaseConfig.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    try {
      return currentUser != null;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  /// Auth state changes stream
  static Stream<AuthState> get authStateChanges {
    try {
      return SupabaseConfig.auth.onAuthStateChange;
    } catch (e) {
      debugPrint('Error getting auth state changes: $e');
      // Return empty stream if auth is unavailable
      return const Stream.empty();
    }
  }

  /// Handle deep link authentication (email confirmation)
  static Future<bool> handleDeepLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('code')) {
        await SupabaseConfig.auth.exchangeCodeForSession(
          uri.queryParameters['code']!,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      return false;
    }
  }

  /// Verify user profile was created by database trigger
  static Future<void> _verifyUserProfile(User user) async {
    try {
      // Check if profile was created by the database trigger
      final existingUser = await SupabaseService.selectSingle(
        'users',
        filters: {'id': user.id},
      );

      if (existingUser == null) {
        // If trigger failed, create manually as fallback
        debugPrint('Database trigger did not create user profile, creating manually...');
        await SupabaseService.insert('users', {
          'id': user.id,
          'email': user.email,
          'display_name': user.email?.split('@')[0] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('User profile created manually for ${user.email}');
      } else {
        debugPrint('User profile verified for ${user.email}');
      }
    } catch (e) {
      debugPrint('Error verifying/creating user profile: ${e}');
      // Don't throw here to avoid breaking the signup flow
    }
  }

  /// Handle authentication errors
  static String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password';
        case 'Email not confirmed':
          return 'Please check your email and confirm your account';
        case 'User not found':
          return 'No account found with this email';
        case 'Signup requires a valid password':
          return 'Password must be at least 6 characters';
        case 'Too many requests':
          return 'Too many attempts. Please try again later';
        default:
          return 'Authentication error: ${error.message}';
      }
    } else if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    } else {
      return 'Network error. Please check your connection';
    }
  }
}

/// Generic database service for CRUD operations
class SupabaseService {
  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query;
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw _handleDatabaseError('select', table, e);
    }
  }

  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.maybeSingle();
    } catch (e) {
      throw _handleDatabaseError('selectSingle', table, e);
    }
  }

  /// Insert a record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await SupabaseConfig.client.from(table).insert(data).select();
      
      if (result.isEmpty) {
        throw Exception('Insert operation returned empty result. This may be due to RLS policies or missing permissions.');
      }
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw _handleDatabaseError('insert', table, e);
    }
  }

  /// Insert multiple records into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final result = await SupabaseConfig.client.from(table).insert(data).select();
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw _handleDatabaseError('insertMultiple', table, e);
    }
  }

  /// Update records in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      final result = await query.select();
      
      if (result.isEmpty) {
        throw Exception('Update operation returned empty result. Record may not exist or user lacks permissions.');
      }
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      throw _handleDatabaseError('update', table, e);
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      throw _handleDatabaseError('delete', table, e);
    }
  }

  /// Get direct table reference for complex queries
  static SupabaseQueryBuilder from(String table) =>
      SupabaseConfig.client.from(table);

  /// Handle database errors
  static String _handleDatabaseError(
    String operation,
    String table,
    dynamic error,
  ) {
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PGRST116':
          return 'No rows found for $operation in $table. Check if the record exists and you have permission to access it.';
        case 'PGRST301':
          return 'Row Level Security policy violation for $operation in $table. Check your permissions.';
        default:
          return 'Failed to $operation from $table: ${error.message} (Code: ${error.code})';
      }
    } else if (error.toString().contains('empty result')) {
      return 'Operation completed but returned empty result. This may be due to RLS policies or the record was not found.';
    } else {
      return 'Failed to $operation from $table: ${error.toString()}';
    }
  }
}

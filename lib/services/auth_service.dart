import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Register a new user
  // Returns SignUpResult with success status and whether email confirmation is required
  Future<SignUpResult> register(String email, String password, String name) async {
    try {
      // Sign up with Supabase
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      if (response.user != null) {
        // Check if session exists (email confirmation may be required)
        if (response.session != null) {
          // User is immediately signed in (email confirmation disabled)
          // Update user metadata with name
          await _supabase.auth.updateUser(
            UserAttributes(
              data: {'name': name},
            ),
          );
          return SignUpResult(
            success: true,
            requiresEmailConfirmation: false,
            message: null,
          );
        } else {
          // Email confirmation is required
          return SignUpResult(
            success: true,
            requiresEmailConfirmation: true,
            message: 'Account created. Please verify your email.',
          );
        }
      }
      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: 'Registration failed. Please try again.',
      );
    } on AuthException catch (e) {
      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: e.message,
      );
    } catch (e) {
      return SignUpResult(
        success: false,
        requiresEmailConfirmation: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Login user
  // Returns Supabase User on success, throws AuthException on failure
  Future<User> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return response.user!;
      }
      throw AuthException('Login failed. Please try again.');
    } on AuthException {
      rethrow; // Re-throw to get error message in UI
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // Get current logged in user
  // Returns Supabase User or null
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Logout user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Get Supabase client (for use in other services)
  SupabaseClient get supabase => _supabase;
}

// Result class for sign up operation
class SignUpResult {
  final bool success;
  final bool requiresEmailConfirmation;
  final String? message;

  SignUpResult({
    required this.success,
    required this.requiresEmailConfirmation,
    this.message,
  });
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Get the current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<Failure, User>> signInWithApple();

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Link Google account to existing user
  Future<Either<Failure, User>> linkGoogleAccount();

  /// Link Apple account to existing user
  Future<Either<Failure, User>> linkAppleAccount();

  /// Unlink a provider from the user account
  Future<Either<Failure, User>> unlinkProvider(String providerId);

  /// Update user profile information
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Update user preferences
  Future<Either<Failure, void>> updatePreferences(
    Map<String, dynamic> preferences,
  );

  /// Reload user data from server
  Future<Either<Failure, User>> reloadUser();

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Re-authenticate user before sensitive operations
  Future<Either<Failure, void>> reauthenticateWithGoogle();
  Future<Either<Failure, void>> reauthenticateWithApple();

  /// Enable/disable biometric authentication
  Future<Either<Failure, void>> setBiometricEnabled(bool enabled);

  /// Check if biometric authentication is available
  Future<Either<Failure, bool>> isBiometricAvailable();

  /// Authenticate with biometrics
  Future<Either<Failure, bool>> authenticateWithBiometrics();

  /// Get stored session token
  Future<Either<Failure, String?>> getSessionToken();

  /// Refresh session token
  Future<Either<Failure, String>> refreshSessionToken();

  /// Clear all cached authentication data
  Future<Either<Failure, void>> clearAuthCache();
}

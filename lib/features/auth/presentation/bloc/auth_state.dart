import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app is starting
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication is being checked
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is authenticated
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated([this.message]);

  @override
  List<Object?> get props => [message];
}

/// State when authentication fails
class AuthError extends AuthState {
  final String message;
  final bool requiresReauth;

  const AuthError({required this.message, this.requiresReauth = false});

  @override
  List<Object?> get props => [message, requiresReauth];
}

/// State when an operation is in progress
class AuthOperationInProgress extends AuthState {
  final String operation;
  final User? currentUser;

  const AuthOperationInProgress({required this.operation, this.currentUser});

  @override
  List<Object?> get props => [operation, currentUser];
}

/// State when an operation completes successfully
class AuthOperationSuccess extends AuthState {
  final String message;
  final User? user;

  const AuthOperationSuccess({required this.message, this.user});

  @override
  List<Object?> get props => [message, user];
}

/// State when password reset email is sent
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// State when email verification is sent
class AuthVerificationSent extends AuthState {
  final String email;

  const AuthVerificationSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// State when biometric authentication is required
class AuthBiometricRequired extends AuthState {
  final User user;

  const AuthBiometricRequired(this.user);

  @override
  List<Object?> get props => [user];
}

/// State for biometric authentication result
class AuthBiometricResult extends AuthState {
  final bool isAuthenticated;
  final String? message;
  final User? user;

  const AuthBiometricResult({
    required this.isAuthenticated,
    this.message,
    this.user,
  });

  @override
  List<Object?> get props => [isAuthenticated, message, user];
}

/// Extension methods for AuthState
extension AuthStateX on AuthState {
  /// Check if the state represents an authenticated user
  bool get isAuthenticated => this is AuthAuthenticated;

  /// Check if the state represents loading
  bool get isLoading => this is AuthLoading || this is AuthOperationInProgress;

  /// Get the current user if available
  User? get currentUser {
    if (this is AuthAuthenticated) {
      return (this as AuthAuthenticated).user;
    } else if (this is AuthOperationInProgress) {
      return (this as AuthOperationInProgress).currentUser;
    } else if (this is AuthOperationSuccess) {
      return (this as AuthOperationSuccess).user;
    } else if (this is AuthBiometricRequired) {
      return (this as AuthBiometricRequired).user;
    } else if (this is AuthBiometricResult) {
      return (this as AuthBiometricResult).user;
    }
    return null;
  }
}

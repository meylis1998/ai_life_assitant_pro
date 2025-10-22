import 'package:equatable/equatable.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to sign in with Google
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Event to sign in with Apple
class AuthSignInWithAppleRequested extends AuthEvent {
  const AuthSignInWithAppleRequested();
}

/// Event to sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to link Google account
class AuthLinkGoogleRequested extends AuthEvent {
  const AuthLinkGoogleRequested();
}

/// Event to link Apple account
class AuthLinkAppleRequested extends AuthEvent {
  const AuthLinkAppleRequested();
}

/// Event to unlink a provider
class AuthUnlinkProviderRequested extends AuthEvent {
  final String providerId;

  const AuthUnlinkProviderRequested(this.providerId);

  @override
  List<Object?> get props => [providerId];
}

/// Event to update user profile
class AuthUpdateProfileRequested extends AuthEvent {
  final String? displayName;
  final String? photoUrl;

  const AuthUpdateProfileRequested({this.displayName, this.photoUrl});

  @override
  List<Object?> get props => [displayName, photoUrl];
}

/// Event to update user preferences
class AuthUpdatePreferencesRequested extends AuthEvent {
  final Map<String, dynamic> preferences;

  const AuthUpdatePreferencesRequested(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// Event to reload user data
class AuthReloadRequested extends AuthEvent {
  const AuthReloadRequested();
}

/// Event to delete account
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

/// Event to enable/disable biometric authentication
class AuthBiometricToggleRequested extends AuthEvent {
  final bool enabled;

  const AuthBiometricToggleRequested(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to authenticate with biometrics
class AuthBiometricAuthRequested extends AuthEvent {
  const AuthBiometricAuthRequested();
}

/// Event to refresh session token
class AuthSessionRefreshRequested extends AuthEvent {
  const AuthSessionRefreshRequested();
}

/// Event triggered when user authentication state changes
class AuthUserChanged extends AuthEvent {
  final dynamic user; // Can be User or null

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

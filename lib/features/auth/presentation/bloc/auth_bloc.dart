import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/link_apple_account.dart';
import '../../domain/usecases/link_google_account.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/update_user_profile.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogle signInWithGoogle;
  final SignInWithApple signInWithApple;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final LinkGoogleAccount linkGoogleAccount;
  final LinkAppleAccount linkAppleAccount;
  final UpdateUserProfile updateUserProfile;
  final AuthRepository authRepository;

  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required this.signInWithGoogle,
    required this.signInWithApple,
    required this.signOut,
    required this.getCurrentUser,
    required this.linkGoogleAccount,
    required this.linkAppleAccount,
    required this.updateUserProfile,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthLinkGoogleRequested>(_onLinkGoogleRequested);
    on<AuthLinkAppleRequested>(_onLinkAppleRequested);
    on<AuthUnlinkProviderRequested>(_onUnlinkProviderRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
    on<AuthUpdatePreferencesRequested>(_onUpdatePreferencesRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthReloadRequested>(_onReloadRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthBiometricToggleRequested>(_onBiometricToggleRequested);
    on<AuthBiometricAuthRequested>(_onBiometricAuthRequested);
    on<AuthSessionRefreshRequested>(_onSessionRefreshRequested);
    on<AuthUserChanged>(_onUserChanged);

    // Listen to auth state changes
    _authStateSubscription = authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  /// Handle auth check request
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUser(NoParams());

    result.fold((failure) => emit(AuthUnauthenticated(failure.message)), (
      user,
    ) {
      if (user != null) {
        // Check if biometric is enabled for this user
        _checkBiometricStatus(user, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  /// Handle Google sign-in request
  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Signing in with Google'));

    final result = await signInWithGoogle(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle Apple sign-in request
  Future<void> _onSignInWithAppleRequested(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Signing in with Apple'));

    final result = await signInWithApple(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle email sign-in request
  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Signing in'));

    final result = await authRepository.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle sign-up request
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Creating account'));

    final result = await authRepository.signUpWithEmailAndPassword(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      emit(
        AuthOperationSuccess(
          message: 'Account created! Please verify your email.',
          user: user,
        ),
      );
      emit(AuthAuthenticated(user));
    });
  }

  /// Handle sign-out request
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Signing out',
        currentUser: currentUser,
      ),
    );

    final result = await signOut(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Handle link Google account request
  Future<void> _onLinkGoogleRequested(
    AuthLinkGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Linking Google account',
        currentUser: currentUser,
      ),
    );

    final result = await linkGoogleAccount(NoParams());

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      emit(
        AuthOperationSuccess(
          message: 'Google account linked successfully',
          user: user,
        ),
      );
      emit(AuthAuthenticated(user));
    });
  }

  /// Handle link Apple account request
  Future<void> _onLinkAppleRequested(
    AuthLinkAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Linking Apple account',
        currentUser: currentUser,
      ),
    );

    final result = await linkAppleAccount(NoParams());

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      emit(
        AuthOperationSuccess(
          message: 'Apple account linked successfully',
          user: user,
        ),
      );
      emit(AuthAuthenticated(user));
    });
  }

  /// Handle unlink provider request
  Future<void> _onUnlinkProviderRequested(
    AuthUnlinkProviderRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Unlinking provider',
        currentUser: currentUser,
      ),
    );

    final result = await authRepository.unlinkProvider(event.providerId);

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      emit(
        AuthOperationSuccess(
          message: 'Provider unlinked successfully',
          user: user,
        ),
      );
      emit(AuthAuthenticated(user));
    });
  }

  /// Handle update profile request
  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Updating profile',
        currentUser: currentUser,
      ),
    );

    final result = await updateUserProfile(
      UpdateUserProfileParams(
        displayName: event.displayName,
        photoUrl: event.photoUrl,
      ),
    );

    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      emit(
        AuthOperationSuccess(
          message: 'Profile updated successfully',
          user: user,
        ),
      );
      emit(AuthAuthenticated(user));
    });
  }

  /// Handle update preferences request
  Future<void> _onUpdatePreferencesRequested(
    AuthUpdatePreferencesRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Updating preferences',
        currentUser: currentUser,
      ),
    );

    final result = await authRepository.updatePreferences(event.preferences);

    result.fold((failure) => emit(AuthError(message: failure.message)), (_) {
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          preferences: {...currentUser.preferences, ...event.preferences},
        );
        emit(
          AuthOperationSuccess(
            message: 'Preferences updated',
            user: updatedUser,
          ),
        );
        emit(AuthAuthenticated(updatedUser));
      }
    });
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Sending reset email'));

    final result = await authRepository.sendPasswordResetEmail(event.email);

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthPasswordResetSent(event.email)),
    );
  }

  /// Handle email verification request
  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Sending verification email',
        currentUser: currentUser,
      ),
    );

    final result = await authRepository.sendEmailVerification();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthVerificationSent(currentUser?.email ?? '')),
    );
  }

  /// Handle reload user request
  Future<void> _onReloadRequested(
    AuthReloadRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: 'Refreshing user data',
        currentUser: currentUser,
      ),
    );

    final result = await authRepository.reloadUser();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Handle delete account request
  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOperationInProgress(operation: 'Deleting account'));

    final result = await authRepository.deleteAccount();

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          requiresReauth: failure.message.contains('recent'),
        ),
      ),
      (_) => emit(const AuthUnauthenticated('Account deleted successfully')),
    );
  }

  /// Handle biometric toggle request
  Future<void> _onBiometricToggleRequested(
    AuthBiometricToggleRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.currentUser;
    emit(
      AuthOperationInProgress(
        operation: event.enabled
            ? 'Enabling biometric authentication'
            : 'Disabling biometric authentication',
        currentUser: currentUser,
      ),
    );

    final result = await authRepository.setBiometricEnabled(event.enabled);

    result.fold((failure) => emit(AuthError(message: failure.message)), (_) {
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          biometricEnabled: event.enabled,
        );
        emit(
          AuthOperationSuccess(
            message: event.enabled
                ? 'Biometric authentication enabled'
                : 'Biometric authentication disabled',
            user: updatedUser,
          ),
        );
        emit(AuthAuthenticated(updatedUser));
      }
    });
  }

  /// Handle biometric authentication request
  Future<void> _onBiometricAuthRequested(
    AuthBiometricAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      const AuthOperationInProgress(
        operation: 'Authenticating with biometrics',
      ),
    );

    final result = await authRepository.authenticateWithBiometrics();

    result.fold(
      (failure) => emit(
        AuthBiometricResult(isAuthenticated: false, message: failure.message),
      ),
      (isAuthenticated) async {
        if (isAuthenticated) {
          final userResult = await getCurrentUser(NoParams());
          userResult.fold(
            (failure) => emit(
              AuthBiometricResult(
                isAuthenticated: false,
                message: failure.message,
              ),
            ),
            (user) {
              if (user != null) {
                emit(AuthBiometricResult(isAuthenticated: true, user: user));
                emit(AuthAuthenticated(user));
              }
            },
          );
        } else {
          emit(
            const AuthBiometricResult(
              isAuthenticated: false,
              message: 'Biometric authentication failed',
            ),
          );
        }
      },
    );
  }

  /// Handle session refresh request
  Future<void> _onSessionRefreshRequested(
    AuthSessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await authRepository.refreshSessionToken();

    result.fold(
      (failure) =>
          emit(AuthError(message: failure.message, requiresReauth: true)),
      (_) {
        // Session refreshed successfully, no state change needed
      },
    );
  }

  /// Handle user state changes from Firebase
  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      final user = event.user as User;

      // Don't emit a new state if we're in the middle of an operation
      if (state is! AuthOperationInProgress) {
        if (user.biometricEnabled && state is! AuthBiometricRequired) {
          // If biometric is enabled and we haven't checked yet
          final isAvailable = await authRepository.isBiometricAvailable();
          if (isAvailable.isRight() && isAvailable.getOrElse(() => false)) {
            emit(AuthBiometricRequired(user));
            return;
          }
        }
        emit(AuthAuthenticated(user));
      }
    } else {
      // User signed out
      if (state is! AuthOperationInProgress) {
        emit(const AuthUnauthenticated());
      }
    }
  }

  /// Check biometric status for user
  Future<void> _checkBiometricStatus(User user, Emitter<AuthState> emit) async {
    if (user.biometricEnabled) {
      final isAvailable = await authRepository.isBiometricAvailable();
      if (isAvailable.isRight() && isAvailable.getOrElse(() => false)) {
        emit(AuthBiometricRequired(user));
        return;
      }
    }
    emit(AuthAuthenticated(user));
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

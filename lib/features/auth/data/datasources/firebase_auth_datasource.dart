import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Abstract class for Firebase authentication data source
abstract class FirebaseAuthDataSource {
  /// Get current Firebase user
  Future<UserModel?> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;

  /// Sign in with Google
  Future<UserModel> signInWithGoogle();

  /// Sign in with Apple
  Future<UserModel> signInWithApple();

  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create new user with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out
  Future<void> signOut();

  /// Link Google account
  Future<UserModel> linkGoogleAccount();

  /// Link Apple account
  Future<UserModel> linkAppleAccount();

  /// Unlink provider
  Future<UserModel> unlinkProvider(String providerId);

  /// Update user profile
  Future<UserModel> updateProfile({String? displayName, String? photoUrl});

  /// Update user preferences in Firestore
  Future<void> updatePreferences(Map<String, dynamic> preferences);

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Reload user data
  Future<UserModel> reloadUser();

  /// Delete user account
  Future<void> deleteAccount();

  /// Re-authenticate with Google
  Future<void> reauthenticateWithGoogle();

  /// Re-authenticate with Apple
  Future<void> reauthenticateWithApple();

  /// Re-authenticate with password
  Future<void> reauthenticateWithPassword(String password);

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled);

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable();

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics();

  /// Get stored session token
  Future<String?> getSessionToken();

  /// Refresh session token
  Future<String> refreshSessionToken();

  /// Clear auth cache
  Future<void> clearAuthCache();
}

/// Implementation of Firebase authentication data source
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;
  final LocalAuthentication localAuth;
  final FlutterSecureStorage secureStorage;

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
    required this.localAuth,
    required this.secureStorage,
  });

  /// Collection reference for users
  CollectionReference get _usersCollection => firestore.collection('users');

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      // Get additional user data from Firestore
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return UserModel.merge(
          firebaseUser: firebaseUser,
          firestoreData: userDoc.data() as Map<String, dynamic>?,
        );
      }

      // If no Firestore document exists, create one
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      await _createOrUpdateUserDocument(userModel);
      return userModel;
    } catch (e) {
      throw ServerException(message: 'Failed to get current user: $e');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
        return UserModel.merge(
          firebaseUser: firebaseUser,
          firestoreData: userDoc.data() as Map<String, dynamic>?,
        );
      } catch (e) {
        return UserModel.fromFirebaseUser(firebaseUser);
      }
    });
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw const UnauthorizedException(
          message: 'Google sign-in was cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to sign in with Google');
      }

      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to sign in with Google: $e');
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = firebase_auth.OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );

      // Sign in with Firebase
      final userCredential = await firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to sign in with Apple');
      }

      // Update display name if provided by Apple
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((e) => e != null).join(' ');

        if (displayName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(displayName);
          await userCredential.user!.reload();
        }
      }

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to sign in with Apple: $e');
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to sign in');
      }

      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const ServerException(message: 'Failed to create account');
      }

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
      await _createOrUpdateUserDocument(userModel);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([firebaseAuth.signOut(), googleSignIn.signOut()]);
      await clearAuthCache();
    } catch (e) {
      throw ServerException(message: 'Failed to sign out: $e');
    }
  }

  @override
  Future<UserModel> linkGoogleAccount() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Get Google credential
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const UnauthorizedException(
          message: 'Google sign-in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential to the current user
      await currentUser.linkWithCredential(credential);
      await currentUser.reload();

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> linkAppleAccount() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Get Apple credential
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );

      // Link the credential to the current user
      await currentUser.linkWithCredential(oauthCredential);
      await currentUser.reload();

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> unlinkProvider(String providerId) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      await currentUser.unlink(providerId);
      await currentUser.reload();

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);
      await _createOrUpdateUserDocument(userModel);

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      if (displayName != null) {
        await currentUser.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await currentUser.updatePhotoURL(photoUrl);
      }

      await currentUser.reload();

      final userModel = UserModel.fromFirebaseUser(firebaseAuth.currentUser!);

      // Update Firestore document
      await _usersCollection.doc(currentUser.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      await _usersCollection.doc(currentUser.uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to update preferences: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      await currentUser.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> reloadUser() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      await currentUser.reload();
      final user = await getCurrentUser();
      if (user == null) {
        throw const ServerException(message: 'Failed to reload user');
      }
      return user;
    } catch (e) {
      throw ServerException(message: 'Failed to reload user: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Delete user document from Firestore
      await _usersCollection.doc(currentUser.uid).delete();

      // Delete user chats
      await firestore.collection('userChats').doc(currentUser.uid).delete();

      // Delete the user account
      await currentUser.delete();

      // Clear local cache
      await clearAuthCache();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Get Google credential
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const UnauthorizedException(
          message: 'Google sign-in was cancelled',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await currentUser.reauthenticateWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> reauthenticateWithApple() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Get Apple credential
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );

      await currentUser.reauthenticateWithCredential(oauthCredential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      // Store biometric preference securely
      await secureStorage.write(
        key: 'biometric_enabled_${currentUser.uid}',
        value: enabled.toString(),
      );

      // Update Firestore
      await _usersCollection.doc(currentUser.uid).update({
        'biometricEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(
        message: 'Failed to set biometric authentication: $e',
      );
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
      );

      return authenticated;
    } catch (e) {
      throw ServerException(message: 'Biometric authentication failed: $e');
    }
  }

  @override
  Future<String?> getSessionToken() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) return null;

      return await currentUser.getIdToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> refreshSessionToken() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const UnauthorizedException(message: 'No authenticated user');
      }

      final token = await currentUser.getIdToken(true);
      if (token == null) {
        throw const ServerException(message: 'Failed to get session token');
      }
      return token;
    } catch (e) {
      throw ServerException(message: 'Failed to refresh session token: $e');
    }
  }

  @override
  Future<void> clearAuthCache() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        await secureStorage.delete(key: 'biometric_enabled_${currentUser.uid}');
        await secureStorage.delete(key: 'session_token_${currentUser.uid}');
      }
    } catch (e) {
      // Silently fail cache clearing
    }
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(UserModel user) async {
    try {
      await _usersCollection
          .doc(user.id)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      // Non-critical error, log but don't throw
      // TODO: Use proper logger instead of print in production
      // logger.e('Failed to create/update user document: $e');
    }
  }

  /// Generate a cryptographically secure nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Handle Firebase Auth exceptions
  Exception _handleFirebaseAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'invalid-credential':
        return const UnauthorizedException(
          message: 'Invalid email or password',
        );
      case 'user-disabled':
        return const UnauthorizedException(
          message: 'This account has been disabled',
        );
      case 'email-already-in-use':
        return const ValidationException(
          message: 'An account already exists with this email',
        );
      case 'weak-password':
        return const ValidationException(message: 'Password is too weak');
      case 'operation-not-allowed':
        return const ServerException(message: 'This operation is not allowed');
      case 'too-many-requests':
        return const RateLimitException(
          provider: 'firebase_auth',
          message: 'Too many requests. Please try again later',
        );
      case 'requires-recent-login':
        return const UnauthorizedException(
          message: 'Please re-authenticate to continue',
        );
      case 'network-request-failed':
        return const NetworkException(
          message: 'Network error. Please check your connection',
        );
      default:
        return ServerException(message: e.message ?? 'Authentication failed');
    }
  }
}

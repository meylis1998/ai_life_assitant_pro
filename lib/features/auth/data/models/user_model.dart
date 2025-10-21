import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';

/// Data model for User entity
class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    super.displayName,
    super.photoUrl,
    required super.emailVerified,
    required super.createdAt,
    required super.lastSignIn,
    required super.providers,
    required super.preferences,
    required super.biometricEnabled,
    super.phoneNumber,
  });

  /// Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    // Extract provider IDs from provider data
    final providers = firebaseUser.providerData
        .map((info) => info.providerId)
        .where((id) => id.isNotEmpty)
        .toList();

    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSignIn: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      providers: providers,
      preferences: {},
      biometricEnabled: false,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSignIn: DateTime.parse(json['lastSignIn'] as String),
      providers: List<String>.from(json['providers'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      biometricEnabled: json['biometricEnabled'] ?? false,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastSignIn': lastSignIn.toIso8601String(),
      'providers': providers,
      'preferences': preferences,
      'biometricEnabled': biometricEnabled,
      'phoneNumber': phoneNumber,
    };
  }

  /// Create a copy with updated fields
  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastSignIn,
    List<String>? providers,
    Map<String, dynamic>? preferences,
    bool? biometricEnabled,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      providers: providers ?? this.providers,
      preferences: preferences ?? this.preferences,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

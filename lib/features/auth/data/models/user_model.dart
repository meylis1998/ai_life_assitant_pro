import 'package:cloud_firestore/cloud_firestore.dart';
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
      preferences: {}, // Will be loaded from Firestore
      biometricEnabled: false, // Will be loaded from secure storage
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSignIn:
          (data['lastSignIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      providers: List<String>.from(data['providers'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      biometricEnabled: data['biometricEnabled'] ?? false,
      phoneNumber: data['phoneNumber'] as String?,
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

  /// Merge Firebase Auth User with Firestore data
  factory UserModel.merge({
    required firebase_auth.User firebaseUser,
    Map<String, dynamic>? firestoreData,
  }) {
    final baseModel = UserModel.fromFirebaseUser(firebaseUser);

    if (firestoreData == null) {
      return baseModel;
    }

    return UserModel(
      id: baseModel.id,
      email: baseModel.email,
      displayName: firestoreData['displayName'] ?? baseModel.displayName,
      photoUrl: firestoreData['photoUrl'] ?? baseModel.photoUrl,
      emailVerified: baseModel.emailVerified,
      createdAt: baseModel.createdAt,
      lastSignIn: baseModel.lastSignIn,
      providers: baseModel.providers,
      preferences: Map<String, dynamic>.from(
        firestoreData['preferences'] ?? {},
      ),
      biometricEnabled: firestoreData['biometricEnabled'] ?? false,
      phoneNumber: baseModel.phoneNumber,
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSignIn': Timestamp.fromDate(lastSignIn),
      'providers': providers,
      'preferences': preferences,
      'biometricEnabled': biometricEnabled,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
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

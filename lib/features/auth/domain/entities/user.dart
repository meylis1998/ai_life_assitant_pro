import 'package:equatable/equatable.dart';

/// Represents an authenticated user in the application
class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final List<String> providers;
  final Map<String, dynamic> preferences;
  final bool biometricEnabled;
  final String? phoneNumber;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
    required this.createdAt,
    required this.lastSignIn,
    required this.providers,
    required this.preferences,
    required this.biometricEnabled,
    this.phoneNumber,
  });

  /// Creates an empty user (used for initial state)
  static final empty = User(
    id: '',
    emailVerified: false,
    createdAt: _defaultTime,
    lastSignIn: _defaultTime,
    providers: const [],
    preferences: const {},
    biometricEnabled: false,
  );

  static final _defaultTime = DateTime(1970);

  /// Checks if the user is empty/not authenticated
  bool get isEmpty => this == User.empty;

  /// Checks if the user is not empty/authenticated
  bool get isNotEmpty => this != User.empty;

  /// Checks if the user has a specific provider linked
  bool hasProvider(String provider) => providers.contains(provider);

  /// Checks if the user can link another provider
  bool get canLinkMoreProviders => providers.length < 5;

  /// Gets the user's initials for avatar
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email?.substring(0, 1).toUpperCase() ?? '?';
    }

    final names = displayName!.trim().split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return names.first.substring(0, min(2, names.first.length)).toUpperCase();
  }

  /// Creates a copy of the user with updated fields
  User copyWith({
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
    return User(
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

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    emailVerified,
    createdAt,
    lastSignIn,
    providers,
    preferences,
    biometricEnabled,
    phoneNumber,
  ];
}

/// Extension methods for User
extension UserX on User {
  /// Returns the primary auth provider
  String? get primaryProvider => providers.isNotEmpty ? providers.first : null;

  /// Checks if this is a new user (created in the last minute)
  bool get isNewUser {
    final now = DateTime.now();
    return now.difference(createdAt).inMinutes < 1;
  }

  /// Gets a preference value with type safety
  T? getPreference<T>(String key) {
    return preferences[key] as T?;
  }
}

// Helper function to handle min
int min(int a, int b) => a < b ? a : b;

import 'package:geolocator/geolocator.dart';

/// Service to handle location-related operations
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  /// Returns null if permission denied or service disabled
  Future<Position?> getCurrentPosition() async {
    print('📍 Starting location detection...');

    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    print('📍 Location services enabled: $serviceEnabled');
    if (!serviceEnabled) {
      print('📍 Location services disabled');
      return null;
    }

    // Check permission
    LocationPermission permission = await checkPermission();
    print('📍 Current permission: $permission');

    if (permission == LocationPermission.denied) {
      print('📍 Requesting location permission...');
      permission = await requestPermission();
      print('📍 Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        print('📍 Permission denied by user');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('📍 Permission permanently denied');
      return null;
    }

    // Get position with high accuracy and longer timeout for better results
    try {
      print('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      print('📍 Got position: ${position.latitude}, ${position.longitude}');
      print('📍 Position accuracy: ${position.accuracy}m');
      print('📍 Position timestamp: ${position.timestamp}');

      return position;
    } catch (e) {
      print('📍 Error getting position: $e');

      // Try to get last known position as fallback
      print('📍 Trying last known position...');
      try {
        final lastKnown = await getLastKnownPosition();
        if (lastKnown != null) {
          print('📍 Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
          return lastKnown;
        }
      } catch (e2) {
        print('📍 Error getting last known position: $e2');
      }

      return null;
    }
  }

  /// Get last known position (faster but may be outdated)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Open app settings for location permission
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  // Update bus location
  Future<void> updateBusLocation(String busId, double latitude, double longitude) async {
    try {
      await _firestore.collection(AppConstants.busesCollection).doc(busId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Calculate estimated arrival time based on current location and destination
  Future<DateTime> calculateEstimatedArrival(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      // This is a simplified calculation
      // In a real app, you would use Google Maps Distance Matrix API or similar
      const double averageSpeedKmPerHour = 30.0; // Average bus speed

      // Calculate distance in kilometers using Haversine formula
      final double distanceInKm = await _calculateDistance(
          startLat, startLng, endLat, endLng);

      // Calculate time in hours
      final double timeInHours = distanceInKm / averageSpeedKmPerHour;

      // Calculate estimated arrival time
      final DateTime now = DateTime.now();
      final DateTime estimatedArrival =
          now.add(Duration(minutes: (timeInHours * 60).round()));

      return estimatedArrival;
    } catch (e) {
      rethrow;
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  Future<double> _calculateDistance(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      return await Geolocator.distanceBetween(
              startLat, startLng, endLat, endLng) /
          1000; // Convert meters to kilometers
    } catch (e) {
      rethrow;
    }
  }
}
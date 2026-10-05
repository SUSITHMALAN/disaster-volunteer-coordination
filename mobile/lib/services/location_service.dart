import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request GPS permission and retrieve the current device position.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Maps GPS latitude & longitude coordinates into a human-readable zone string.
  static String deriveZoneFromCoordinates(double lat, double lng) {
    if (lat >= 6.7 && lat <= 7.1 && lng >= 79.8 && lng <= 80.1) {
      return 'Colombo';
    } else if (lat >= 7.2 && lat <= 7.5 && lng >= 80.5 && lng <= 80.8) {
      return 'Kandy';
    } else if (lat >= 5.9 && lat <= 6.2 && lng >= 80.1 && lng <= 80.4) {
      return 'Galle';
    }
    return 'Zone-${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
  }
}

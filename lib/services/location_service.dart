import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class AppLocation {
  const AppLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  AppLocation rounded({int fractionDigits = 3}) {
    final factor = math.pow(10, fractionDigits).toDouble();
    return AppLocation(
      latitude: (latitude * factor).round() / factor,
      longitude: (longitude * factor).round() / factor,
    );
  }
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationClient {
  Future<AppLocation> getCurrentLocation();
}

class DeviceLocationService implements LocationClient {
  const DeviceLocationService();

  @override
  Future<AppLocation> getCurrentLocation() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const LocationServiceException(
        'Konum servisi kapalı. Cihaz ayarlarından konumu açın.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Yakındaki ilanları görmek için konum izni vermelisiniz.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Konum izni kapalı. Uygulama ayarlarından izin verebilirsiniz.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      throw const LocationServiceException(
        'Konum alınamadı. Biraz sonra tekrar deneyin.',
      );
    }
  }
}

double distanceInKilometers(AppLocation first, AppLocation second) {
  const earthRadiusKm = 6371.0;
  final latitudeDifference = _toRadians(second.latitude - first.latitude);
  final longitudeDifference = _toRadians(second.longitude - first.longitude);
  final firstLatitude = _toRadians(first.latitude);
  final secondLatitude = _toRadians(second.latitude);

  final haversine =
      math.sin(latitudeDifference / 2) * math.sin(latitudeDifference / 2) +
      math.cos(firstLatitude) *
          math.cos(secondLatitude) *
          math.sin(longitudeDifference / 2) *
          math.sin(longitudeDifference / 2);
  final angularDistance =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

  return earthRadiusKm * angularDistance;
}

String formatDistance(double distanceKm) {
  if (distanceKm < 1) {
    final meters = (distanceKm * 1000).round();
    return '$meters m';
  }
  if (distanceKm < 10) {
    return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
  return '${distanceKm.round()} km';
}

double _toRadians(double degree) => degree * math.pi / 180;

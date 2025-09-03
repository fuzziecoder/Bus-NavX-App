import 'package:cloud_firestore/cloud_firestore.dart';
class BusModel {
  final String id;
  final String busNo;
  final String driverName;
  final String driverPhone;
  final double latitude;
  final double longitude;
  final String status; // 'active', 'inactive', 'maintenance'
  final DateTime lastUpdated;
  final String route;
  final DateTime estimatedArrival;

  BusModel({
    required this.id,
    required this.busNo,
    required this.driverName,
    required this.driverPhone,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastUpdated,
    required this.route,
    required this.estimatedArrival,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'] ?? '',
      busNo: json['busNo'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      status: json['status'] ?? 'inactive',
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      route: json['route'] ?? '',
      estimatedArrival: json['estimatedArrival'] != null
          ? (json['estimatedArrival'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNo': busNo,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'lastUpdated': lastUpdated,
      'route': route,
      'estimatedArrival': estimatedArrival,
    };
  }
}
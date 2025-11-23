// lib/models/police_unit_model.dart
class PoliceUnitModel {
  final String id;
  final String name;
  final String status;
  final bool available;
  final String? currentIncident;
  final String? location;
  final String? officerName;

  PoliceUnitModel({
    required this.id,
    required this.name,
    required this.status,
    required this.available,
    this.currentIncident,
    this.location,
    this.officerName,
  });

  factory PoliceUnitModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PoliceUnitModel(
      id: id,
      name: data['name'] ?? 'Unit $id',
      status: data['status'] ?? 'unknown',
      available: data['available'] ?? false,
      currentIncident: data['current_incident'],
      location: data['location'],
      officerName: data['officer_name'],
    );
  }

  String get displayName {
    if (officerName != null && officerName!.isNotEmpty) {
      return '$name - $officerName';
    }
    return name;
  }

  String get statusLabel {
    return status.toUpperCase();
  }
}

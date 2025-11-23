// lib/models/incident_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final int severityScore;
  final String? locationId;
  final double? latitude;
  final double? longitude;
  final String? unitAssigned;
  final DateTime? timestamp;
  final DateTime? assignedAt;
  final String? createdBy;
  final String? verifiedBy;

  IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.severityScore,
    this.locationId,
    this.latitude,
    this.longitude,
    this.unitAssigned,
    this.timestamp,
    this.assignedAt,
    this.createdBy,
    this.verifiedBy,
  });

  factory IncidentModel.fromFirestore(String id, Map<String, dynamic> data) {
    double? lat, lng;
    final locationId = data['location_id']?.toString() ?? '';
    
    if (locationId.isNotEmpty) {
      var latMatch = RegExp(r'Latitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
      var lngMatch = RegExp(r'Longitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationId);

      if (latMatch == null || lngMatch == null) {
        latMatch = RegExp(r'Lat\s*=\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
        lngMatch = RegExp(r'Long\s*=\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
      }

      lat = latMatch != null ? double.tryParse(latMatch.group(1) ?? '') : null;
      lng = lngMatch != null ? double.tryParse(lngMatch.group(1) ?? '') : null;
    }

    final severityValue = data['severity_score'];
    int severity = 0;
    if (severityValue is int) {
      severity = severityValue;
    } else if (severityValue is String) {
      severity = int.tryParse(severityValue) ?? 0;
    }

    return IncidentModel(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? 'No description',
      status: data['status'] ?? 'pending',
      severityScore: severity,
      locationId: locationId.isNotEmpty ? locationId : null,
      latitude: lat,
      longitude: lng,
      unitAssigned: data['unit_assigned'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      assignedAt: (data['assigned_at'] as Timestamp?)?.toDate(),
      createdBy: data['created_by'],
      verifiedBy: data['verified_by'],
    );
  }

  String get severityLabel {
    if (severityScore <= 33) return 'Low';
    if (severityScore <= 66) return 'Medium';
    return 'High';
  }

  String get statusLabel {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String getTimeAgo() {
    if (timestamp == null) return 'Unknown';
    
    final difference = DateTime.now().difference(timestamp!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

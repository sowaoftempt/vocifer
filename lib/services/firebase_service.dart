// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =============================
  // INCIDENT COUNTS
  // =============================

  /// Get count of incidents by status
  static Future<int> getIncidentCount(String status) async {
    try {
      final snapshot = await _db
          .collection('incidents')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.size;
    } catch (e) {
      print('❌ Error getting incident count: $e');
      return 0;
    }
  }

  /// Get total incidents count
  static Future<int> getTotalIncidents() async {
    try {
      final snapshot = await _db.collection('incidents').get();
      return snapshot.size;
    } catch (e) {
      print('❌ Error getting total incidents: $e');
      return 0;
    }
  }

  // =============================
  // POLICE UNITS
  // =============================

  /// Get count of free/available units
  static Future<int> getFreeUnitsCount() async {
    try {
      final snapshot = await _db
          .collection('police_units')
          .where('status', isEqualTo: 'free')
          .get();
      return snapshot.size;
    } catch (e) {
      print('❌ Error getting free units count: $e');
      return 0;
    }
  }

  /// Get all available units for assignment
  static Future<List<QueryDocumentSnapshot>> getAvailableUnits() async {
    try {
      final snapshot = await _db
          .collection('police_units')
          .where('status', isEqualTo: 'free')
          .get();
      return snapshot.docs;
    } catch (e) {
      print('❌ Error getting available units: $e');
      return [];
    }
  }

  /// Get unit details by ID
  static Future<Map<String, dynamic>?> getUnitById(String unitId) async {
    try {
      final doc = await _db.collection('police_units').doc(unitId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('❌ Error getting unit: $e');
      return null;
    }
  }

  // =============================
  // INCIDENTS STREAM & QUERIES
  // =============================

  /// Stream of new/recent reports (real-time)
  static Stream<QuerySnapshot> getNewReports() {
    try {
      return _db
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();
    } catch (e) {
      print('❌ Error streaming new reports: $e');
      return const Stream.empty();
    }
  }

  /// Get all incidents
  static Future<List<Map<String, dynamic>>> getAllIncidents() async {
    try {
      final snapshot = await _db
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('❌ Error getting all incidents: $e');
      return [];
    }
  }

  /// Get incidents by status
  static Future<List<Map<String, dynamic>>> getIncidentsByStatus(String status) async {
    try {
      final snapshot = await _db
          .collection('incidents')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('❌ Error getting incidents by status: $e');
      return [];
    }
  }

  // =============================
  // INCIDENT ASSIGNMENT
  // =============================

  /// Assign a unit to an incident
  static Future<bool> assignUnitToIncident(String incidentId, String unitId) async {
    try {
      // Update incident
      await _db.collection('incidents').doc(incidentId).update({
        'unit_assigned': unitId,
        'status': 'in_progress',
        'assigned_at': FieldValue.serverTimestamp(),
      });

      // Update unit status
      await _db.collection('police_units').doc(unitId).update({
        'status': 'active',
        'current_incident': incidentId,
      });

      print('✅ Unit $unitId assigned to incident $incidentId');
      return true;
    } catch (e) {
      print('❌ Error assigning unit: $e');
      return false;
    }
  }

  /// Update incident status
  static Future<bool> updateIncidentStatus(String incidentId, String newStatus) async {
    try {
      await _db.collection('incidents').doc(incidentId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // If resolved, free up the unit
      if (newStatus == 'resolved') {
        final incident = await _db.collection('incidents').doc(incidentId).get();
        final unitId = incident.data()?['unit_assigned'];

        if (unitId != null) {
          await _db.collection('police_units').doc(unitId).update({
            'status': 'free',
            'current_incident': null,
          });
        }
      }

      return true;
    } catch (e) {
      print('❌ Error updating incident status: $e');
      return false;
    }
  }

  // =============================
  // LOCATION-BASED INCIDENTS
  // =============================

  /// Get incidents with valid location data
  static Future<List<Map<String, dynamic>>> getIncidentsWithLocation() async {
    try {
      final snapshot = await _db.collection('incidents').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final locationId = data['location_ID']?.toString() ?? '';

        // Parse coordinates from location string
        double? lat, lng;
        if (locationId.isNotEmpty) {
          // Try "Latitude: XX Longitude: YY" format
          var latMatch = RegExp(r'Latitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
          var lngMatch = RegExp(r'Longitude:\s*([-+]?\d+\.?\d*)').firstMatch(locationId);

          // Fallback to "Lat=XX Long=YY" format
          if (latMatch == null || lngMatch == null) {
            latMatch = RegExp(r'Lat\s*=\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
            lngMatch = RegExp(r'Long\s*=\s*([-+]?\d+\.?\d*)').firstMatch(locationId);
          }

          lat = latMatch != null ? double.tryParse(latMatch.group(1) ?? '') : null;
          lng = lngMatch != null ? double.tryParse(lngMatch.group(1) ?? '') : null;
        }

        // Validate coordinates
        if (lat == null || lng == null ||
            lat < -90.0 || lat > 90.0 ||
            lng < -180.0 || lng > 180.0) {
          return null;
        }

        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Incident',
          'description': data['description'] ?? 'No details',
          'severity_score': data['severity_score'] ?? 0,
          'status': data['status'] ?? 'pending',
          'lat': lat,
          'lng': lng,
          'timestamp': data['timestamp']?.toDate().toString() ?? 'Unknown',
        };
      }).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('❌ Error fetching incidents with location: $e');
      return [];
    }
  }

  // =============================
  // ANALYTICS
  // =============================

  /// Get crime type distribution
  static Future<Map<String, int>> getCrimeTypeCounts() async {
    try {
      final snapshot = await _db.collection('incidents').get();
      final Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        final title = (doc.data()['title'] ?? 'Unknown') as String;
        counts[title] = (counts[title] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('❌ Error getting crime type counts: $e');
      return {};
    }
  }

  /// Get daily incident counts
  static Future<Map<String, int>> getDailyIncidents() async {
    try {
      final snapshot = await _db.collection('incidents').get();
      final Map<String, int> incidents = {};

      for (var doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final day = DateFormat('yyyy-MM-dd').format(timestamp);
          incidents[day] = (incidents[day] ?? 0) + 1;
        }
      }

      return incidents;
    } catch (e) {
      print('❌ Error getting daily incidents: $e');
      return {};
    }
  }

  /// Get severity distribution
  static Future<Map<String, int>> getSeverityDistribution() async {
    try {
      final snapshot = await _db.collection('incidents').get();
      final Map<String, int> severity = {'Low': 0, 'Medium': 0, 'High': 0};

      for (var doc in snapshot.docs) {
        final scoreValue = doc.data()['severity_score'];
        final score = scoreValue is String
            ? int.tryParse(scoreValue) ?? 0
            : scoreValue as int? ?? 0;

        if (score <= 33) {
          severity['Low'] = (severity['Low'] ?? 0) + 1;
        } else if (score <= 66) {
          severity['Medium'] = (severity['Medium'] ?? 0) + 1;
        } else {
          severity['High'] = (severity['High'] ?? 0) + 1;
        }
      }

      return severity;
    } catch (e) {
      print('❌ Error getting severity distribution: $e');
      return {'Low': 0, 'Medium': 0, 'High': 0};
    }
  }

  // =============================
  // PUBLIC REPORTS
  // =============================

  /// Publish a public report
  static Future<bool> publishPublicReport({
    required String title,
    required String description,
    String? imageUrl,
    required String author,
  }) async {
    try {
      await _db.collection('public_reports').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'publishedAt': FieldValue.serverTimestamp(),
        'author': author,
      });

      print('✅ Public report published');
      return true;
    } catch (e) {
      print('❌ Error publishing report: $e');
      return false;
    }
  }

  // =============================
  // TEST CONNECTION
  // =============================

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      await _db.collection('_test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'connected',
      });
      print('✅ Firebase connection successful');
      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }
}
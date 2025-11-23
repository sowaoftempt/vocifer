// lib/screens/assign_report.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/firebase_service.dart';
import '../models/incident_model.dart';
import '../models/police_unit_model.dart';

class AssignReportScreen extends StatefulWidget {
  const AssignReportScreen({super.key});

  @override
  State<AssignReportScreen> createState() => _AssignReportScreenState();
}

class _AssignReportScreenState extends State<AssignReportScreen> {
  bool _isLoading = true;
  List<IncidentModel> _incidents = [];
  List<IncidentModel> _filteredIncidents = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    try {
      final data = await FirebaseService.getAllIncidents();
      final incidents = data.map((item) => IncidentModel.fromFirestore(
        item['id'],
        item,
      )).toList();

      setState(() {
        _incidents = incidents;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading incidents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<IncidentModel> filtered = _incidents;

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((i) => i.status == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) =>
      i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) {
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    setState(() {
      _filteredIncidents = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  Future<void> _showAssignUnitDialog(IncidentModel incident) async {
    // Load available units
    final unitDocs = await FirebaseService.getAvailableUnits();
    final units = unitDocs.map((doc) =>
        PoliceUnitModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)
    ).toList();

    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available units at this time')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Unit to ${incident.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select an available unit:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ...units.map((unit) => ListTile(
              leading: Icon(
                Icons.local_police,
                color: AppTheme.accentColor,
              ),
              title: Text(unit.displayName),
              subtitle: Text(unit.location ?? 'Unknown location'),
              onTap: () {
                Navigator.pop(context);
                _assignUnit(incident, unit);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignUnit(IncidentModel incident, PoliceUnitModel unit) async {
    try {
      final success = await FirebaseService.assignUnitToIncident(
        incident.id,
        unit.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${unit.name} assigned to ${incident.title}'),
            backgroundColor: AppTheme.activeColor,
          ),
        );
        _loadIncidents(); // Reload data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign unit'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _updateIncidentStatus(IncidentModel incident, String newStatus) async {
    try {
      final success = await FirebaseService.updateIncidentStatus(
        incident.id,
        newStatus,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: AppTheme.activeColor,
          ),
        );
        _loadIncidents();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search incidents...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('In Progress', 'in_progress'),
                _buildFilterChip('Resolved', 'resolved'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Incident List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIncidents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredIncidents.length,
                itemBuilder: (context, index) {
                  return _buildIncidentCard(_filteredIncidents[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => _onFilterChanged(value),
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No incidents found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel incident) {
    final severityColor = AppTheme.getSeverityColor(incident.severityScore);
    final statusColor = AppTheme.getStatusColor(incident.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showIncidentDetails(incident),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: severityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      incident.severityLabel,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      incident.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    incident.getTimeAgo(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                incident.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                incident.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  if (incident.status == 'pending')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAssignUnitDialog(incident),
                        icon: const Icon(Icons.assignment, size: 18),
                        label: const Text('Assign Unit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentColor,
                          side: BorderSide(color: AppTheme.accentColor),
                        ),
                      ),
                    ),
                  if (incident.status == 'in_progress') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateIncidentStatus(incident, 'resolved'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark Resolved'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.activeColor,
                          side: BorderSide(color: AppTheme.activeColor),
                        ),
                      ),
                    ),
                  ],
                  if (incident.unitAssigned != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_police,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            incident.unitAssigned!,
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status badges
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(incident.severityLabel),
                    backgroundColor: AppTheme.getSeverityColor(incident.severityScore).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: AppTheme.getSeverityColor(incident.severityScore),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(incident.statusLabel),
                    backgroundColor: AppTheme.getStatusColor(incident.status).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: AppTheme.getStatusColor(incident.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildDetailRow(Icons.description, 'Description', incident.description),
              _buildDetailRow(Icons.access_time, 'Reported', incident.getTimeAgo()),
              if (incident.unitAssigned != null)
                _buildDetailRow(Icons.local_police, 'Assigned Unit', incident.unitAssigned!),
              if (incident.locationId != null)
                _buildDetailRow(Icons.location_on, 'Location', incident.locationId!),

              const SizedBox(height: 24),

              // Action buttons
              if (incident.status == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAssignUnitDialog(incident);
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Assign Unit'),
                  ),
                ),

              if (incident.status == 'in_progress')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateIncidentStatus(incident, 'resolved');
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Resolved'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
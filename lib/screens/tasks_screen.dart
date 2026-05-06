import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'track_volunteer_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();
  
  String? _userRole;
  String? _volunteerDocId;
  bool _isLoadingIdentity = true;

  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionStream;
  String? _trackingRequestId;
  bool _isSimulating = false;
  double _simLat = 23.7500;
  double _simLng = 90.3800;

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Get user role
    final role = await _auth.getUserRole(user.uid);
    
    // 2. If volunteer, get their doc ID in the 'volunteers' collection
    String? volId;
    if (role == 'volunteer' || role == 'admin') {
      volId = await _db.getVolunteerDocIdByUid(user.uid);
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _volunteerDocId = volId;
        _isLoadingIdentity = false;
      });
    }
  }

  Future<void> _completeTask(String requestId, List<dynamic> teamMembers, String taskTitle) async {
    try {
      _stopTracking(); // Ensure tracking stops if it was on
      await _db.completeRequestAndReleaseTeam(requestId, teamMembers);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✨ "$taskTitle" marked as Completed!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Tracking Logic ---

  Future<void> _startMission(String requestId) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    // 2. Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // 3. Update status to 'In Progress'
    try {
      await _db.updateRequestStatus(requestId, 'In Progress');
      
      setState(() {
        _trackingRequestId = requestId;
        _isSimulating = false; // Reset on startup
      });

      // 4. Start Real GPS Stream
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) async {
        if (!_isSimulating) {
          await _db.updateTaskLocation(requestId, position.latitude, position.longitude);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚀 Mission Started! Live tracking active.')),
        );
      }
    } catch (e) {
      print('Error starting mission: $e');
    }
  }

  void _toggleSimulation() async {
    if (_trackingRequestId == null) return;
    
    setState(() {
      _isSimulating = !_isSimulating;
    });

    if (_isSimulating) {
      // Start Simulation Timer
      _trackingTimer?.cancel();
      _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!_isSimulating || _trackingRequestId == null) {
          timer.cancel();
          return;
        }

        // Small random movement for demo
        _simLat += 0.0002;
        _simLng += 0.0001;
        
        await _db.updateTaskLocation(_trackingRequestId!, _simLat, _simLng);
        print('>>> [Simulation] Pushed: $_simLat, $_simLng');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎮 Simulation Mode: ACTIVE (Mocking movement)')),
        );
      }
    } else {
      _trackingTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🛰️ Returned to Real GPS mode.')),
        );
      }
    }
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    _positionStream?.cancel();
    _trackingTimer = null;
    _positionStream = null;
    _trackingRequestId = null;
    _isSimulating = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingIdentity) {
      return const Scaffold(
        backgroundColor: Color(0xFFE62135),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      floatingActionButton: _trackingRequestId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Find current task data if possible, or just re-fetch locally
                // For demo, we navigate with default values or latest tracking info
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackVolunteerScreen(
                      requestId: _trackingRequestId!,
                      volunteerName: "My Team", // Dynamic enough for demo
                      destinationName: "User Destination",
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFFE62135),
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text('Live Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (_userRole == 'admin')
                  ? _db.getAllAssignedTasksStream()
                  : (_volunteerDocId != null) 
                    ? _db.getAssignedTasksForVolunteer(_volunteerDocId!)
                    : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading tasks'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return _buildTaskCard(id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _userRole == 'admin' ? 'No active team assignments.' : 'No tasks assigned to your team yet.',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFFE62135),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userRole == 'admin' ? 'Global Oversight' : 'My Team Tasks',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _userRole == 'admin' ? 'Monitoring all field operations' : 'Mission-critical objectives',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String requestId, Map<String, dynamic> data) {
    final String title = data['name'] ?? 'Relief Operation';
    final String teamName = data['assignedTeamName'] ?? 'Unassigned';
    final List<dynamic> teamMembers = data['assignedTeam'] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUrgencyChip(data['urgencyLevel'] ?? 'Medium'),
                _buildTeamBadge(teamName),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFFE62135)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['location'] ?? 'Location TBD',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    'Personnel: ${teamMembers.length} volunteers active.\nObjective: provide emergency support as requested.',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: SizedBox(
              // height: 52, // Removed fixed height to allow for more content
              child: data['status'] == 'In Progress' 
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _completeTask(requestId, teamMembers, title),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text('Complete Mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isSimulating ? Icons.sensors : Icons.sensors_off, size: 16, color: Colors.blueAccent),
                          TextButton(
                            onPressed: _toggleSimulation,
                            child: Text(
                              _isSimulating ? 'Stop Simulation' : 'Simulate Movement (Demo Mode)',
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _startMission(requestId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch, size: 20),
                              SizedBox(width: 8),
                              Text('Start Mission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      if (data['status'] == 'In Progress' || data['status'] == 'Assigned')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrackVolunteerScreen(
                                    requestId: requestId,
                                    volunteerName: teamName,
                                    destinationName: (data['location'] as String? ?? "Dhaka").split(',').first.trim(),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined, color: Color(0xFF3B82F6)),
                            label: const Text('View Live Map', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    Color color;
    switch (urgency) {
      case 'High': color = const Color(0xFFE62135); break;
      case 'Medium': color = Colors.orange.shade700; break;
      case 'Low': color = Colors.blue.shade700; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(urgency.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTeamBadge(String teamName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Text(teamName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

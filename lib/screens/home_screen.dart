import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'request_aid_screen.dart';
import 'volunteer_list_screen.dart';
import 'team_assign_screen.dart';
import 'volunteer_registration_screen.dart';
import 'admin_dashboard_screen.dart';
import 'resources_screen.dart';
import 'shelter_screen.dart';
import 'donation_screen.dart';
import 'tasks_screen.dart';
import 'track_volunteer_screen.dart';

// ─── Role constants ────────────────────────────────────────────────────────────
const String kRoleAdmin = 'admin';
const String kRoleVolunteer = 'volunteer';
const String kRoleUser = 'user';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  /// Null while the role is still being fetched from Firestore.
  String? _userRole;
  String? _volunteerStatus;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final role = await _auth.getUserRole(user.uid);
    final status = await _db.getVolunteerStatusByUid(user.uid);

    if (mounted) {
      setState(() {
        _userRole = role;
        _volunteerStatus = status;
        _displayName = user.displayName ?? user.email ?? 'User';
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    // AuthGate in main.dart will redirect to LoginScreen automatically
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  bool get _isAdmin => _userRole == kRoleAdmin;
  bool get _isVolunteer => _userRole == kRoleVolunteer;

  List<Map<String, dynamic>> get _visibleFeatures {
    const all = [
      {
        'icon': '🫶',
        'title': 'Request Aid',
        'sub': 'Get Help',
        'highlight': true,
        'roles': [kRoleAdmin, kRoleVolunteer, kRoleUser],
      },
      {
        'icon': '🤝',
        'title': 'Become a Volunteer',
        'sub': 'Join Effort',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleVolunteer, kRoleUser],
        'hideIfApplied': true,
      },
      {
        'icon': '📋',
        'title': 'Volunteer List',
        'sub': 'List',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleVolunteer],
      },
      {
        'icon': '📦',
        'title': 'Resources',
        'sub': 'Support',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleUser],
      },
      {
        'icon': '👥',
        'title': 'Team Assign',
        'sub': 'Assign',
        'highlight': true,
        'roles': [kRoleAdmin],
      },
      {
        'icon': '✅',
        'title': 'Tasks',
        'sub': 'Manage',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleVolunteer],
      },
      {
        'icon': '🏠',
        'title': 'Shelters',
        'sub': 'Nearby',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleVolunteer, kRoleUser],
      },
      {
        'icon': '💸',
        'title': 'Donations',
        'sub': 'Donate',
        'highlight': false,
        'roles': [kRoleAdmin, kRoleUser],
      },
    ];

    if (_userRole == null) return [];
    return all.where((f) {
      final hasRole = (f['roles'] as List<String>).contains(_userRole);
      final shouldHide = (f['hideIfApplied'] == true && _volunteerStatus != null);
      return hasRole && !shouldHide;
    }).toList();
  }

  void _onFeatureTap(String title) {
    switch (title) {
      case 'Request Aid':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestAidScreen()));
        break;
      case 'Become a Volunteer':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerRegistrationScreen()));
        break;
      case 'Volunteer List':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerListScreen()));
        break;
      case 'Team Assign':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamAssignScreen()));
        break;
      case 'Resources':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResourcesScreen(isAdmin: _isAdmin)));
        break;
      case 'Shelters':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShelterScreen(isAdmin: _isAdmin)));
        break;
      case 'Donations':
        Navigator.push(context, MaterialPageRoute(builder: (_) => DonationScreen(isReadOnly: !_isAdmin)));
        break;
      case 'Tasks':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title — coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Full-screen loading while role is being fetched
    if (_userRole == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE62135),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, color: Colors.white, size: 60),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Setting up your dashboard...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              if (_volunteerStatus == 'Pending Approval') _buildPendingBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildEmergencyOverview(),
                    const SizedBox(height: 16),
                    _buildTrackingBanner(),
                    const SizedBox(height: 16),
                    _buildMainFeatures(),
                    const SizedBox(height: 24),
                    _buildBottomButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final roleLabel = _isAdmin ? 'Admin' : _isVolunteer ? 'Volunteer' : 'User';
    final roleIcon = _isAdmin ? Icons.shield : _isVolunteer ? Icons.volunteer_activism : Icons.person;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 20),
      decoration: const BoxDecoration(color: Color(0xFFE62135)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aid Go',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, ${_displayName.split(' ').first} 👋',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Admin Dashboard shortcut (Admins only)
                  if (_isAdmin)
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      ),
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                      tooltip: 'Admin Dashboard',
                    ),
                  // Sign out button
                  IconButton(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                    tooltip: 'Sign Out',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingBanner() {
    final user = _auth.currentUser;
    if (user == null || _userRole != kRoleUser) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('name', isEqualTo: _displayName) // Basic link for demo: match by user name
          .where('status', whereIn: ['Assigned', 'In Progress'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final requestId = snapshot.data!.docs.first.id;
        final teamName = data['assignedTeamName'] ?? 'Emergency Team';
        final volunteerIds = data['assignedVolunteerIds'] as List<dynamic>?;
        final locationName = data['location'] ?? 'Unknown';

        if (volunteerIds == null || volunteerIds.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.blueAccent, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hero En Route!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('$teamName is tracking to you.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackVolunteerScreen(
                        requestId: requestId, 
                        volunteerName: teamName,
                        destinationName: locationName.split(',').first.trim(), // e.g., "Dhanmondi"
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE62135),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Track Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Application Under Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  'Your volunteer status is pending admin approval.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.getPendingRequestsStream(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData) {
                count = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] != 'Completed';
                }).length;
              }
              return _buildStatCard(count.toString(), 'Active Cases');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.getFreeVolunteersStream(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatCard(count.toString(), 'Available Volunteers');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.blue.shade400)),
        ],
      ),
    );
  }

  // ─── Emergency Overview ───────────────────────────────────────────────────────
  Widget _buildEmergencyOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Emergency Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
                child: const Text('Live', style: TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Today's response status", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Positioned(top: 20, left: -20,
                  child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.03), width: 3), shape: BoxShape.circle))),
                Positioned(top: -50, right: -50,
                  child: Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.03), width: 3), shape: BoxShape.circle))),
                const Positioned(top: 30, left: 40, child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFF43F5E))),
                const Positioned(bottom: 40, right: 80, child: CircleAvatar(radius: 6, backgroundColor: Color(0xFFF59E0B))),
                const Positioned(bottom: 20, left: 140, child: CircleAvatar(radius: 6, backgroundColor: Color(0xFF10B981))),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                    child: const Text('Updated 2 mins ago', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Features ────────────────────────────────────────────────────────────
  Widget _buildMainFeatures() {
    final features = _visibleFeatures;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Main Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE62135).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${features.length} features', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE62135))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Your available actions', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          features.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No features available.', style: TextStyle(color: Colors.grey))))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    final item = features[index];
                    return _buildFeatureItem(
                      item['icon'] as String,
                      item['title'] as String,
                      item['sub'] as String,
                      item['highlight'] as bool,
                      () => _onFeatureTap(item['title'] as String),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String title, String sub, bool highlight, VoidCallback onTap) {
    return Material(
      color: highlight ? const Color(0xFFFFF0F0) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: highlight ? const Color(0xFFFFD3D3) : Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom Button ────────────────────────────────────────────────────────────
  Widget _buildBottomButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE62135),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () => _onFeatureTap('Request Aid'),
        child: const Text('Request Emergency Aid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

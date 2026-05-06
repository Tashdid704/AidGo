import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _openCertificate(String urlStr) async {
    try {
      final Uri url = Uri.parse(urlStr);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open certificate link.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid URL: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE62135),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Requests', icon: Icon(Icons.assignment)),
              Tab(text: 'Teams', icon: Icon(Icons.group)),
              Tab(text: 'Volunteers', icon: Icon(Icons.people)),
              Tab(text: 'Approvals', icon: Icon(Icons.how_to_reg)),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildStatsHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRequestsTab(),
                  _buildActiveTeamsTab(),
                  _buildVolunteersTab(),
                  _buildApprovalsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getPendingRequestsStream(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatCard('Total Requests', count.toString(), Colors.orange);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getVolunteersStream(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatCard('Active Volunteers', count.toString(), Colors.blue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color.withOpacity(0.9)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.getPendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No requests found.', style: TextStyle(color: Colors.grey)));

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['name'] ?? 'Unknown Request', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location: ${data['location'] ?? ''}\nUrgency: ${data['urgencyLevel'] ?? 'Normal'}'),
                    if (data['status'] == 'Assigned' || data['status'] == 'In Progress' || data['status'] == 'Completed') ...[
                      if (data['assignedTeam'] != null && (data['assignedTeam'] as List).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'Team Assigned: ${(data['assignedTeam'] as List).map((v) => v['name']).join(', ')}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ],
                    if (data['status'] == 'Pending') ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAssignVolunteerDialog(docs[index].id),
                        icon: const Icon(Icons.group_add, size: 16),
                        label: const Text('Assign Team', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFE62135),
                           foregroundColor: Colors.white,
                           elevation: 0,
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                    ],
                  ],
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  initialValue: data['status'] ?? 'Pending',
                  onSelected: (String newStatus) async {
                    try {
                      await _db.updateRequestStatus(docs[index].id, newStatus);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Status updated to $newStatus')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update status')),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Pending',
                      child: Text('Pending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'In Progress',
                      child: Text('In Progress'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(data['status'] ?? 'Pending', style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: Colors.orange.shade800),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveTeamsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.getPendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] == 'Assigned' || data['status'] == 'In Progress') &&
                 data['assignedTeam'] != null &&
                 (data['assignedTeam'] as List).isNotEmpty;
        }).toList() ?? [];

        if (docs.isEmpty) return const Center(child: Text('No active teams on duty.', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final teamMembers = data['assignedTeam'] as List<dynamic>;
            final requestId = docs[index].id;
            
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200, width: 2)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['assignedTeamName'] ?? 'Response Team',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(data['status'] ?? '', style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Mission: ${data['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Location: ${data['location'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 12),
                    const Text('Roster:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: teamMembers.map((m) {
                        return Chip(
                          label: Text(m['name'], style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade100,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark as Completed & Release Team'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                           try {
                             await _db.completeRequestAndReleaseTeam(requestId, teamMembers);
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Task Completed! Team has been released.')),
                               );
                             }
                           } catch (e) {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Error: $e')),
                               );
                             }
                           }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVolunteersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.getVolunteersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        // Filter out those still in 'Pending Approval' or 'Rejected' status
        final docs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Free' || data['status'] == 'Busy';
        }).toList() ?? [];

        if (docs.isEmpty) return const Center(child: Text('No active volunteers found.', style: TextStyle(color: Colors.grey)));
 
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final hasCertificate = data['certificateLink'] != null && data['certificateLink'].toString().trim().isNotEmpty;
            final isFree = data['status'] == 'Free';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFree ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFree ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                            ),
                          ),
                          child: Text(
                            (data['status'] ?? '').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isFree ? const Color(0xFF059669) : const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Skills: ${data['skill'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    Text('Phone: ${data['phone'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('View Profile Certificate'),
                        onPressed: hasCertificate ? () => _openCertificate(data['certificateLink']) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: BorderSide(color: hasCertificate ? const Color(0xFF3B82F6) : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.getPendingVolunteersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending applications.', style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            final uid = data['uid'] ?? '';
            final hasCert = data['certificateLink'] != null && data['certificateLink'].toString().isNotEmpty;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade50,
                          child: Text(data['name']?[0] ?? 'V', style: TextStyle(color: Colors.orange.shade800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Text('PENDING', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Skills: ${data['skill'] ?? ''}', style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 4),
                    Text('Exp: ${data['experience'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: hasCert ? () => _openCertificate(data['certificateLink']) : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: hasCert ? Colors.blue : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View Cert', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _db.approveVolunteer(id, uid);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer Approved!')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Approve', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _db.rejectVolunteer(id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Rejected.')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignVolunteerDialog(String requestId) {
    List<Map<String, String>> selectedVolunteers = [];
    TextEditingController teamNameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Assign Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: teamNameController,
                      decoration: InputDecoration(
                        labelText: 'Team Name (Required)',
                        hintText: 'e.g. Phoenix Response Team',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {}); // trigger rebuild to enable/disable button
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _db.getFreeVolunteersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No free volunteers available.', style: TextStyle(color: Colors.grey)));

                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;
                              final name = data['name'] ?? 'Unknown';
                              final isSelected = selectedVolunteers.any((element) => element['id'] == docId);
                              
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isSelected ? const Color(0xFFE62135) : Colors.grey.shade200, width: isSelected ? 2 : 1),
                                ),
                                child: CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${data['skill'] ?? 'N/A'} • ${data['area'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  value: isSelected,
                                  activeColor: const Color(0xFFE62135),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedVolunteers.add({'id': docId, 'name': name});
                                      } else {
                                        selectedVolunteers.removeWhere((element) => element['id'] == docId);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE62135),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (selectedVolunteers.isEmpty || teamNameController.text.trim().isEmpty) ? null : () async {
                          try {
                            await _db.assignVolunteerTeam(requestId, teamNameController.text.trim(), selectedVolunteers);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Team assigned successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error assigning team: $e')),
                              );
                            }
                          }
                        },
                        child: Text(
                          selectedVolunteers.isEmpty ? 'Select Volunteers' : 'Assign Selected Team (${selectedVolunteers.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }
}

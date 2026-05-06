import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class TeamAssignScreen extends StatefulWidget {
  const TeamAssignScreen({super.key});

  @override
  State<TeamAssignScreen> createState() => _TeamAssignScreenState();
}

class _TeamAssignScreenState extends State<TeamAssignScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isResetting = false;

  Future<void> _resetDatabase() async {
    setState(() => _isResetting = true);
    await _db.clearDatabaseState();
    setState(() => _isResetting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reset complete: All volunteers are Free, all requests Completed.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getPendingRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter to only truly Pending requests
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return d['status'] == 'Pending';
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No pending requests.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _buildRequestCard(docId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 24),
      decoration: const BoxDecoration(color: Color(0xFFE62135)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Assignment', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Assign volunteers to pending requests', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dev Tools Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isResetting ? null : _resetDatabase,
              icon: _isResetting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.restore, size: 16, color: Colors.white),
              label: Text(
                _isResetting ? 'Resetting...' : 'Reset All (Free Volunteers & Clear Assignments)',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.04),
             blurRadius: 10,
             offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(
                 data['name'] ?? 'Unknown Request',
                 style: const TextStyle(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFF0F172A),
                 ),
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: const Color(0xFFFEF3C7),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: const Color(0xFFFDE68A)),
                 ),
                 child: Text(
                   data['status'] ?? 'Pending',
                   style: const TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFFD97706),
                   ),
                 ),
               ),
             ],
          ),
          const SizedBox(height: 8),
          Text(
            'Location: ${data['location'] ?? ''}',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Affected: ${data['affectedCount'] ?? 0} | Urgency: ${data['urgencyLevel']}',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
          if (data['aidTypes'] != null)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Wrap(
                 spacing: 6,
                 children: (data['aidTypes'] as List).map<Widget>((type) {
                   return Chip(
                     label: Text(type.toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                     backgroundColor: const Color(0xFFF1F5F9),
                     side: BorderSide.none,
                     padding: EdgeInsets.zero,
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                   );
                 }).toList(),
               ),
             ),
          const SizedBox(height: 16),
          SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               onPressed: () => _showAssignVolunteerModal(context, requestId),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFE62135),
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 elevation: 0,
               ),
               child: const Text('Choose Team / Volunteer'),
             ),
          ),
        ],
      ),
    );
  }

  void _showAssignVolunteerModal(BuildContext context, String requestId) {
    List<Map<String, String>> selectedVolunteers = [];
    final teamNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Assign Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Team Name Field
                    TextField(
                      controller: teamNameController,
                      decoration: InputDecoration(
                        labelText: 'Team Name (Required)',
                        hintText: 'e.g. Phoenix Response Team',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Volunteers:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // Multi-select volunteer list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _db.getFreeVolunteersStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(child: Text('No free volunteers available.', style: TextStyle(color: Colors.grey)));
                          }
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final isSelected = selectedVolunteers.any((e) => e['id'] == doc.id);
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFE62135) : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  activeColor: const Color(0xFFE62135),
                                  value: isSelected,
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '${data['skill'] ?? 'N/A'} • ${data['area'] ?? 'N/A'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedVolunteers.add({'id': doc.id, 'name': name});
                                      } else {
                                        selectedVolunteers.removeWhere((e) => e['id'] == doc.id);
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
                    // Assign button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          selectedVolunteers.isEmpty
                              ? 'Select Volunteers'
                              : 'Assign Team (${selectedVolunteers.length} selected)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE62135),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: (selectedVolunteers.isEmpty || teamNameController.text.trim().isEmpty)
                            ? null
                            : () async {
                                try {
                                  await _db.assignVolunteerTeam(
                                    requestId,
                                    teamNameController.text.trim(),
                                    selectedVolunteers,
                                  );
                                  if (context.mounted) {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Team "${teamNameController.text.trim()}" assigned!'),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

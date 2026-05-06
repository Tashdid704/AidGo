import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── RBAC / Role Management ──────────────────────────────────────────────────

  /// Fetches the persisted user role from Firestore.
  /// Defaults to 'user' if no document exists yet.
  Future<String> getUserRole() async {
    try {
      final doc = await _db.collection('app_config').doc('current_session').get();
      if (doc.exists && doc.data()!.containsKey('role')) {
        return doc.data()!['role'] as String;
      }
      return 'user'; // safe default
    } catch (e) {
      print('>>> [DatabaseService] Error fetching role: $e');
      return 'user';
    }
  }

  /// Persists the selected user role to Firestore so it survives app restarts.
  Future<void> setUserRole(String role) async {
    try {
      await _db.collection('app_config').doc('current_session').set({'role': role});
    } catch (e) {
      print('>>> [DatabaseService] Error setting role: $e');
    }
  }

  Future<String> submitAidRequest({
    required String name,
    required String location,
    required int affectedCount,
    required String urgencyLevel,
    required List<String> aidTypes,
  }) async {
    try {
      print('>>> [DatabaseService] PREPARING payload for Firestore...');
      final payload = {
        'name': name,
        'location': location,
        'affectedCount': affectedCount,
        'urgencyLevel': urgencyLevel,
        'aidTypes': aidTypes,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      print('>>> [DatabaseService] INITIATING network call to Firestore...');
      DocumentReference docRef = await _db.collection('requests').add(payload).timeout(const Duration(seconds: 10)); 
      
      print('>>> [DatabaseService] SUCCESS: Firestore acknowledged write.');
      return docRef.id;
    } catch (e) {
      print('>>> [DatabaseService] ERROR: Firebase call threw an exception: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getVolunteersStream() {
    return _db.collection('volunteers').orderBy('name').snapshots();
  }

  Stream<QuerySnapshot> getFreeVolunteersStream() {
    return _db.collection('volunteers').where('status', isEqualTo: 'Free').snapshots();
  }

  Stream<QuerySnapshot> getPendingRequestsStream() {
    // Returning all requests temporarily to ensure you can test the UI regardless of actual document fields!
    return _db.collection('requests').snapshots();
  }

  Future<void> assignVolunteerTeam(String requestId, String teamName, List<Map<String, String>> team) async {
    if (team.isEmpty) return;

    WriteBatch batch = _db.batch();
    DocumentReference requestRef = _db.collection('requests').doc(requestId);

    // Extracting just the IDs for easy querying in TasksScreen
    List<String> volunteerIds = team.map((v) => v['id']!).toList();

    batch.update(requestRef, {
      'status': 'Assigned',
      'assignedTeam': team,
      'assignedTeamName': teamName,
      'assignedVolunteerIds': volunteerIds, // Added for efficient filtering
    });

    for (var volunteer in team) {
      DocumentReference volunteerRef = _db.collection('volunteers').doc(volunteer['id']);
      batch.update(volunteerRef, {'status': 'Busy'});
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error assigning team: $e');
      rethrow;
    }
  }

  // --- Task Synchronization Helpers ---

  /// Helper to find the Volunteer document ID associated with a user's Firebase UID.
  Future<String?> getVolunteerDocIdByUid(String uid) async {
    try {
      final snapshot = await _db.collection('volunteers')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding volunteer doc: $e');
      return null;
    }
  }

  /// Global stream for Admins to monitor all active assignments.
  Stream<QuerySnapshot> getAllAssignedTasksStream() {
    return _db.collection('requests')
        .where('status', whereIn: ['Assigned', 'In Progress'])
        .snapshots();
  }

  /// Personalized stream for Volunteers to see only their assigned missions.
  Stream<QuerySnapshot> getAssignedTasksForVolunteer(String volunteerDocId) {
    return _db.collection('requests')
        .where('status', whereIn: ['Assigned', 'In Progress'])
        .where('assignedVolunteerIds', arrayContains: volunteerDocId)
        .snapshots();
  }

  // --- Volunteer Approval System ---

  Stream<QuerySnapshot> getPendingVolunteersStream() {
    return _db.collection('volunteers')
        .where('status', isEqualTo: 'Pending Approval')
        .snapshots();
  }

  Future<void> approveVolunteer(String volunteerId, String uid) async {
    WriteBatch batch = _db.batch();
    
    // 1. Update volunteer status
    DocumentReference volunteerRef = _db.collection('volunteers').doc(volunteerId);
    batch.update(volunteerRef, {'status': 'Free'});
    
    // 2. Update user role in 'users' collection
    DocumentReference userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {'role': 'volunteer'});
    
    try {
      await batch.commit();
    } catch (e) {
      print('Error approving volunteer: $e');
      rethrow;
    }
  }

  Future<void> rejectVolunteer(String volunteerId) async {
    try {
      await _db.collection('volunteers').doc(volunteerId).update({'status': 'Rejected'});
    } catch (e) {
      print('Error rejecting volunteer: $e');
      rethrow;
    }
  }

  Future<String?> getVolunteerStatusByUid(String uid) async {
    try {
      final snapshot = await _db.collection('volunteers')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('status') as String;
      }
      return null;
    } catch (e) {
      print('Error checking volunteer status: $e');
      return null;
    }
  }

  Future<void> completeRequestAndReleaseTeam(String requestId, List<dynamic> teamMembers) async {
    WriteBatch batch = _db.batch();
    DocumentReference requestRef = _db.collection('requests').doc(requestId);

    batch.update(requestRef, {'status': 'Completed'});

    for (var volunteer in teamMembers) {
      if (volunteer is Map && volunteer.containsKey('id')) {
        DocumentReference volunteerRef = _db.collection('volunteers').doc(volunteer['id']);
        batch.update(volunteerRef, {'status': 'Free'});
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error completing request & releasing team: $e');
      rethrow;
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _db.collection('requests').doc(requestId).update({'status': status});
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }

  // --- Real-time Tracking ---

  Future<void> updateVolunteerLocation({
    required String volunteerId,
    required double lat,
    required double lng,
    required String requestId,
    required String status,
  }) async {
    try {
      await _db.collection('tracking').doc(volunteerId).set({
        'latitude': lat,
        'longitude': lng,
        'requestId': requestId,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating volunteer location: $e');
    }
  }

  Future<void> updateTaskLocation(String requestId, double lat, double lng) async {
    try {
      await _db.collection('requests').doc(requestId).update({
        'volunteerLatitude': lat,
        'volunteerLongitude': lng,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('>>> [DatabaseService] Error updating task location: $e');
    }
  }

  Stream<DocumentSnapshot> getRequestStream(String requestId) {
    return _db.collection('requests').doc(requestId).snapshots();
  }

  Stream<DocumentSnapshot> getVolunteerLocationStream(String volunteerId) {
    return _db.collection('tracking').doc(volunteerId).snapshots();
  }

  Future<void> registerVolunteer({
    required String uid, // Now requiring UID to link user to profile
    required String name,
    required String phone,
    required String email,
    required String area,
    required List<String> skills,
    required String availability,
    required String experience,
    required String certificateLink,
  }) async {
    try {
      print('>>> [DatabaseService] INITIATING network call to register volunteer...');
      await _db.collection('volunteers').add({
        'uid': uid, // Identity Link
        'name': name,
        'phone': phone,
        'email': email,
        'area': area,
        'skill': skills.join(', '), 
        'availability': availability,
        'experience': experience,
        'certificateLink': certificateLink,
        'status': 'Pending Approval', // Initially pending
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('>>> [DatabaseService] SUCCESS: Volunteer registered.');
    } catch (e) {
      print('>>> [DatabaseService] ERROR: Volunteer registration failed: $e');
      rethrow;
    }
  }

  Future<void> seedVolunteers() async {
    try {
      final snapshot = await _db.collection('volunteers').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Already seeded
      }

      final volunteers = [
        {
          'name': 'New Volunteer',
          'skill': 'Medical / First Aid',
          'area': 'District A',
          'phone': '+8801XXXXXXXXX',
          'status': 'Free',
        },
        {
          'name': 'Rahim Ahmed',
          'skill': 'Medical / First Aid',
          'area': 'District A',
          'phone': '+8801711000001',
          'status': 'Free',
        },
        {
          'name': 'Nila Sultana',
          'skill': 'Food Distribution',
          'area': 'District B',
          'phone': '+8801711000002',
          'status': 'Busy',
        },
        {
          'name': 'Karim Hasan',
          'skill': 'Search & Rescue',
          'area': 'District A',
          'phone': '+8801711000003',
          'status': 'Free',
        },
        {
          'name': 'Fatima Begum',
          'skill': 'Transportation',
          'area': 'District C',
          'phone': '+8801711000004',
          'status': 'Free',
        },
      ];

      WriteBatch batch = _db.batch();
      for (var v in volunteers) {
        DocumentReference ref = _db.collection('volunteers').doc();
        batch.set(ref, v);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error seeding volunteers: $e');
    }
  }

  // --- ONE-TIME UTILITY ---
  Future<void> clearDatabaseState() async {
    try {
      WriteBatch batch = _db.batch();
      
      // Reset all volunteers to 'Free'
      var volunteerSnapshot = await _db.collection('volunteers').get();
      for (var doc in volunteerSnapshot.docs) {
        batch.update(doc.reference, {'status': 'Free'});
      }

      // Mark all non-completed requests as 'Completed'
      var requestSnapshot = await _db.collection('requests').get();
      for (var doc in requestSnapshot.docs) {
        var data = doc.data();
        if (data['status'] != 'Completed') {
          batch.update(doc.reference, {'status': 'Completed'});
        }
      }

      await batch.commit();
      print('>>> [DatabaseService] Database successfully cleared to clean state.');
    } catch (e) {
      print('>>> [DatabaseService] Error clearing database: $e');
    }
  }
}

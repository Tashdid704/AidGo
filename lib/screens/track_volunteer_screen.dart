import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/database_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng; // Only for Type

class TrackVolunteerScreen extends StatefulWidget {
  final String requestId;
  final String volunteerName;
  final String destinationName;

  const TrackVolunteerScreen({
    super.key,
    required this.requestId,
    required this.volunteerName,
    required this.destinationName,
  });

  @override
  State<TrackVolunteerScreen> createState() => _TrackVolunteerScreenState();
}

class _TrackVolunteerScreenState extends State<TrackVolunteerScreen> {
  final DatabaseService _db = DatabaseService();

  // State
  String _distance = "Calculating...";
  String _duration = "...";
  bool _isManualSimulating = false;
  Timer? _manualSimTimer;
  LatLng? _currentVolunteerPos;
  
  // --- Dhaka Coordinate Mapper (Simulation) ---
  static const Map<String, LatLng> _dhakaCoords = {
    'Dhanmondi': LatLng(23.7461, 90.3742),
    'Mirpur': LatLng(23.8223, 90.3654),
    'Tejgaon': LatLng(23.7599, 90.3913),
    'Gulshan': LatLng(23.7925, 90.4078),
    'Banani': LatLng(23.7940, 90.4043),
    'Uttara': LatLng(23.8759, 90.3795),
  };

  LatLng get _destination => _dhakaCoords[widget.destinationName] ?? const LatLng(23.8103, 90.4125); 

  @override
  void dispose() {
    _manualSimTimer?.cancel();
    super.dispose();
  }

  void _toggleManualSimulation() {
    setState(() => _isManualSimulating = !_isManualSimulating);
    
    if (_isManualSimulating) {
      // Start slightly north-east of destination
      double currentLat = _destination.latitude + 0.005;
      double currentLng = _destination.longitude + 0.008;
      
      _manualSimTimer?.cancel();
      _manualSimTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!_isManualSimulating) {
          timer.cancel();
          return;
        }
        
        // Move towards destination
        currentLat -= 0.0001; 
        currentLng -= 0.00015;
        
        await _db.updateTaskLocation(widget.requestId, currentLat, currentLng);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔥 SHOWCASE SIMULATION: ACTIVE')),
      );
    } else {
      _manualSimTimer?.cancel();
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude, p1.longitude,
      p2.latitude, p2.longitude,
    ) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.getRequestStream(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading track.'));
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Waiting for connection...'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final double? lat = data['volunteerLatitude'];
          final double? lng = data['volunteerLongitude'];

          if (lat == null || lng == null) {
            return const Center(child: Text('Establishing GPS connection...'));
          }

          _currentVolunteerPos = LatLng(lat, lng);
          
          double distKm = _calculateDistance(_currentVolunteerPos!, _destination);
          _distance = "${distKm.toStringAsFixed(2)} km";
          _duration = "${(distKm * 8).toInt()} mins"; 

          return Stack(
            children: [
              // 1. Permanent High-Fidelity Mock Map Background
              Positioned.fill(
                child: Image.asset(
                  'assets/mock_map.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Custom Route Painter (Polyline)
              Positioned.fill(
                child: CustomPaint(
                  painter: MockPathPainter(
                    start: _currentVolunteerPos!,
                    end: _destination,
                    mockAreaCenter: _destination,
                  ),
                ),
              ),

              // 3. Animated Volunteer Marker (Sliding Effect)
              _buildMockMarker(_currentVolunteerPos!, 'volunteer'),

              // 4. Static User Destination Marker
              _buildMockMarker(_destination, 'destination', isUser: true),

              // 5. Showcase Simulation Control (Floating)
              Positioned(
                top: 100,
                right: 20,
                child: FloatingActionButton.small(
                  onPressed: _toggleManualSimulation,
                  backgroundColor: _isManualSimulating ? Colors.red : Colors.green,
                  child: Icon(_isManualSimulating ? Icons.stop : Icons.play_arrow, color: Colors.white),
                ),
              ),

              // 6. Bottom Information Card
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: _buildBottomStats(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockMarker(LatLng pos, String id, {bool isUser = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double centerX = constraints.maxWidth / 2;
        double centerY = constraints.maxHeight / 2;
        double scale = 20000.0; // Zoom scale for the static image
        
        double offsetX = (pos.longitude - _destination.longitude) * scale;
        double offsetY = (_destination.latitude - pos.latitude) * scale;

        return AnimatedPositioned(
          duration: const Duration(seconds: 1), // Ultra-smooth update frequency
          curve: Curves.easeInOut,
          left: centerX + offsetX - 24,
          top: centerY + offsetY - 24,
          child: isUser 
            ? const Icon(Icons.location_on, color: Color(0xFF8B5CF6), size: 48)
            : Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
                ),
                child: Image.asset('assets/launcher_icon.png', width: 44, height: 44),
              ),
        );
      },
    );
  }

  Widget _buildBottomStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
              image: const DecorationImage(image: AssetImage('assets/launcher_icon.png')),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.volunteerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('$_distance — $_duration', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class MockPathPainter extends CustomPainter {
  final LatLng start;
  final LatLng end;
  final LatLng mockAreaCenter;

  MockPathPainter({required this.start, required this.end, required this.mockAreaCenter});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double scale = 20000.0;

    Offset p1 = Offset(
      centerX + (start.longitude - mockAreaCenter.longitude) * scale,
      centerY + (mockAreaCenter.latitude - start.latitude) * scale,
    );

    Offset p2 = Offset(
      centerX + (end.longitude - mockAreaCenter.longitude) * scale,
      centerY + (mockAreaCenter.latitude - end.latitude) * scale,
    );

    // Draw route line
    canvas.drawLine(p1, p2, paint);
    
    // Draw subtle dots along the path for "premium" feel
    final dotPaint = Paint()..color = const Color(0xFF8B5CF6);
    canvas.drawCircle(p1, 4, dotPaint);
    canvas.drawCircle(p2, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'volunteer_list_screen.dart';

class VolunteerSuccessScreen extends StatelessWidget {
  const VolunteerSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: Color(0xFFE6F4EA), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('🤝', style: TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Welcome, Volunteer!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    const Text('You have successfully joined the network.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               backgroundColor: const Color(0xFF1E293B),
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               elevation: 0,
                            ),
                            onPressed: () {
                               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VolunteerListScreen()));
                            },
                            child: const Text('Volunteer List', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               foregroundColor: const Color(0xFF1E293B),
                               side: BorderSide(color: Colors.grey.shade300),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                               Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            child: const Text('Back Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 40),
      decoration: const BoxDecoration(color: Color(0xFFE62135)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 12, top: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
               Text('Volunteer Confirmed', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
               SizedBox(height: 4),
               Text('Registration successful', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

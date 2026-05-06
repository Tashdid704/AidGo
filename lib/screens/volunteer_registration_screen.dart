import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'volunteer_success_screen.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  const VolunteerRegistrationScreen({super.key});

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _certificateController = TextEditingController();
  
  bool _isLoading = false;
  
  final Map<String, bool> _skills = {
    'Medical / First Aid': true,
    'Food Distribution': false,
    'Search & Rescue': false,
    'Transportation': false,
    'Logistics': false,
  };
  
  String _availability = 'Weekdays';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _areaController.dispose();
    _experienceController.dispose();
    _certificateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    _buildTextField('Enter your name', _nameController),
                    const SizedBox(height: 16),
                    _buildLabel('Phone (Required)'),
                    _buildTextField('+8801XXXXXXXXX', _phoneController, isNumber: true),
                    const SizedBox(height: 16),
                    _buildLabel('Email'),
                    _buildTextField('email@example.com', _emailController),
                    const SizedBox(height: 16),
                    _buildLabel('Area / Location'),
                    _buildTextField('District / City', _areaController),
                    const SizedBox(height: 16),
                    _buildLabel('Skills'),
                    _buildSkillsCheckboxes(),
                    const SizedBox(height: 16),
                    _buildLabel('Availability'),
                    _buildAvailabilityPills(),
                    const SizedBox(height: 16),
                    _buildLabel('Provide certificate link for verification'),
                    _buildTextField('https://drive.google.com/...', _certificateController),
                    const SizedBox(height: 16),
                    _buildLabel('Previous Experience Description'),
                    _buildTextArea('Briefly describe any previous experience', _experienceController),
                    const SizedBox(height: 24),
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 40),
      decoration: const BoxDecoration(color: Color(0xFFE62135)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
              Text('Volunteer Registration', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Join as a helper', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE62135))),
      ),
    );
  }

  Widget _buildTextArea(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE62135))),
      ),
    );
  }

  Widget _buildSkillsCheckboxes() {
    return Column(
      children: _skills.keys.map((skill) {
        final isSelected = _skills[skill]!;
        return GestureDetector(
          onTap: () => setState(() => _skills[skill] = !isSelected),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF6EE7B7) : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(skill, style: TextStyle(color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569), fontSize: 14))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityPills() {
    return Row(
      children: ['Weekdays', 'Weekend', 'Anytime'].map((level) {
        final isSelected = _availability == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _availability = level),
            child: Container(
              margin: EdgeInsets.only(right: level == 'Anytime' ? 0 : 8),
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                level,
                style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF475569), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE62135),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : () async {
          if (_phoneController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number is required!'), backgroundColor: Colors.red));
            return;
          }
          setState(() { _isLoading = true; });

          final selectedSkills = _skills.entries.where((e) => e.value).map((e) => e.key).toList();

          try {
            final uid = AuthService().currentUser?.uid ?? 'unknown_uid';
            await DatabaseService().registerVolunteer(
              uid: uid,
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              area: _areaController.text.trim(),
              skills: selectedSkills,
              availability: _availability,
              experience: _experienceController.text.trim(),
              certificateLink: _certificateController.text.trim(),
            );

            if (context.mounted) {
              setState(() { _isLoading = false; });
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VolunteerSuccessScreen()));
            }
          } catch (e) {
            if (context.mounted) {
              setState(() { _isLoading = false; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red));
            }
          }
        },
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Register as Volunteer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

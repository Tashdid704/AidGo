import 'package:flutter/material.dart';

// Global variables for prototype persistence during the session
double globalTotalDonated = 55000.0;
Map<String, double> globalAllocations = {
  'Food': 5000.0,
  'Medicine': 3000.0,
  'Rescue': 2000.0,
};

List<Map<String, dynamic>> globalDonationHistory = [
  {'name': 'John Smith', 'amount': '500', 'time': '2 hours ago', 'method': 'bKash'},
  {'name': 'Sarah Johnson', 'amount': '1200', 'time': '5 hours ago', 'method': 'Nagad'},
];

class DonationScreen extends StatefulWidget {
  final bool isReadOnly; // Added for role-based transparency
  const DonationScreen({super.key, this.isReadOnly = false});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  String _selectedAmount = '500';
  String _selectedPayment = 'bKash';
  bool _isAdminMode = false; // Toggle between Donor and Admin/Transparency views

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '500');

  double get _totalAllocated => globalAllocations.values.fold(0, (sum, val) => sum + val);
  double get _availableFund => globalTotalDonated - _totalAllocated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── View Toggle ──
                  _buildViewToggle(),
                  const SizedBox(height: 24),

                  if (!_isAdminMode) ...[
                    // ── DONOR VIEW ──
                    _buildTotalDonatedCard(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildRecentDonations(),
                    const SizedBox(height: 24),
                    _buildDonationForm(),
                  ] else ...[
                    // ── ADMIN / TRANSPARENCY VIEW ──
                    _buildTransparencySummaryCard(),
                    const SizedBox(height: 24),
                    Text(
                      widget.isReadOnly ? 'Budget Allocation (Transparency)' : 'Budget Management',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    ...globalAllocations.entries.map((e) => _buildSectorAllocationCard(e.key, e.value)),
                    const SizedBox(height: 24),
                    _buildAllocationStats(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    final secondTabLabel = widget.isReadOnly ? 'Transparency View' : 'Admin View';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem('Donor View', !_isAdminMode, () => setState(() => _isAdminMode = false)),
          ),
          Expanded(
            child: _buildToggleItem(secondTabLabel, _isAdminMode, () => setState(() => _isAdminMode = true)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE62135) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTransparencySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isReadOnly ? 'Remaining Fund' : 'Available Fund', 
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('${_availableFund.toInt()}৳',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Allocated', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('${_totalAllocated.toInt()}৳',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE62135))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: globalTotalDonated > 0 ? _totalAllocated / globalTotalDonated : 0,
              backgroundColor: Colors.grey.shade100,
              color: const Color(0xFFE62135),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isReadOnly 
                ? 'Trust Ledger: ${((_totalAllocated / globalTotalDonated) * 100).toInt()}% of collected funds have been put to work.'
                : 'Management: ${((_totalAllocated / globalTotalDonated) * 100).toInt()}% of total funds items allocated',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorAllocationCard(String sector, double allocated) {
    double percentOfTotal = globalTotalDonated > 0 ? allocated / globalTotalDonated : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE62135).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getSectorIcon(sector), color: const Color(0xFFE62135), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(sector, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('${allocated.toInt()}৳', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentOfTotal,
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFF1E293B),
                    minHeight: 6,
                  ),
                ),
              ),
              if (!widget.isReadOnly) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _showAllocationDialog(sector),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Allocate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSectorIcon(String sector) {
    switch (sector) {
      case 'Food': return Icons.restaurant;
      case 'Medicine': return Icons.medical_services;
      case 'Rescue': return Icons.emergency;
      default: return Icons.category;
    }
  }

  void _showAllocationDialog(String sector) {
    if (widget.isReadOnly) return; // Safeguard

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Allocate to $sector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max available: ${_availableFund.toInt()}৳', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              
              if (amount > _availableFund) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient funds available!'),
                    backgroundColor: Color(0xFFE62135),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                setState(() {
                  globalAllocations[sector] = (globalAllocations[sector] ?? 0) + amount;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully allocated ${amount.toInt()}৳ to $sector'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE62135)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resource Distribution', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildDistRow('Essential Food', globalAllocations['Food'] ?? 0),
          _buildDistRow('Medical Support', globalAllocations['Medicine'] ?? 0),
          _buildDistRow('Emergency Rescue', globalAllocations['Rescue'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildDistRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text('${amount.toInt()}৳', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── PREVIOUSLY IMPLEMENTED WIDGETS ──

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 20),
      color: const Color(0xFFE62135),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const Text('Donations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTotalDonatedCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE62135), Color(0xFFC01A2B)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFFE62135).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('Total Funds Collected', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${globalTotalDonated.toInt()}৳', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Goal: 100,000৳', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${globalDonationHistory.length + 242}', 'Donors', Icons.people_alt, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('1,450', 'Items', Icons.inventory_2, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildRecentDonations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Donations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ...globalDonationHistory.take(5).map((d) => _buildDonationItem(d)),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _showAllDonations,
              child: const Text('View Full History', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationItem(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text(d['method'] ?? 'Online', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${d['amount']}৳', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE62135))),
              Text(d['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Make a Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAmountChip('500'),
              const SizedBox(width: 8),
              _buildAmountChip('1000'),
              const SizedBox(width: 8),
              _buildAmountChip('5000'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Amount (৳)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _selectedAmount = ''),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Your Name (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. Jisan',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaymentChip('bKash'),
              const SizedBox(width: 8),
              _buildPaymentChip('Nagad'),
              const SizedBox(width: 8),
              _buildPaymentChip('Rocket'),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final amountStr = _amountController.text.trim();
                final donationValue = double.tryParse(amountStr) ?? 0;

                if (donationValue > 0) {
                  setState(() {
                    globalTotalDonated += donationValue;
                    globalDonationHistory.insert(0, {
                      'name': _nameController.text.isEmpty ? 'Jisan' : _nameController.text.trim(),
                      'amount': amountStr,
                      'time': 'Just now',
                      'method': _selectedPayment,
                    });
                  });
                  _showSuccessDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE62135),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Donate Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            const Text('Donation Successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to Home
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE62135)),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllDonations() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Donation History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: globalDonationHistory.length,
                itemBuilder: (context, index) => _buildDonationItem(globalDonationHistory[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(String amount) {
    bool isSelected = _selectedAmount == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedAmount = amount;
          _amountController.text = amount;
        }),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade200),
          ),
          child: Text('$amount৳', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String method) {
    bool isSelected = _selectedPayment == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPayment = method),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFE62135) : Colors.grey.shade200, width: isSelected ? 2 : 1),
          ),
          child: Text(method, style: TextStyle(color: isSelected ? const Color(0xFFE62135) : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

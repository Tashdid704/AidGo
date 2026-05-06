import 'package:flutter/material.dart';

class ResourcesScreen extends StatefulWidget {
  final bool isAdmin;
  const ResourcesScreen({super.key, this.isAdmin = false});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  // Inventory simulation data
  final List<Map<String, String>> _resources = [
    {'name': 'Water Bottles (500ml)', 'loc': 'Warehouse A', 'qty': '1500', 'status': 'Available'},
    {'name': 'Emergency Food Rations', 'loc': 'Warehouse A', 'qty': '800', 'status': 'Available'},
    {'name': 'First Aid Kits', 'loc': 'Medical Center', 'qty': '210', 'status': 'Available'},
    {'name': 'Blankets', 'loc': 'Warehouse B', 'qty': '450', 'status': 'Available'},
    {'name': 'Tents (4-person)', 'loc': 'Storage Unit 1', 'qty': '50', 'status': 'Low Stock'},
    {'name': 'Flashlights', 'loc': 'Warehouse B', 'qty': '200', 'status': 'Available'},
  ];

  // Dynamic calculation for stats
  int get _totalItemCount {
    return _resources.fold(0, (sum, item) => sum + int.parse(item['qty']!.replaceAll(',', '')));
  }

  // ── Logic: Add Resource ──
  void _showAddResourceModal() {
    final nameController = TextEditingController();
    final locController = TextEditingController();
    final qtyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add New Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Life Jackets',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locController,
              decoration: InputDecoration(
                labelText: 'Warehouse Location',
                hintText: 'e.g. Warehouse C',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g. 100',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                    setState(() {
                      _resources.insert(0, {
                        'name': nameController.text.trim(),
                        'loc': locController.text.isEmpty ? 'Warehouse A' : locController.text.trim(),
                        'qty': qtyController.text.trim(),
                        'status': 'Available',
                      });
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${nameController.text} added to inventory'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(20),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Simulation: Export Report ──
  Future<void> _handleExportReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFFE62135)),
            SizedBox(height: 24),
            Text('Generating Inventory Report...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Processing data from all warehouses', style: TextStyle(color: Colors.grey, fontSize: 13)),
            SizedBox(height: 16),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('✅ Inventory Report (PDF) saved to /Downloads'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  // ── Simulation: Request Restocking ──
  void _handleRequestRestocking() {
    String? selectedItem;
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            const Text('Request Restocking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Choose item and quantity to request from Head Office', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Resource Item',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: <String>['Water Bottles', 'Food Rations', 'Medicine Kits', 'Tents', 'Blankets', 'Oxygen Tanks']
                  .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (val) => selectedItem = val,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Requested Quantity',
                hintText: 'e.g. 500',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedItem != null && quantityController.text.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Text('🚀 Restocking request sent to Head Office'),
                          ],
                        ),
                        backgroundColor: const Color(0xFFE62135),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(20),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE62135),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSearchCard(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildInventoryCard(),
                  const SizedBox(height: 24),
                  if (widget.isAdmin) _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 40),
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
          const Text('Resource Inventory', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search resources...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE62135), width: 1.5)),
            ),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _showAddResourceModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Add Resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('${_resources.length}', 'Categories'),
        _buildStatCard('$_totalItemCount', 'Total Items'),
        _buildStatCard('1', 'Low Stock', isAlert: true),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, {bool isAlert = false}) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          FittedBox(child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isAlert ? const Color(0xFFE11D48) : Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Resource', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ..._resources.map((res) => _buildResourceRow(res)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildResourceRow(Map<String, String> res) {
    bool isLow = res['status'] == 'Low Stock';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(res['loc']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res['qty']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Unit', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: isLow ? const Color(0xFFFFE4E6) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                    child: Text(res['status']!, style: TextStyle(color: isLow ? const Color(0xFFE11D48) : const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildBottomButton('Export Inventory Report', _handleExportReport),
        const SizedBox(height: 12),
        _buildBottomButton('Request Restocking', _handleRequestRestocking),
      ],
    );
  }

  Widget _buildBottomButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

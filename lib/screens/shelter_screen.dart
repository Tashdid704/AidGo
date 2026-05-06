import 'package:flutter/material.dart';

class ShelterScreen extends StatefulWidget {
  final bool isAdmin;
  const ShelterScreen({super.key, this.isAdmin = false});

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  // Mutable state list for shelters
  late List<Map<String, dynamic>> _shelters;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shelters = [
      {
        'name': 'Dhanmondi School Shelter',
        'address': 'Road 27, Dhanmondi, Dhaka',
        'capacity': 500,
        'occupied': 320,
        'phone': '+880 1711-123456',
        'type': 'School',
        'distance': '1.2 km',
      },
      {
        'name': 'City College Cyclone Center',
        'address': 'Mirpur Road, Dhaka',
        'capacity': 800,
        'occupied': 750,
        'phone': '+880 1822-654321',
        'type': 'Center',
        'distance': '0.8 km',
      },
      {
        'name': 'Tejgaon Community Hall',
        'address': 'Begum Rokeya Avenue, Tejgaon',
        'capacity': 300,
        'occupied': 120,
        'phone': '+880 1933-987654',
        'type': 'Hall',
        'distance': '2.5 km',
      },
      {
        'name': 'Rayer Bazar High School',
        'address': 'Rayer Bazar, Dhanmondi',
        'capacity': 400,
        'occupied': 400,
        'phone': '+880 1644-111222',
        'type': 'School',
        'distance': '1.5 km',
      },
      {
        'name': 'Gulshan North Club',
        'address': 'Gulshan 2, Dhaka',
        'capacity': 200,
        'occupied': 45,
        'phone': '+880 1555-333444',
        'type': 'Club',
        'distance': '4.1 km',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredShelters {
    return _shelters.where((s) {
      final matchesCategory = _selectedCategory == 'All' || s['type'] == _selectedCategory.replaceAll('s', '').replaceAll('ies', 'y');
      // Special case for 'Schools' matching 'School'
      final type = s['type'].toString().toLowerCase();
      final category = _selectedCategory.toLowerCase();
      
      bool categoryMatch = false;
      if (category == 'all') {
        categoryMatch = true;
      } else if (category == 'schools' && type == 'school') {
        categoryMatch = true;
      } else if (category == 'centers' && type == 'center') {
        categoryMatch = true;
      } else if (category == 'halls' && type == 'hall') {
        categoryMatch = true;
      } else if (type == category) {
        categoryMatch = true;
      }

      final nameMatch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final addressMatch = s['address'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatch && (nameMatch || addressMatch);
    }).toList();
  }

  void _updateOccupancy(String shelterName, int delta) {
    setState(() {
      final index = _shelters.indexWhere((s) => s['name'] == shelterName);
      if (index != -1) {
        int newVal = _shelters[index]['occupied'] + delta;
        if (newVal >= 0 && newVal <= _shelters[index]['capacity']) {
          _shelters[index]['occupied'] = newVal;
        }
      }
    });
  }

  void _addNewShelter(String name, int capacity) {
    setState(() {
      _shelters.insert(0, {
        'name': name,
        'address': 'Primary Response Zone',
        'capacity': capacity,
        'occupied': 0,
        'phone': 'N/A',
        'type': 'New Shelter',
        'distance': 'Local',
      });
    });
  }

  Future<void> _showAddShelterDialog() async {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Shelter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Shelter Name'),
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && capacityController.text.isNotEmpty) {
                _addNewShelter(nameController.text, int.parse(capacityController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      floatingActionButton: widget.isAdmin 
        ? FloatingActionButton(
            onPressed: _showAddShelterDialog,
            backgroundColor: const Color(0xFFE62135),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredShelters.length + 2, // Search bar + Title + List
              itemBuilder: (context, index) {
                if (index == 0) return _buildSearchAndFilter();
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Shelters',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                          Text(
                            '${_filteredShelters.length} found',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                      ],
                    ),
                  );
                }
                final shelter = _filteredShelters[index - 2];
                return _buildShelterCard(shelter);
              },
            ),
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Emergency Shelters',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search for a shelter...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20), 
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  }) 
              : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE62135), width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('Schools'),
              _buildFilterChip('Centers'),
              _buildFilterChip('Halls'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE62135) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFE62135) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }


  Widget _buildShelterCard(Map<String, dynamic> shelter) {
    double occupancyRate = shelter['occupied'] / shelter['capacity'];
    bool isFull = occupancyRate >= 1.0;
    bool isCrowded = occupancyRate > 0.8;

    Color progressColor = isFull ? const Color(0xFFE11D48) : (isCrowded ? Colors.orange : const Color(0xFF10B981));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE62135).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(shelter['type'], style: const TextStyle(color: Color(0xFFE62135), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(shelter['distance'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(shelter['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(shelter['address'], style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Occupancy: ${shelter['occupied']}/${shelter['capacity']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
              Text('${(occupancyRate * 100).toInt()}% Full', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: occupancyRate, backgroundColor: Colors.grey.shade100, color: progressColor, minHeight: 8),
          ),
          const SizedBox(height: 20),

          // ── Occupancy Controls ──
          Row(
            children: [
              if (widget.isAdmin) ...[
                _buildOccupancyBtn(Icons.remove, () => _updateOccupancy(shelter['name'], -1)),
                const SizedBox(width: 12),
                _buildOccupancyBtn(Icons.add, () => _updateOccupancy(shelter['name'], 1)),
              ],
              const Spacer(),
              _buildActionBtn(Icons.phone_in_talk_outlined, 'Call', const Color(0xFFE62135), true),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildOccupancyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF475569)),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, bool isOutline) {
    return SizedBox(
      height: 40,
      width: 100,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

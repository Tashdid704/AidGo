import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'success_screen.dart';
import '../services/database_service.dart';
import '../data/bd_locations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
class RequestAidScreen extends StatefulWidget {
  const RequestAidScreen({super.key});

  @override
  State<RequestAidScreen> createState() => _RequestAidScreenState();
}

class _RequestAidScreenState extends State<RequestAidScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  String? _selectedUnion;
  int _peopleAffected = 1;
  String _urgencyLevel = 'Critical';
  bool _isLoading = false;
  bool _isLocationLoading = false;
  final Map<String, bool> _aidTypes = {
    'Food & Water': true,
    'Medical': false,
    'Shelter': false,
    'Rescue': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    _buildTextField('Enter your name', _nameController),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Location (Required)'),
                        _buildLocationTrackButton(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLocationDropdowns(),
                    const SizedBox(height: 16),
                    _buildLabel('Village / Street / Address (Optional)'),
                    _buildTextField('Enter specific village or address', _villageController),
                    const SizedBox(height: 16),
                    _buildLabel('Number of People Affected'),
                    _buildCounter(),
                    const SizedBox(height: 16),
                    _buildLabel('Urgency Level'),
                    _buildUrgencyLevel(),
                    const SizedBox(height: 16),
                    _buildLabel('Type of Aid Needed'),
                    _buildAidTypes(),
                    const SizedBox(height: 16),
                    _buildLabel('Additional Note'),
                    _buildTextArea('Describe the situation briefly'),
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (_) {
        // Ignored here to allow null check below to handle it
      }

      if (position == null) {
        throw Exception('Location unavailable');
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String? fetchedDiv = place.administrativeArea?.replaceAll(' Division', '');
        String? fetchedDist = place.subAdministrativeArea?.replaceAll(' District', '');
        String? fetchedUpazila = place.locality; // or subLocality
        if (fetchedUpazila == null || fetchedUpazila.isEmpty) {
          fetchedUpazila = place.subLocality;
        }

        // Try to match with bdLocations
        String? matchedDiv;
        String? matchedDist;
        String? matchedUpazila;

        if (fetchedDiv != null) {
          for (var div in bdLocations.keys) {
            if (div.toLowerCase() == fetchedDiv.toLowerCase()) {
              matchedDiv = div;
              break;
            }
          }
        }
        
        if (matchedDiv != null && fetchedDist != null) {
          for (var dist in bdLocations[matchedDiv]!.keys) {
            String cleanDist = dist.toLowerCase().replaceAll(' sadar', '');
            String cleanFetchedDist = fetchedDist.toLowerCase().replaceAll(' sadar', '');
            if (dist.toLowerCase() == fetchedDist.toLowerCase() || cleanDist == cleanFetchedDist) {
              matchedDist = dist;
              break;
            }
          }
        }

        if (matchedDiv != null && matchedDist != null && fetchedUpazila != null) {
          for (var upz in bdLocations[matchedDiv]![matchedDist]!.keys) {
            String cleanUpz = upz.toLowerCase().replaceAll(' sadar', '');
            String cleanFetchedUpz = fetchedUpazila.toLowerCase().replaceAll(' sadar', '');
            if (upz.toLowerCase() == fetchedUpazila.toLowerCase() || 
                cleanUpz == cleanFetchedUpz ||
                upz.toLowerCase().contains(fetchedUpazila.toLowerCase()) ||
                fetchedUpazila.toLowerCase().contains(upz.toLowerCase())) {
              matchedUpazila = upz;
              break;
            }
          }
        }

        setState(() {
          if (matchedDiv != null) _selectedDivision = matchedDiv;
          if (matchedDist != null) _selectedDistrict = matchedDist;
          if (matchedUpazila != null) _selectedUpazila = matchedUpazila;
          _selectedUnion = null; 
          
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
          if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
          if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
          
          if (addressParts.isNotEmpty) {
            _villageController.text = addressParts.join(', ');
          }
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location automatically filled! Please verify and select Union if missing.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location unavailable. Please select manually.')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Widget _buildLocationTrackButton() {
    return TextButton.icon(
      onPressed: _isLocationLoading ? null : _getCurrentLocation,
      icon: _isLocationLoading 
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE62135)))
          : const Icon(Icons.my_location, size: 16, color: Color(0xFFE62135)),
      label: Text(
        _isLocationLoading ? 'Loading...' : 'Auto-detect Location',
        style: const TextStyle(color: Color(0xFFE62135), fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFFE62135),
      ),
      child: Row(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Request Aid',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Main feature of the system',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdowns() {
    List<String> divisions = bdLocations.keys.toList();
    
    List<String> districts = [];
    if (_selectedDivision != null && bdLocations.containsKey(_selectedDivision)) {
      districts = bdLocations[_selectedDivision!]!.keys.toList();
    }
    
    List<String> upazilas = [];
    if (_selectedDistrict != null && bdLocations[_selectedDivision!]!.containsKey(_selectedDistrict)) {
      upazilas = bdLocations[_selectedDivision!]![_selectedDistrict!]!.keys.toList();
    }

    List<String> unions = [];
    if (_selectedUpazila != null && bdLocations[_selectedDivision!]![_selectedDistrict!]!.containsKey(_selectedUpazila)) {
      unions = bdLocations[_selectedDivision!]![_selectedDistrict!]![_selectedUpazila!]!;
    }

    return Column(
      children: [
        _buildSearchableDropdown(
          hint: 'Select Division',
          items: divisions,
          selectedValue: _selectedDivision,
          onChanged: (val) {
            setState(() {
              _selectedDivision = val;
              _selectedDistrict = null;
              _selectedUpazila = null;
              _selectedUnion = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildSearchableDropdown(
          hint: 'Select District',
          items: districts,
          selectedValue: _selectedDistrict,
          enabled: _selectedDivision != null,
          onChanged: (val) {
            setState(() {
              _selectedDistrict = val;
              _selectedUpazila = null;
              _selectedUnion = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildSearchableDropdown(
          hint: 'Select Upazila',
          items: upazilas,
          selectedValue: _selectedUpazila,
          enabled: _selectedDistrict != null,
          onChanged: (val) {
            setState(() {
              _selectedUpazila = val;
              _selectedUnion = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildSearchableDropdown(
          hint: 'Select Union',
          items: unions,
          selectedValue: _selectedUnion,
          enabled: _selectedUpazila != null,
          onChanged: (val) {
            setState(() {
              _selectedUnion = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String hint,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return DropdownSearch<String>(
      items: (String filter, LoadProps? loadProps) => items.where((item) => item.toLowerCase().contains(filter.toLowerCase())).toList(),
      selectedItem: selectedValue,
      onSelected: enabled ? onChanged : null,
      enabled: enabled,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: enabled ? Colors.grey : Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE62135)),
          ),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        emptyBuilder: (context, searchEntry) => const Center(
          child: Text('No data found', style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE62135)),
        ),
      ),
    );
  }

  Widget _buildTextArea(String hint) {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE62135)),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Row(
      children: [
        _buildCounterButton(Icons.remove, () {
          if (_peopleAffected > 1) {
            setState(() => _peopleAffected--);
          }
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              _peopleAffected.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildCounterButton(Icons.add, () {
          setState(() => _peopleAffected++);
        }),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }

  Widget _buildUrgencyLevel() {
    return Row(
      children: ['Critical', 'High', 'Medium'].map((level) {
        final isSelected = _urgencyLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _urgencyLevel = level),
            child: Container(
              margin: EdgeInsets.only(right: level == 'Medium' ? 0 : 8),
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE62135) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE62135) : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                level,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAidTypes() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _aidTypes.keys.map((type) {
        final isSelected = _aidTypes[type]!;
        return GestureDetector(
          onTap: () {
            setState(() {
              _aidTypes[type] = !isSelected;
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 40 - 32 - 12) / 2, // 2 items per row
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF0F0) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD3D3) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFE62135) : const Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : () async {
          final isLocationComplete = _selectedDivision != null &&
              _selectedDistrict != null &&
              _selectedUpazila != null;
          
          final isAddressFilled = _villageController.text.trim().isNotEmpty;

          if (_nameController.text.trim().isEmpty || (!isLocationComplete && !isAddressFilled)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter your Name and provide a Location (either via Auto-detect or Dropdowns).'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              )
            );
            return;
          }

          setState(() {
            _isLoading = true;
          });

          final selectedAids = _aidTypes.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();

          final customAddress = _villageController.text.trim();
          
          List<String> locationParts = [];
          if (customAddress.isNotEmpty) locationParts.add(customAddress);
          if (_selectedUnion != null) locationParts.add(_selectedUnion!);
          if (_selectedUpazila != null) locationParts.add(_selectedUpazila!);
          if (_selectedDistrict != null) locationParts.add(_selectedDistrict!);
          if (_selectedDivision != null) locationParts.add(_selectedDivision!);
          
          String finalLocation = locationParts.join(', ');

          try {
            String newRequestId = await DatabaseService().submitAidRequest(
              name: _nameController.text,
              location: finalLocation,
              affectedCount: _peopleAffected,
              urgencyLevel: _urgencyLevel,
              aidTypes: selectedAids,
            );

            if (context.mounted) {
              setState(() {
                _isLoading = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SuccessScreen(requestId: newRequestId)),
              );
            }
          } catch (e) {
            if (context.mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit request: $e')),
              );
            }
          }
        },
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Submit Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

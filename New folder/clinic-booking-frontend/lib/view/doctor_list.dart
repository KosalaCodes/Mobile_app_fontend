import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/network/dio_client.dart';
import 'Bottom_navbar.dart';
import 'doctor_profile.dart';
import 'Dashboard.dart';
import 'visits_page.dart';

// Doctor Model
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? clinicName;
  final String? imageUrl;
  final double? rating;
  final double? consultationFee;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.clinicName,
    this.imageUrl,
    this.rating,
    this.consultationFee,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Doctor',
      specialty: (json['specialty'] as String?) ?? '',
      clinicName: json['clinicName'] as String?,
      imageUrl: (json['photoUrl'] as String?) ?? (json['imageUrl'] as String?),
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : null,
      consultationFee: (json['consultationFee'] is num)
          ? (json['consultationFee'] as num).toDouble()
          : null,
    );
  }
}

class AllDoctorsPage extends StatefulWidget {
  const AllDoctorsPage({super.key, this.initialSpecialty});
  final String? initialSpecialty;

  @override
  State<AllDoctorsPage> createState() => _AllDoctorsPageState();
}

class _AllDoctorsPageState extends State<AllDoctorsPage> {
  final TextEditingController searchController = TextEditingController();
  bool isDropdownOpen = false;

  String selectedSpecialty = 'All Specialties';
  List<String> specialties = ['All Specialties'];

  List<Doctor> allDoctors = [];
  List<Doctor> filteredDoctors = [];

  bool _loading = true;
  String? _error;
  late final Dio _dio;

  int _selectedIndex = 1; // highlight "Find"

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _loadDoctors();
    searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get('/v1/doctors'); // { data: [...] }
      final list = (res.data['data'] as List<dynamic>)
          .map((e) => Doctor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final specSet = <String>{};
      for (final d in list) {
        if (d.specialty.trim().isNotEmpty) specSet.add(d.specialty.trim());
      }
      final specList = ['All Specialties', ...specSet.toList()..sort()];

      String nextSelected = 'All Specialties';
      if (widget.initialSpecialty != null &&
          specList.contains(widget.initialSpecialty)) {
        nextSelected = widget.initialSpecialty!;
      }

      setState(() {
        allDoctors = list;
        specialties = specList;
        selectedSpecialty = nextSelected;
        filteredDoctors = list;
        _loading = false;
      });

      _filterDoctors();
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error =
            e.response?.data is Map &&
                (e.response!.data as Map)['error'] != null
            ? (e.response!.data as Map)['error'].toString()
            : 'Failed to load doctors';
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to load doctors';
      });
    }
  }

  void _filterDoctors() {
    final q = searchController.text.toLowerCase();
    setState(() {
      filteredDoctors = allDoctors.where((d) {
        final matchesQuery =
            q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.specialty.toLowerCase().contains(q) ||
            (d.clinicName ?? '').toLowerCase().contains(q);
        final matchesSpec =
            selectedSpecialty == 'All Specialties' ||
            d.specialty == selectedSpecialty;
        return matchesQuery && matchesSpec;
      }).toList();
    });
  }

  void _selectSpecialty(String specialty) {
    setState(() {
      selectedSpecialty = specialty;
      isDropdownOpen = false;
    });
    _filterDoctors();
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
        break;
      case 1:
        break; // already here
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add New Page Placeholder")),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VisitsPage()),
        );
        break;
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Page Placeholder")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropMaxHeight =
        MediaQuery.of(context).size.height * 0.4; // cap dropdown height

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Doctors',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.search, "Find", 1),
            _buildCenterAddButton(2),
            _buildNavItem(Icons.calendar_today, "Visits", 3),
            _buildNavItem(Icons.person, "Profile", 4),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search doctors or specialties...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () =>
                        setState(() => isDropdownOpen = !isDropdownOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedSpecialty,
                            style: const TextStyle(fontSize: 15),
                          ),
                          Icon(
                            isDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable dropdown with bounded height (prevents overflow)
            if (isDropdownOpen)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: BoxConstraints(maxHeight: dropMaxHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: specialties.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFEFEFEF)),
                  itemBuilder: (context, i) {
                    final specialty = specialties[i];
                    final isSelected = specialty == selectedSpecialty;
                    return InkWell(
                      onTap: () => _selectSpecialty(specialty),
                      child: Container(
                        color: isSelected
                            ? const Color(0xFFE0F2F1)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              specialty,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected
                                    ? const Color(0xFF00695C)
                                    : Colors.black,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Color(0xFF00695C),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // Doctors list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : (filteredDoctors.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final d = filteredDoctors[index];
                        return _buildDoctorCard(context, d);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor d) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfilePage(
              doctorId: d.id,
              doctorName: d.name,
              specialty: d.specialty,
              clinicName: d.clinicName ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: d.imageUrl != null && d.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        d.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(Icons.person, size: 32, color: Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.specialty,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (d.rating != null) ...[
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(d.rating!.toStringAsFixed(1)),
            ],
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // Bottom nav helpers (same style as Dashboard)
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1B5E57) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1B5E57) : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1B5E57),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(int index) {
    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E57),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

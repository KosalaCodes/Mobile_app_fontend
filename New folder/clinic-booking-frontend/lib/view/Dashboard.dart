import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import 'doctor_list.dart'; // ensure this path/case matches your project
import 'patient_profile.dart';
import 'visits_page.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1B5E57),
      ),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 22))),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  String _displayName = 'User';
  StreamSubscription<User?>? _authSub;

  late final Dio _dio;

  // Header stats
  int _upcomingCount = 0;
  int _completedCount = 0;

  // Specialty counts for cards
  // keys exactly match the card titles below
  final Map<String, int> _specCounts = {
    'Cardiology': 0,
    'Neurology': 0,
    'Pediatrics': 0,
    'Eye Care': 0,
    'Orthopedics': 0,
    'General': 0,
  };

  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _dio = createDio();

    _setName(FirebaseAuth.instance.currentUser);
    _authSub = FirebaseAuth.instance.userChanges().listen((u) => _setName(u));

    _loadHeaderData();
  }

  void _setName(User? u) {
    String name = 'User';
    if (u != null) {
      final dn = u.displayName?.trim();
      if (dn != null && dn.isNotEmpty) {
        name = _titleCase(dn);
      } else if ((u.email ?? '').isNotEmpty) {
        final local = u.email!.split('@').first;
        final parts = local.split(RegExp(r'[._-]+')).where((s) => s.isNotEmpty);
        name = parts.map(_titleCase).join(' ');
        if (name.isEmpty) name = 'User';
      }
    }
    if (mounted) setState(() => _displayName = name);
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + (s.length > 1 ? s.substring(1) : '');

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadHeaderData() async {
    setState(() => _loadingStats = true);
    try {
      await Future.wait([_fetchAppointmentsCounts(), _fetchSpecialtyCounts()]);
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // GET /v1/appointments/me → compute upcoming/completed (ignoring canceled)
  Future<void> _fetchAppointmentsCounts() async {
    final res = await _dio.get('/v1/appointments/me');
    final list = (res.data['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final now = DateTime.now().millisecondsSinceEpoch;

    int upcoming = 0;
    int completed = 0;

    for (final a in list) {
      final status = (a['status'] as String?) ?? 'booked';
      if (status == 'canceled') continue;

      final endUtc = (a['endUtc'] as num).toInt();
      if (endUtc < now) {
        completed++;
      } else {
        upcoming++;
      }
    }

    if (mounted) {
      setState(() {
        _upcomingCount = upcoming;
        _completedCount = completed;
      });
    }
  }

  // GET /v1/doctors → compute counts for card specialties
  Future<void> _fetchSpecialtyCounts() async {
    final res = await _dio.get('/v1/doctors');
    final list = (res.data['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Raw counts by backend specialty
    final Map<String, int> raw = {};
    for (final d in list) {
      String spec = (d['specialty'] as String? ?? '').trim();
      if (spec.isEmpty) spec = 'General';
      raw[spec] = (raw[spec] ?? 0) + 1;
    }

    // Map backend specialties to your card categories
    // Eye Care should include Ophthalmology and "Eye Care" if present
    const Map<String, List<String>> groups = {
      'Cardiology': ['Cardiology'],
      'Neurology': ['Neurology'],
      'Pediatrics': ['Pediatrics'],
      'Eye Care': ['Ophthalmology', 'Eye Care'],
      'Orthopedics': ['Orthopedics'],
      'General': [
        'General',
        'General Medicine',
        'Family Medicine',
        'Internal Medicine',
      ],
    };

    final Map<String, int> cardCounts = {
      'Cardiology': 0,
      'Neurology': 0,
      'Pediatrics': 0,
      'Eye Care': 0,
      'Orthopedics': 0,
      'General': 0,
    };

    raw.forEach((spec, count) {
      groups.forEach((card, specs) {
        if (specs.contains(spec)) {
          cardCounts[card] = (cardCounts[card] ?? 0) + count;
        }
      });
    });

    if (mounted) {
      setState(() {
        _specCounts.addAll(cardCounts);
      });
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break; // Home - stay
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllDoctorsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PlaceholderPage(title: "Add New Page"),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VisitsPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

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

      body: RefreshIndicator(
        onRefresh: _loadHeaderData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildDashboardBody(),
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E57), Color(0xFF00695C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.black54),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Good Afternoon",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.notifications_none,
                    size: 28,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search → open Find
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllDoctorsPage()),
                  ),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: "Search doctors, symptoms, specialties...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Stats (real counts)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Upcoming",
                  _loadingStats ? "…" : _upcomingCount.toString(),
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  "Completed",
                  _loadingStats ? "…" : _completedCount.toString(),
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Specialties Section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Medical Specialties",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSpecialtyCard(
                context,
                "Cardiology",
                _loadingStats
                    ? "…"
                    : "${_specCounts['Cardiology'] ?? 0} doctors",
                Icons.favorite,
                Colors.red,
                const AllDoctorsPage(initialSpecialty: "Cardiology"),
              ),
              _buildSpecialtyCard(
                context,
                "Neurology",
                _loadingStats
                    ? "…"
                    : "${_specCounts['Neurology'] ?? 0} doctors",
                Icons.psychology,
                Colors.purple,
                const AllDoctorsPage(initialSpecialty: "Neurology"),
              ),
              _buildSpecialtyCard(
                context,
                "Pediatrics",
                _loadingStats
                    ? "…"
                    : "${_specCounts['Pediatrics'] ?? 0} doctors",
                Icons.child_care,
                Colors.pink,
                const AllDoctorsPage(initialSpecialty: "Pediatrics"),
              ),
              _buildSpecialtyCard(
                context,
                "Eye Care",
                _loadingStats ? "…" : "${_specCounts['Eye Care'] ?? 0} doctors",
                Icons.remove_red_eye,
                Colors.blue,
                const AllDoctorsPage(initialSpecialty: "Eye Care"),
              ),
              _buildSpecialtyCard(
                context,
                "Orthopedics",
                _loadingStats
                    ? "…"
                    : "${_specCounts['Orthopedics'] ?? 0} doctors",
                Icons.fitness_center,
                Colors.orange,
                const AllDoctorsPage(initialSpecialty: "Orthopedics"),
              ),
              _buildSpecialtyCard(
                context,
                "General",
                _loadingStats ? "…" : "${_specCounts['General'] ?? 0} doctors",
                Icons.medical_services,
                Colors.teal,
                const AllDoctorsPage(initialSpecialty: "General"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // === Helpers ===
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

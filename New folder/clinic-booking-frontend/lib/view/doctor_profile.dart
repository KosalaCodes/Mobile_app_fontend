import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Use your shared Dio (adds Authorization if signed in)
import '../core/network/dio_client.dart';

// Keep your existing file name for Book page import
import 'book_appoinment.dart'; // if your file is book_appointment.dart, update this import

// Optional preview entrypoint (safe to keep)
void main() {
  runApp(const DoctorProfileApp());
}

class DoctorProfileApp extends StatelessWidget {
  const DoctorProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DoctorProfilePage(
        doctorId: 'dr_sarah',
        doctorName: 'Dr. Sarah Johnson',
        specialty: 'Cardiology',
        clinicName: 'City General Hospital',
      ),
    );
  }
}

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    this.clinicName,
  });

  final String doctorId;
  final String doctorName;
  final String specialty;
  final String? clinicName;

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  late final Dio _dio;

  bool _loading = true;
  String? _error;

  // Data from backend
  String? _name;
  String? _specialty;
  String? _clinicName;
  String? _address;
  String? _bio;
  int? _yearsExp;
  int? _patientsCount;
  double? _rating;
  int? _consultationFee; // LKR
  String? _photoUrl;
  int? _nextAvailableStartUtc;
  int? _reviewsCount; // only shown if backend provides it

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get('/v1/doctors/${widget.doctorId}');
      final data = Map<String, dynamic>.from(res.data['data'] as Map);

      setState(() {
        _name = (data['name'] as String?) ?? widget.doctorName;
        _specialty = (data['specialty'] as String?) ?? widget.specialty;
        _clinicName = (data['clinicName'] as String?) ?? widget.clinicName;
        _address = data['address'] as String?;
        _bio = data['bio'] as String?;
        _yearsExp = (data['yearsExp'] as num?)?.toInt();
        _patientsCount = (data['patientsCount'] as num?)?.toInt();
        _rating = (data['rating'] as num?)?.toDouble();
        _consultationFee = (data['consultationFee'] as num?)?.toInt();
        _photoUrl = data['photoUrl'] as String?;
        _nextAvailableStartUtc = (data['nextAvailableStartUtc'] as num?)
            ?.toInt();
        _reviewsCount = (data['reviewsCount'] as num?)
            ?.toInt(); // if not present, stays null
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load profile';
      });
    }
  }

  String _formatNext(int? ms) {
    if (ms == null) return 'No upcoming slots';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final two = (int n) => n.toString().padLeft(2, '0');
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$h12:${two(dt.minute)} $ampm';
    if (isToday) return 'Today $time';
    return '${dt.month}/${dt.day}/${dt.year} $time';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _name ?? widget.doctorName;
    final specialty = _specialty ?? widget.specialty;
    final clinicName = _clinicName ?? widget.clinicName ?? '';
    final bio = _bio ?? '—';
    final yearsExp = _yearsExp?.toString() ?? '—';
    final patients = _patientsCount?.toString() ?? '—';
    final rating = _rating != null ? _rating!.toStringAsFixed(1) : '—';
    final fee = _consultationFee != null
        ? 'LKR ${_consultationFee!.toStringAsFixed(0)}'
        : '—';
    final nextAvail = _formatNext(_nextAvailableStartUtc);
    final available = _nextAvailableStartUtc != null;

    final ImageProvider avatar = (_photoUrl != null && _photoUrl!.isNotEmpty)
        ? NetworkImage(_photoUrl!)
        : const AssetImage('assets/doctor.jpg');

    final reviewsText = (_reviewsCount != null)
        ? ' ($_reviewsCount reviews)'
        : '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF00695C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(radius: 40, backgroundImage: avatar),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          (rating == '—') ? '—' : '$rating$reviewsText',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          available ? Icons.check_circle : Icons.cancel,
                          color: available
                              ? Colors.lightGreenAccent
                              : Colors.redAccent,
                        ),
                        Text(
                          available ? ' Available' : ' Unavailable',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Experience / Patients / Rating Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoCard(
                      yearsExp == '—' ? '—' : '$yearsExp+',
                      'Years Exp',
                      Icons.work,
                    ),
                    _infoCard(patients, 'Patients', Icons.people),
                    _infoCard(rating, 'Rating', Icons.star),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // About
              _sectionCard('About', bio),

              // Location
              _sectionCard(
                'Location',
                '',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinicName.isNotEmpty
                          ? clinicName +
                                (_address != null && _address!.isNotEmpty
                                    ? '\n$_address'
                                    : '')
                          : (_address ?? '—'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'Interactive map',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Get Directions',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),

              // Availability & Pricing
              _sectionCard(
                'Availability & Pricing',
                '',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.teal,
                      ),
                      title: const Text('Next Available'),
                      trailing: Text(nextAvail),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.attach_money,
                        color: Colors.teal,
                      ),
                      title: const Text('Consultation Fee'),
                      trailing: Text(fee),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Book Appointment Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: available
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookAppointmentPage(
                                doctorId: widget.doctorId,
                                doctorName: name,
                                specialty: specialty,
                                clinicName: clinicName,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Book Appointment',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Info card widget
  Widget _infoCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Section card widget
  Widget _sectionCard(String title, String description, {Widget? child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (description.isNotEmpty)
            Text(description, style: const TextStyle(fontSize: 14)),
          if (child != null) child,
        ],
      ),
    );
  }
}

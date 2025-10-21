import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'Dashboard.dart';
import 'doctor_list.dart'; // make sure this path/case matches your project
import 'patient_profile.dart';
import '../core/network/dio_client.dart';

// Model for appointments returned by backend
class _Appointment {
  final String id; // same as slotId
  final String slotId;
  final String doctorId;
  final String patientId;
  final String? patientName;
  final int startUtc;
  final int endUtc;
  final String status; // booked | canceled
  final String? notes;

  _Appointment({
    required this.id,
    required this.slotId,
    required this.doctorId,
    required this.patientId,
    this.patientName,
    required this.startUtc,
    required this.endUtc,
    required this.status,
    this.notes,
  });

  factory _Appointment.fromJson(Map<String, dynamic> j) => _Appointment(
    id: j['id'] as String,
    slotId: j['slotId'] as String? ?? j['id'] as String,
    doctorId: j['doctorId'] as String,
    patientId: j['patientId'] as String,
    patientName: j['patientName'] as String?,
    startUtc: (j['startUtc'] as num).toInt(),
    endUtc: (j['endUtc'] as num).toInt(),
    status: j['status'] as String,
    notes: j['notes'] as String?,
  );
}

// Minimal doctor info cache
class _DoctorInfo {
  final String id;
  final String name;
  final String? specialty;
  _DoctorInfo({required this.id, required this.name, this.specialty});
}

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3; // Visits selected in bottom bar

  late final Dio _dio;

  bool _loading = true;
  String? _error;

  List<_Appointment> _all = [];
  List<_Appointment> _upcoming = [];
  List<_Appointment> _completed = [];
  List<_Appointment> _canceled = [];

  final Map<String, _DoctorInfo> _doctorCache = {};

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([_fetchAppointmentsMe(), _ensureDoctorsCache()]);
      _partitionAppointments();
      setState(() {
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        final body = e.response?.data;
        _error = body is Map && body['error'] != null
            ? body['error'].toString()
            : 'Failed to load appointments';
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to load appointments';
      });
    }
  }

  Future<void> _fetchAppointmentsMe() async {
    // Call once without scope; backend returns all for current user
    final res = await _dio.get('/v1/appointments/me');
    final list = (res.data['data'] as List)
        .map((e) => _Appointment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _all = list;
  }

  Future<void> _ensureDoctorsCache() async {
    if (_doctorCache.isNotEmpty) return;
    try {
      final res = await _dio.get('/v1/doctors'); // public endpoint
      final list = (res.data['data'] as List).cast<Map>();
      for (final m in list) {
        final j = Map<String, dynamic>.from(m);
        final id = j['id'] as String;
        final name = (j['name'] as String?) ?? 'Doctor';
        final spec = j['specialty'] as String?;
        _doctorCache[id] = _DoctorInfo(id: id, name: name, specialty: spec);
      }
    } catch (_) {
      // If this fails, we still show items with doctorId
    }
  }

  void _partitionAppointments() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final up = <_Appointment>[];
    final done = <_Appointment>[];
    final cancel = <_Appointment>[];

    for (final a in _all) {
      if (a.status == 'canceled') {
        cancel.add(a);
      } else if (a.endUtc < now) {
        done.add(a);
      } else {
        up.add(a);
      }
    }

    // Sort for nicer UX
    up.sort((a, b) => a.startUtc.compareTo(b.startUtc)); // soonest first
    done.sort((a, b) => b.endUtc.compareTo(a.endUtc)); // most recent first
    cancel.sort((a, b) => b.startUtc.compareTo(a.startUtc));

    _upcoming = up;
    _completed = done;
    _canceled = cancel;
  }

  Future<void> _cancelAppointment(_Appointment appt) async {
    try {
      await _dio.delete('/v1/appointments/cancel/${appt.id}');
      // Refresh list
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment canceled')));
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = switch (code) {
        401 => 'Please sign in',
        404 => 'Appointment not found',
        400 => 'Cannot cancel past/ongoing appointment',
        403 => 'Not your appointment',
        _ => 'Cancel failed',
      };
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cancel failed')));
      }
    }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AllDoctorsPage()),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add New Page Placeholder")),
        );
        break;
      case 3:
        // already here
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientProfilePage()),
        );
        break;
    }
  }

  String _fmtRange(int startMs, int endMs) {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs).toLocal();
    final end = DateTime.fromMillisecondsSinceEpoch(endMs).toLocal();
    final two = (int n) => n.toString().padLeft(2, '0');
    String fmtTime(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:${two(dt.minute)} $ampm';
    }

    final isSameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    final dateStr = '${start.month}/${start.day}/${start.year}';
    final timeStr = isSameDay
        ? '${fmtTime(start)} – ${fmtTime(end)}'
        : '${fmtTime(start)} → ${fmtTime(end)}';
    return '$dateStr  •  $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Upcoming (${_upcoming.length})',
      'Completed (${_completed.length})',
      'Cancelled (${_canceled.length})',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // Bottom Nav
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

      body: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E57), Color(0xFF00695C)],
                begin: Alignment.topCenter,
                end: Alignment(0, 1.1),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Appointments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Tabs row (dynamic labels)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 0,
              ),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E57), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // Tab contents
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                ? _buildError(_error!)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApptList(_upcoming, showCancel: true),
                      _buildApptList(_completed),
                      _buildApptList(_canceled),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildApptList(List<_Appointment> items, {bool showCancel = false}) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.event_busy, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No items here', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (showCancel == false)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AllDoctorsPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E57),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final a = items[i];
          final d = _doctorCache[a.doctorId];
          final title = d != null ? 'Dr. ${d.name}' : 'Doctor: ${a.doctorId}';
          final subtitle = d?.specialty ?? '';
          final when = _fmtRange(a.startUtc, a.endUtc);

          IconData leadingIcon;
          Color leadingColor;
          if (a.status == 'canceled') {
            leadingIcon = Icons.cancel;
            leadingColor = Colors.redAccent;
          } else if (a.endUtc < DateTime.now().millisecondsSinceEpoch) {
            leadingIcon = Icons.check_circle;
            leadingColor = Colors.teal;
          } else {
            leadingIcon = Icons.event_available;
            leadingColor = Colors.green;
          }

          return Container(
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
            child: ListTile(
              leading: Icon(leadingIcon, color: leadingColor),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle.isNotEmpty) Text(subtitle),
                  Text(when),
                  if ((a.notes ?? '').isNotEmpty)
                    Text(
                      'Notes: ${a.notes}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: showCancel && a.status != 'canceled'
                  ? TextButton(
                      onPressed: () => _cancelAppointment(a),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // ---------- Bottom Navigation Helpers ----------
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
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

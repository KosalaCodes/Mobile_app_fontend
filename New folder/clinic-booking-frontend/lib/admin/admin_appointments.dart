import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

// Brand colors
const kPrimaryDark = Color(0xFF1B5E57);
const kPrimary = Color(0xFF00695C);

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0; // 0=All, 1=Today, 2=Upcoming

  // Sample data
  List<Appointment> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // 🔥 fetch data from backend
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final dio = Dio();
      final response = await dio.get(
        'http://localhost:8080/v1/admin/appointments',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List data = response.data;
      setState(() {
        _appointments = data.map((a) {
          DateTime dt;
          try {
            if (a['startUtc'] != null && a['startUtc'].toString().isNotEmpty) {
              dt = DateTime.parse(a['startUtc']).toLocal();
            } else {
              dt = DateTime.now();
            }
          } catch (e) {
            dt = DateTime.now();
            print('Invalid startUtc format: $e');
          }

          AppointmentStatus status;
          switch ((a['status'] ?? '').toLowerCase()) {
            case 'confirmed':
              status = AppointmentStatus.confirmed;
              break;
            case 'cancelled':
            case 'canceled':
              status = AppointmentStatus.cancelled;
              break;
            default:
              status = AppointmentStatus.pending;
          }

          return Appointment(
            patientName: a['patientName'] ?? 'Unknown',
            doctorName: a['doctorName'] ?? 'Unknown',
            specialty: a['specialty'] ?? '',
            dateTime: dt,
            status: status,
            mode: a['mode'] ?? 'in-person',
          );
        }).toList();

        _loading = false;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() => _loading = false);
    }
  }

  // Stats
  int get _todayCount {
    final now = DateTime.now();
    return _appointments.where((a) => _isSameDay(a.dateTime, now)).length;
  }

  int get _confirmedCount => _appointments
      .where((a) => a.status == AppointmentStatus.confirmed)
      .length;

  int get _pendingCount =>
      _appointments.where((a) => a.status == AppointmentStatus.pending).length;

  int get _cancelledCount => _appointments
      .where((a) => a.status == AppointmentStatus.cancelled)
      .length;

  List<Appointment> get _visible {
    final q = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return _appointments.where((a) {
      final matchesQuery =
          q.isEmpty ||
          a.patientName.toLowerCase().contains(q) ||
          a.doctorName.toLowerCase().contains(q) ||
          a.specialty.toLowerCase().contains(q) ||
          a.mode.toLowerCase().contains(q);

      bool matchesTab = true;
      if (_tabIndex == 1) {
        matchesTab = _isSameDay(a.dateTime, now);
      } else if (_tabIndex == 2) {
        final aDay = DateTime(
          a.dateTime.year,
          a.dateTime.month,
          a.dateTime.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        matchesTab = aDay.isAfter(today);
      }

      return matchesQuery && matchesTab;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final list = _visible;

    return Scaffold(
      bottomNavigationBar: const ABottomNavBar(
        selectedIndex: 2,
      ), // 0-4 for differ
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _header(),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row (responsive)
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            value: _todayCount.toString(),
                            label: 'Today',
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            value: _confirmedCount.toString(),
                            label: 'Confirmed',
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            value: _pendingCount.toString(),
                            label: 'Pending',
                            color: const Color(0xFFF9A825),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            value: _cancelledCount.toString(),
                            label: 'Cancelled',
                            color: const Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Segmented tabs
                    _SegmentedTabs(
                      index: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                      labels: const ['All', 'Today', 'Upcoming'],
                    ),
                    const SizedBox(height: 16),

                    // Appointments list
                    if (list.isEmpty)
                      _emptyState()
                    else
                      Column(
                        children: list
                            .map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AppointmentCard(appointment: a),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDark, kPrimary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage all appointments',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search appointments...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: kPrimaryDark,
                        content: Text('Filter coming soon'),
                      ),
                    );
                  },
                  icon: Icon(Icons.tune_rounded, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.event_busy, color: kPrimary, size: 40),
          SizedBox(height: 10),
          Text(
            'No appointments',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing filters or add new appointments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ===================== Models =====================
enum AppointmentStatus { confirmed, pending, cancelled }

class Appointment {
  final String patientName;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String mode; // online / in-person

  Appointment({
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.status,
    required this.mode,
  });
}

// ===================== Widgets =====================

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth - 6,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.grey[100] : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('hh:mm a');

    final statusData = _statusChip(appointment.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row (patient + status chip)
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusData.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusData.icon, size: 16, color: statusData.fg),
                    const SizedBox(width: 4),
                    Text(
                      statusData.text,
                      style: TextStyle(
                        color: statusData.fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Doctor line
          Text(
            appointment.doctorName,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            appointment.specialty,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),

          // Date + Time row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                df.format(appointment.dateTime),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.schedule, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                tf.format(appointment.dateTime),
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mode tag
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appointment.mode == 'online'
                    ? const Color(0xFFE8F0FE)
                    : const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                appointment.mode,
                style: TextStyle(
                  color: appointment.mode == 'online'
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF6A1B9A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisual _statusChip(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const _StatusVisual(
          text: 'confirmed',
          fg: Color(0xFF2E7D32),
          bg: Color(0xFFE8F5E9),
          icon: Icons.check_circle,
        );
      case AppointmentStatus.pending:
        return const _StatusVisual(
          text: 'pending',
          fg: Color(0xFFF9A825),
          bg: Color(0xFFFFF8E1),
          icon: Icons.pending,
        );
      case AppointmentStatus.cancelled:
        return const _StatusVisual(
          text: 'cancelled',
          fg: Color(0xFFD32F2F),
          bg: Color(0xFFFFEBEE),
          icon: Icons.cancel,
        );
    }
  }
}

class _StatusVisual {
  final String text;
  final Color fg;
  final Color bg;
  final IconData icon;
  const _StatusVisual({
    required this.text,
    required this.fg,
    required this.bg,
    required this.icon,
  });
}

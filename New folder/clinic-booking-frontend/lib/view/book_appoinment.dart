import 'package:clinic_booking_frontend/view/visits_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import 'package:clinic_booking_frontend/core/network/dio_client.dart';
import 'package:clinic_booking_frontend/view/payment_page.dart';

import 'Dashboard.dart';
import 'doctor_list.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.specialty,
    this.clinicName,
  });

  final String doctorId;
  final String doctorName;
  final String? specialty;
  final String? clinicName;

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  late final Dio _dio;
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  String? selectedSlotId;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  double? consultationFee;
  double? platformFee;
  double? totalAmount;
  String currency = 'LKR';

  List<_SlotVM> daySlots = [];
  bool _loadingSlots = false;
  String? _slotsError;
  bool _loadingQuote = false;
  String? _quoteError;

  // Bottom nav
  int _selectedIndex = 1; // highlight "Find" for the booking flow

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _loadSlotsForDay();
  }

  Future<void> _loadSlotsForDay() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      daySlots = [];
      selectedTime = null;
      selectedSlotId = null;
      consultationFee = null;
      platformFee = null;
      totalAmount = null;
      _quoteError = null;
    });

    try {
      final (fromUtc, toUtc) = _dayRangeUtc(selectedDate);
      final res = await _dio.get(
        '/v1/doctors/${widget.doctorId}/slots',
        queryParameters: {'from': fromUtc, 'to': toUtc},
      );
      final arr = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        daySlots = arr.map((j) => _SlotVM.fromJson(j)).toList();
        _loadingSlots = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loadingSlots = false;
        _slotsError = e.response?.data is Map
            ? ((e.response!.data as Map)['error']?.toString() ??
                  'Failed to load slots')
            : 'Failed to load slots';
      });
    } catch (_) {
      setState(() {
        _loadingSlots = false;
        _slotsError = 'Failed to load slots';
      });
    }
  }

  Future<void> _loadQuote(String slotId) async {
    setState(() {
      _loadingQuote = true;
      _quoteError = null;
      consultationFee = null;
      platformFee = null;
      totalAmount = null;
    });
    try {
      final res = await _dio.get(
        '/v1/appointments/quote',
        queryParameters: {'slotId': slotId},
      );
      final data = Map<String, dynamic>.from(res.data['data'] as Map);
      final fee = Map<String, dynamic>.from(data['fee'] as Map);
      setState(() {
        consultationFee = (fee['consultation'] as num).toDouble();
        platformFee = (fee['platform'] as num).toDouble();
        totalAmount = (fee['total'] as num).toDouble();
        currency = (fee['currency'] as String?) ?? 'LKR';
        _loadingQuote = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loadingQuote = false;
        _quoteError = e.response?.data is Map
            ? ((e.response!.data as Map)['error']?.toString() ??
                  'Failed to load quote')
            : 'Failed to load quote';
      });
    } catch (_) {
      setState(() {
        _loadingQuote = false;
        _quoteError = 'Failed to load quote';
      });
    }
  }

  (int, int) _dayRangeUtc(DateTime dayLocal) {
    final startLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final endLocal = startLocal
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return (
      startLocal.toUtc().millisecondsSinceEpoch,
      endLocal.toUtc().millisecondsSinceEpoch,
    );
  }

  String _fmtTime(int ms) => DateFormat(
    'hh:mm a',
  ).format(DateTime.fromMillisecondsSinceEpoch(ms).toLocal());

  // Bottom nav handler
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
          const SnackBar(content: Text('Add New Page Placeholder')),
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
          const SnackBar(content: Text('Profile Page Placeholder')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.specialty ?? widget.clinicName ?? '';
    final confirmEnabled =
        selectedSlotId != null && !_loadingQuote && (totalAmount ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      // Bottom navbar (same look+feel as Dashboard)
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.teal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '4.9',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date selector
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 8),
                Text(
                  'Select Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCompactCalendar(
                    selectedDate,
                    onChange: (d) {
                      setState(() => selectedDate = d);
                      _loadSlotsForDay();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Available times
            Row(
              children: const [
                Icon(Icons.access_time, size: 20),
                SizedBox(width: 8),
                Text(
                  'Available Times',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loadingSlots)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_slotsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slotsError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadSlotsForDay,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (daySlots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No available times for this date'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daySlots.map((s) {
                  final t = _fmtTime(s.startUtc);
                  final isSelected = selectedSlotId == s.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedSlotId = s.id;
                        selectedTime = t;
                      });
                      _loadQuote(s.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00695C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00695C)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Patient info
            Row(
              children: const [
                Icon(Icons.person_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Patient Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: _inputDecoration(
                'Additional Notes (Optional)',
              ).copyWith(labelText: 'Additional Notes (Optional)'),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Booking summary
            Row(
              children: const [
                Icon(Icons.receipt_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Booking Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Date & Time',
                    '${DateFormat('MM/dd/yyyy').format(selectedDate)} at ${selectedTime ?? '--:--'}',
                  ),
                  const SizedBox(height: 8),

                  if (_loadingQuote)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Loading pricing...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else if (_quoteError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _quoteError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  _summaryRow(
                    'Consultation Fee',
                    consultationFee == null
                        ? '-'
                        : '$currency ${consultationFee!.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Platform Fee',
                    platformFee == null
                        ? '-'
                        : '$currency ${platformFee!.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    'Total',
                    totalAmount == null
                        ? '-'
                        : '$currency ${totalAmount!.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (selectedSlotId != null &&
                        !_loadingQuote &&
                        (totalAmount ?? 0) > 0)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentPage(
                              doctorName: widget.doctorName,
                              specialty: widget.specialty ?? '',
                              dateTime:
                                  '${DateFormat('MM/dd/yyyy').format(selectedDate)} at ${selectedTime ?? '--:--'}',
                              totalAmount: (totalAmount ?? 0),
                              slotId: selectedSlotId!,
                              patientName: nameController.text.isNotEmpty
                                  ? nameController.text
                                  : null,
                              notes: notesController.text.isNotEmpty
                                  ? notesController.text
                                  : null,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  totalAmount == null
                      ? 'Confirm Booking'
                      : 'Confirm Booking - $currency ${totalAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact calendar
  Widget _buildCompactCalendar(
    DateTime selected, {
    required void Function(DateTime) onChange,
  }) {
    final now = DateTime.now();
    final first = DateTime(selected.year, selected.month, 1);
    final last = DateTime(selected.year, selected.month + 1, 0);
    final days = last.day;
    final startWeekday = first.weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => onChange(
                DateTime(
                  selected.year,
                  selected.month - 1,
                  selected.day.clamp(1, 28),
                ),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy').format(selected),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => onChange(
                DateTime(
                  selected.year,
                  selected.month + 1,
                  selected.day.clamp(1, 28),
                ),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
              .map(
                (d) => SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(6, (w) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final dayNumber = w * 7 + i - startWeekday + 1;
                if (dayNumber < 1 || dayNumber > days) {
                  return const SizedBox(width: 32, height: 32);
                }
                final d = DateTime(selected.year, selected.month, dayNumber);
                final isSelected =
                    d.year == selected.year &&
                    d.month == selected.month &&
                    d.day == selected.day;
                final isToday =
                    d.year == DateTime.now().year &&
                    d.month == DateTime.now().month &&
                    d.day == DateTime.now().day;

                return InkWell(
                  onTap: () => onChange(d),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00695C)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: const Color(0xFF00695C),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF00695C)),
    ),
  );

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Bottom nav helpers
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

class _SlotVM {
  final String id;
  final int startUtc;
  final int endUtc;
  _SlotVM({required this.id, required this.startUtc, required this.endUtc});
  factory _SlotVM.fromJson(Map<String, dynamic> j) => _SlotVM(
    id: j['id'] as String,
    startUtc: (j['startUtc'] as num).toInt(),
    endUtc: (j['endUtc'] as num).toInt(),
  );
}

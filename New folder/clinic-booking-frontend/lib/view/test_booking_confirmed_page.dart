import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Dashboard.dart';
import 'visits_page.dart';

class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.specialty,
    required this.startUtc,
    required this.endUtc,
    required this.currency,
    required this.consultationFee,
    required this.platformFee,
    required this.total,
    this.patientName,
    this.notes,
  });

  final String appointmentId; // same as slotId
  final String doctorName;
  final String specialty;
  final int startUtc;
  final int endUtc;
  final String currency; // e.g., 'LKR'
  final double consultationFee;
  final double platformFee;
  final double total;
  final String? patientName;
  final String? notes;

  String _fmtDT(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return DateFormat('MM/dd/yyyy • hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = _fmtDT(startUtc);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Booking Confirmed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your appointment is confirmed!',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Appointment summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _row('Doctor', doctorName),
                  const SizedBox(height: 8),
                  _row('Specialty', specialty),
                  const SizedBox(height: 8),
                  _row('Date & Time', dateTime),
                  if (patientName != null && patientName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row('Patient', patientName!),
                  ],
                  if (notes != null && notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row('Notes', notes!),
                  ],
                  const SizedBox(height: 8),
                  _row('Appointment ID', appointmentId),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    'Consultation Fee',
                    '$currency ${consultationFee.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _row(
                    'Platform Fee',
                    '$currency ${platformFee.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _row(
                    'Total',
                    '$currency ${total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const VisitsPage()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00695C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'View My Appointments',
                      style: TextStyle(
                        color: Color(0xFF00695C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Dashboard()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

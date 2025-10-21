import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:clinic_booking_frontend/core/network/dio_client.dart';
import 'test_booking_confirmed_page.dart';

class PaymentPage extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String dateTime;
  final double totalAmount;

  // Inputs from BookAppointmentPage
  final String slotId;
  final String? patientName;
  final String? notes;

  const PaymentPage({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.totalAmount,
    required this.slotId,
    this.patientName,
    this.notes,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();

  // Card fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // PayPal
  final TextEditingController paypalEmailController = TextEditingController();

  // Bank transfer
  bool _bankAgree = false;
  String? _bankError;

  String selectedMethod = "Credit/Debit Card";

  late final Dio _dio;
  bool _paying = false;
  double? _quotedTotal;
  String _currency = 'LKR';

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _loadQuote(); // confirm totals from server
  }

  @override
  void dispose() {
    nameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    paypalEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    try {
      final res = await _dio.get(
        '/v1/appointments/quote',
        queryParameters: {'slotId': widget.slotId},
      );
      final data = Map<String, dynamic>.from(res.data['data'] as Map);
      final fee = Map<String, dynamic>.from(data['fee'] as Map);
      setState(() {
        _quotedTotal = (fee['total'] as num).toDouble();
        _currency = (fee['currency'] as String?) ?? 'LKR';
      });
    } catch (_) {
      // keep UI usable
    }
  }

  Future<void> _bookAppointment() async {
    if (_paying) return;

    // Validate per method
    if (selectedMethod == 'Credit/Debit Card' || selectedMethod == 'PayPal') {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix errors before continuing')),
        );
        return;
      }
    } else if (selectedMethod == 'Bank Transfer') {
      if (!_bankAgree) {
        setState(
          () =>
              _bankError = 'Please confirm you agree to complete the transfer.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm bank transfer acknowledgement'),
          ),
        );
        return;
      }
    }

    setState(() => _paying = true);
    try {
      final res = await _dio.post(
        '/v1/appointments/book',
        data: {
          'slotId': widget.slotId,
          if (widget.notes != null && widget.notes!.isNotEmpty)
            'notes': widget.notes,
          if (widget.patientName != null && widget.patientName!.isNotEmpty)
            'patientName': widget.patientName,
        },
      );

      final appt = Map<String, dynamic>.from((res.data as Map)['data'] as Map);
      final fee = Map<String, dynamic>.from(appt['fee'] as Map);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedPage(
            appointmentId: appt['id'] as String,
            doctorName: widget.doctorName,
            specialty: widget.specialty,
            startUtc: (appt['startUtc'] as num).toInt(),
            endUtc: (appt['endUtc'] as num).toInt(),
            currency: (fee['currency'] as String? ?? 'LKR'),
            consultationFee: (fee['consultation'] as num).toDouble(),
            platformFee: (fee['platform'] as num).toDouble(),
            total: (fee['total'] as num).toDouble(),
            patientName: appt['patientName'] as String?,
            notes: appt['notes'] as String?,
          ),
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = switch (code) {
        401 => 'Please sign in to book',
        404 => 'Slot not found',
        409 => 'This slot was just booked. Pick another.',
        400 => 'Slot is no longer valid',
        _ => 'Booking failed. Please try again',
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
        ).showSnackBar(const SnackBar(content: Text('Booking failed')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _clearPaymentInputs() {
    nameController.clear();
    cardNumberController.clear();
    expiryController.clear();
    cvvController.clear();
    paypalEmailController.clear();
    _bankAgree = false;
    _bankError = null;
  }

  String _payButtonText() {
    final total = (_quotedTotal ?? widget.totalAmount).toStringAsFixed(0);
    switch (selectedMethod) {
      case 'PayPal':
        return 'Pay with PayPal $_currency $total';
      case 'Bank Transfer':
        return 'Confirm (Bank Transfer)';
      default:
        return 'Pay $_currency $total';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalLabel =
        '${_currency} ${(_quotedTotal ?? widget.totalAmount).toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Payment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Summary
            Row(
              children: const [
                Icon(Icons.receipt_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  "Appointment Summary",
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
                  _summaryRow("Doctor", widget.doctorName),
                  const SizedBox(height: 8),
                  _summaryRow("Specialty", widget.specialty),
                  const SizedBox(height: 8),
                  _summaryRow("Date & Time", widget.dateTime),
                  const Divider(height: 24),
                  _summaryRow("Total Amount", totalLabel, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method
            Row(
              children: const [
                Icon(Icons.payment, size: 20),
                SizedBox(width: 8),
                Text(
                  "Payment Method",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedMethod,
                  items: const [
                    DropdownMenuItem(
                      value: "Credit/Debit Card",
                      child: Text("Credit/Debit Card"),
                    ),
                    DropdownMenuItem(value: "PayPal", child: Text("PayPal")),
                    DropdownMenuItem(
                      value: "Bank Transfer",
                      child: Text("Bank Transfer"),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    selectedMethod = value!;
                    _clearPaymentInputs(); // clear inputs when switching method
                  }),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Method-specific fields wrapped in a Form for validation
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _buildMethodFields(),
            ),

            const SizedBox(height: 24),

            // Pay button → book + navigate to confirmation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _paying ? null : () async => _bookAppointment(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _paying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _payButtonText(),
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

  // Method-specific UI
  Widget _buildMethodFields() {
    switch (selectedMethod) {
      case 'PayPal':
        return _buildPayPalFields();
      case 'Bank Transfer':
        return _buildBankTransferFields();
      default:
        return _buildCardFields();
    }
  }

  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.credit_card, size: 20),
            SizedBox(width: 8),
            Text(
              'Card Details',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cardholder Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration("Enter your name"),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter a valid name'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                "Card Number",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cardNumberController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration("16-digit number"),
                validator: (v) {
                  final raw = (v ?? '').replaceAll(' ', '');
                  if (raw.length != 16) return 'Enter 16 digits';
                  if (!_luhnCheck(raw)) return 'Invalid card number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Expiry Date (MM/YY)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: expiryController,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDecoration("MM/YY"),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9/]'),
                            ),
                          ],
                          validator: (v) => _validateExpiry(v ?? ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CVV",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: cvvController,
                          onChanged: (_) => setState(() {}),
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _inputDecoration("3 or 4 digits"),
                          validator: (v) {
                            final raw = (v ?? '').trim();
                            if (raw.length < 3 || raw.length > 4)
                              return 'Enter 3–4 digits';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayPalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.account_balance_wallet, size: 20),
            SizedBox(width: 8),
            Text(
              'PayPal',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PayPal Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: paypalEmailController,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('you@example.com'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = (v ?? '').trim();
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                  return ok ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be redirected to PayPal (simulated). No card details required.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.account_balance, size: 20),
            SizedBox(width: 8),
            Text(
              'Bank Transfer',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bank: ABC Bank • Account: 123-456-789',
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use your name as the payment reference.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _bankAgree,
                onChanged: (v) => setState(() {
                  _bankAgree = v ?? false;
                  _bankError = null;
                }),
                title: const Text(
                  'I agree to complete the bank transfer and provide reference if requested.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_bankError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    _bankError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Validators/utils
  String? _validateExpiry(String input) {
    final s = input.trim();
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(s)) return 'Use MM/YY';
    final parts = s.split('/');
    final mm = int.tryParse(parts[0]) ?? 0;
    final yy = int.tryParse(parts[1]) ?? -1;
    if (mm < 1 || mm > 12) return 'Invalid month';
    // Interpret YY as 2000+YY (e.g., 25 -> 2025)
    final year = 2000 + yy;
    final endOfMonth = DateTime(
      year,
      mm + 1,
    ).subtract(const Duration(milliseconds: 1));
    final now = DateTime.now();
    if (endOfMonth.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Card expired';
    }
    return null;
  }

  bool _luhnCheck(String number) {
    // number contains only digits at this point
    int sum = 0;
    bool alt = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

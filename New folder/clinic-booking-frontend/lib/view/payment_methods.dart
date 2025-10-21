import 'patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:clinic_booking_frontend/core/network/dio_client.dart';
import 'package:clinic_booking_frontend/brand_colors.dart'
    hide kPrimaryDark, kPrimary;

const String mePaymentsBase = '/v1/me/payment-methods';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late final Dio _dio;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> methods = [];

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get(mePaymentsBase);
      final list = (res.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        methods = list;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = e.response?.data is Map
            ? ((e.response!.data as Map)['error']?.toString() ??
                  'Failed to load')
            : 'Failed to load';
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to load';
      });
    }
  }

  Future<void> _addMethod() async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (_) => const _AddMethodDialog(),
    );
    if (result == null) return;
    try {
      await _dio.post(
        mePaymentsBase,
        data: {'brand': result['brand'], 'last4': result['last4']},
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment method added')));
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data is Map
            ? ((e.response!.data as Map)['error']?.toString() ??
                  'Failed to add')
            : 'Failed to add';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _deleteMethod(String id) async {
    try {
      await _dio.delete('$mePaymentsBase/$id');
      setState(() => methods.removeWhere((m) => m['id'] == id));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? ((e.response!.data as Map)['error']?.toString() ?? 'Delete failed')
          : 'Delete failed';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMethod,
        backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: methods.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = methods[i];
                return ListTile(
                  leading: const Icon(Icons.credit_card, color: kPrimaryDark),
                  title: Text('${m['brand']} •••• ${m['last4']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteMethod(m['id'] as String),
                  ),
                );
              },
            ),
    );
  }
}

class _AddMethodDialog extends StatefulWidget {
  const _AddMethodDialog();

  @override
  State<_AddMethodDialog> createState() => _AddMethodDialogState();
}

class _AddMethodDialogState extends State<_AddMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _last4Ctrl = TextEditingController();

  @override
  void dispose() {
    _brandCtrl.dispose();
    _last4Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add payment method'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand (e.g., Visa)',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter brand' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _last4Ctrl,
              decoration: const InputDecoration(labelText: 'Last 4 digits'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) =>
                  (v == null || v.trim().length != 4) ? 'Enter 4 digits' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: kPrimaryDark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryDark),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop<Map<String, String>>(context, {
              'brand': _brandCtrl.text.trim(),
              'last4': _last4Ctrl.text.trim(),
            });
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

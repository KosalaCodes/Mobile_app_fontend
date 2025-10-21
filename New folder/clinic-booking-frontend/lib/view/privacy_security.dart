import 'patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:clinic_booking_frontend/core/network/dio_client.dart';

const String meBase = '/v1/me';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  late final Dio _dio;
  bool _loading = true;
  String? _error;

  bool biometric = false;
  bool twoFactor = false;

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
      final res = await _dio.get(meBase);
      final data = Map<String, dynamic>.from(res.data['data'] as Map);
      final p = Map<String, dynamic>.from((data['privacy'] as Map?) ?? {});
      setState(() {
        biometric = (p['biometric'] as bool?) ?? biometric;
        twoFactor = (p['twoFactor'] as bool?) ?? twoFactor;
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

  Future<void> _saveAll() async {
    await _dio.patch(
      meBase,
      data: {
        'privacy': {'biometric': biometric, 'twoFactor': twoFactor},
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _onToggle(String key, bool v) async {
    final prevB = biometric;
    final prevT = twoFactor;
    setState(() {
      if (key == 'biometric') biometric = v;
      if (key == 'twoFactor') twoFactor = v;
    });
    try {
      await _saveAll();
    } catch (_) {
      setState(() {
        biometric = prevB;
        twoFactor = prevT;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
      }
    }
  }

  void _changePassword() {
    // TODO: implement with your auth provider if needed
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 8),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 8),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm new password'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: kPrimaryDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy & Security'),
          backgroundColor: kPrimaryDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy & Security'),
          backgroundColor: kPrimaryDark,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Biometric login'),
            subtitle: const Text('Face ID / Fingerprint'),
            value: biometric,
            onChanged: (v) => _onToggle('biometric', v),
            activeColor: kPrimaryDark,
            activeTrackColor: kPrimary.withOpacity(0.35),
          ),
          SwitchListTile(
            title: const Text('Two-factor authentication'),
            value: twoFactor,
            onChanged: (v) => _onToggle('twoFactor', v),
            activeColor: kPrimaryDark,
            activeTrackColor: kPrimary.withOpacity(0.35),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete account is not implemented'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'patient_profile.dart'; // uses kPrimaryDark, kPrimary
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:clinic_booking_frontend/core/network/dio_client.dart';

const String meBase = '/v1/me'; // adjust if mounted differently

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final Dio _dio;
  bool _loading = true;
  String? _error;

  bool push = true;
  bool reminders = true;
  bool sound = true;
  bool email = false;

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
      final n = Map<String, dynamic>.from(
        (data['notifications'] as Map?) ?? {},
      );
      setState(() {
        push = (n['push'] as bool?) ?? push;
        reminders = (n['reminders'] as bool?) ?? reminders;
        sound = (n['sound'] as bool?) ?? sound;
        email = (n['email'] as bool?) ?? email;
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
    try {
      await _dio.patch(
        meBase,
        data: {
          'notifications': {
            'push': push,
            'reminders': reminders,
            'sound': sound,
            'email': email,
          },
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data is Map
                  ? ((e.response!.data as Map)['error']?.toString() ??
                        'Save failed')
                  : 'Save failed',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
      }
    }
  }

  Future<void> _onToggle(String key, bool v) async {
    final prev = {
      'push': push,
      'reminders': reminders,
      'sound': sound,
      'email': email,
    };
    setState(() {
      if (key == 'push') push = v;
      if (key == 'reminders') reminders = v;
      if (key == 'sound') sound = v;
      if (key == 'email') email = v;
    });
    try {
      await _saveAll();
    } catch (_) {
      // revert on failure
      setState(() {
        push = prev['push']!;
        reminders = prev['reminders']!;
        sound = prev['sound']!;
        email = prev['email']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _switchTile(
        title: 'Push notifications',
        subtitle: 'General announcements, updates',
        value: push,
        onChanged: (v) => _onToggle('push', v),
      ),
      _switchTile(
        title: 'Appointment reminders',
        subtitle: 'Reminders for upcoming visits',
        value: reminders,
        onChanged: (v) => _onToggle('reminders', v),
      ),
      _switchTile(
        title: 'Notification sounds',
        value: sound,
        onChanged: (v) => _onToggle('sound', v),
      ),
      _switchTile(
        title: 'Email notifications',
        value: email,
        onChanged: (v) => _onToggle('email', v),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
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
          : ListView(padding: const EdgeInsets.only(top: 8), children: tiles),
    );
  }

  Widget _switchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: kPrimaryDark,
      activeTrackColor: kPrimary.withOpacity(0.35),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
    );
  }
}

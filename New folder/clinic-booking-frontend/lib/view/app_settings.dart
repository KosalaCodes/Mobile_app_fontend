import 'patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:clinic_booking_frontend/core/network/dio_client.dart';

const String meBase = '/v1/me';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late final Dio _dio;
  bool _loading = true;
  String? _error;

  bool darkMode = false;
  String language = 'English';

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
      final app = Map<String, dynamic>.from((data['app'] as Map?) ?? {});
      setState(() {
        darkMode = (app['darkMode'] as bool?) ?? darkMode;
        language = (app['language'] as String?) ?? language;
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

  Future<void> _saveApp() async {
    await _dio.patch(
      meBase,
      data: {
        'app': {'darkMode': darkMode, 'language': language},
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _onToggleDark(bool v) async {
    final prev = darkMode;
    setState(() => darkMode = v);
    try {
      await _saveApp();
    } catch (_) {
      setState(() => darkMode = prev);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
      }
    }
  }

  Future<void> _onChangeLanguage(String v) async {
    final prev = language;
    setState(() => language = v);
    try {
      await _saveApp();
    } catch (_) {
      setState(() => language = prev);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('App Settings'),
          backgroundColor: kPrimaryDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('App Settings'),
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
        title: const Text('App Settings'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: darkMode,
            onChanged: _onToggleDark,
            title: const Text('Dark mode'),
            activeColor: kPrimaryDark,
            activeTrackColor: kPrimary.withOpacity(0.35),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('English'),
                        onTap: () => Navigator.pop(context, 'English'),
                      ),
                      ListTile(
                        title: const Text('Sinhala'),
                        onTap: () => Navigator.pop(context, 'Sinhala'),
                      ),
                      ListTile(
                        title: const Text('Tamil'),
                        onTap: () => Navigator.pop(context, 'Tamil'),
                      ),
                    ],
                  ),
                ),
              );
              if (result != null) _onChangeLanguage(result);
            },
          ),
        ],
      ),
    );
  }
}

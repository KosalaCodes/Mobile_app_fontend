import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_navbar.dart';

// Brand colors
const kPrimaryDark = Color(0xFF1B5E57);
const kPrimary = Color(0xFF00695C);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State (loaded from SharedPreferences)
  String _name = 'Admin User';
  String _email = 'admin@echanneling.com';
  String _role = 'Super Admin';
  String _language = 'English';

  bool _push = true;
  bool _emailNoti = true;
  bool _sms = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> _loadPrefs() async {
    final p = await _prefs;
    setState(() {
      _name = p.getString('settings_name') ?? _name;
      _email = p.getString('settings_email') ?? _email;
      _language = p.getString('settings_language') ?? _language;
      _push = p.getBool('settings_push') ?? _push;
      _emailNoti = p.getBool('settings_emailNoti') ?? _emailNoti;
      _sms = p.getBool('settings_sms') ?? _sms;

      // For demo password if not set
      p.getString('settings_password') ??
          p.setString('settings_password', 'admin123');
    });
  }

  Future<void> _savePrefs() async {
    final p = await _prefs;
    await p.setString('settings_name', _name);
    await p.setString('settings_email', _email);
    await p.setString('settings_language', _language);
    await p.setBool('settings_push', _push);
    await p.setBool('settings_emailNoti', _emailNoti);
    await p.setBool('settings_sms', _sms);
  }

  Future<void> _openProfile() async {
    final res = await Navigator.push<_ProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSettingsPage(name: _name, email: _email),
      ),
    );
    if (res != null) {
      setState(() {
        _name = res.name;
        _email = res.email;
      });
      _savePrefs();
      _toast('Profile updated');
    }
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  Future<void> _openLanguage() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => LanguagePage(current: _language)),
    );
    if (selected != null) {
      setState(() => _language = selected);
      _savePrefs();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kPrimaryDark));
  }

  void _logout() {
    // TODO: Replace with your real Sign-In page
    //  Navigator.of(context).pushAndRemoveUntil(//add to the login page
    // MaterialPageRoute(builder: (_) => const DemoSignInPage()),
    // (route) => false,
    //);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.trim().isEmpty
        ? 'A'
        : _name
              .trim()
              .split(RegExp(r'\s+'))
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase();

    return Scaffold(
      bottomNavigationBar: const ABottomNavBar(
        selectedIndex: 4,
      ), // 0-4 for differ
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryDark, kPrimary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
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
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your preferences',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal[100],
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kPrimaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _email,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _role,
                                  style: const TextStyle(
                                    color: kPrimaryDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const _SectionTitle('Account'),
                  _CardBlock(
                    children: [
                      _NavTile(
                        icon: Icons.person_outline,
                        title: 'Profile Settings',
                        onTap: _openProfile,
                      ),
                      _Divider(),
                      _NavTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: _openChangePassword,
                      ),
                      _Divider(),
                      _NavTile(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        trailing: Text(
                          _language,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: _openLanguage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle('Notifications'),
                  _CardBlock(
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_none,
                        title: 'Push Notifications',
                        value: _push,
                        onChanged: (v) {
                          setState(() => _push = v);
                          _savePrefs();
                        },
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.mail_outline,
                        title: 'Email Notifications',
                        value: _emailNoti,
                        onChanged: (v) {
                          setState(() => _emailNoti = v);
                          _savePrefs();
                        },
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.sms_outlined,
                        title: 'SMS Notifications',
                        value: _sms,
                        onChanged: (v) {
                          setState(() => _sms = v);
                          _savePrefs();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Version
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEEF0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Reusable widgets =====================

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final List<Widget> children;
  const _CardBlock({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: kPrimaryDark,
        activeTrackColor: kPrimary.withOpacity(0.35),
      ),
      onTap: () => onChanged(!value),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: kPrimaryDark),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.6, indent: 16, endIndent: 16);
  }
}

// ===================== Pages: Profile, Change Password, Language =====================

class _ProfileResult {
  final String name;
  final String email;
  const _ProfileResult(this.name, this.email);
}

class ProfileSettingsPage extends StatefulWidget {
  final String name;
  final String email;
  const ProfileSettingsPage({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_name', _nameCtrl.text.trim());
    await prefs.setString('settings_email', _emailCtrl.text.trim());
    if (!mounted) return;
    Navigator.pop(
      context,
      _ProfileResult(_nameCtrl.text.trim(), _emailCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: _dec('Full name', Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email', Icons.mail_outline),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryDark),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true, _obscureNew = true, _obscureConfirm = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final p = await SharedPreferences.getInstance();
    final stored = p.getString('settings_password') ?? 'admin123';
    if (_oldCtrl.text != stored) {
      _toast('Old password is incorrect');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _toast('New password and confirmation do not match');
      return;
    }
    await p.setString('settings_password', _newCtrl.text);
    if (!mounted) return;
    Navigator.pop(context);
    _toast('Password updated');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kPrimaryDark));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _oldCtrl,
                obscureText: _obscureOld,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter old password' : null,
                decoration: _pwdDec(
                  'Old password',
                  _obscureOld,
                  () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
                decoration: _pwdDec(
                  'New password',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Confirm password' : null,
                decoration: _pwdDec(
                  'Confirm password',
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _pwdDec(String hint, bool ob, VoidCallback toggle) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(ob ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryDark),
      ),
    );
  }
}

class LanguagePage extends StatefulWidget {
  final String current;
  const LanguagePage({super.key, required this.current});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('settings_language', _selected);
    if (!mounted) return;
    Navigator.pop(context, _selected);
  }

  @override
  Widget build(BuildContext context) {
    final options = ['English', 'Sinhala', 'Tamil'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ...options.map(
            (o) => RadioListTile<String>(
              value: o,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              title: Text(o),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Demo Sign-in (placeholder) =====================

class DemoSignInPage extends StatelessWidget {
  const DemoSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: emailCtrl,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Password'),
              controller: pwdCtrl,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              child: const Text('Sign In (Demo)'),
            ),
          ],
        ),
      ),
    );
  }
}

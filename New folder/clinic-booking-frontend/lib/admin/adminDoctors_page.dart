import 'package:flutter/material.dart';

import 'admin_navbar.dart';

// Brand colors
const kPrimaryDark = Color(0xFF1B5E57);
const kPrimary = Color(0xFF00695C);

class ManageDoctorsPage extends StatefulWidget {
  const ManageDoctorsPage({super.key});

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _filterIndex = 0; // 0=All, 1=Active, 2=Inactive

  // Add your doctors here later (kept empty for now).
  final List<Doctor> _doctors = [];

  List<Doctor> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _doctors.where((d) {
      final matchesQuery =
          q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q) ||
          (d.hospital?.toLowerCase().contains(q) ?? false);

      final matchesFilter =
          _filterIndex == 0 ||
          (_filterIndex == 1 && d.active) ||
          (_filterIndex == 2 && !d.active);

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onAddNewDoctor() {
    // bottomNavigationBar: const ABottomNavBar(
    //     selectedIndex: 1,
    //   );// 0-4 for differ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: kPrimaryDark,
        content: Text('Add New Doctor - implement form or navigation here'),
      ),
    );
  }

  void _onEditDoctor(Doctor d) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPrimaryDark,
        content: Text('Edit ${d.name} - implement editor here'),
      ),
    );
  }

  void _onDeleteDoctor(Doctor d) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete doctor?'),
        content: Text('Are you sure you want to delete ${d.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: kPrimaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _doctors.remove(d);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      bottomNavigationBar: const ABottomNavBar(
        selectedIndex: 1,
      ), // 0-4 for differ
      backgroundColor: Colors.grey[50],
      // bottomNavigationBar: _BottomNavBar(
      //   selectedIndex: 1, // Doctors tab highlighted on this page
      //   onTap: (index) {
      //     // TODO: replace with your own routing
      //     final label = [
      //       'Dashboard',
      //       'Doctors',
      //       'Appointments',
      //       'Reports',
      //       'Settings',
      //     ][index];
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         backgroundColor: kPrimaryDark,
      //         content: Text('$label tapped (wire up navigation)'),
      //       ),
      //     );
      //   },
      // ),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter chips
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterIndex == 0,
                        onTap: () => setState(() => _filterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Active',
                        selected: _filterIndex == 1,
                        onTap: () => setState(() => _filterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Inactive',
                        selected: _filterIndex == 2,
                        onTap: () => setState(() => _filterIndex = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Add new doctor button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _onAddNewDoctor,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add New Doctor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List or empty state
                  if (list.isEmpty)
                    _emptyState()
                  else
                    Column(
                      children: list
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DoctorCard(
                                doctor: d,
                                onEdit: () => _onEditDoctor(d),
                                onDelete: () => _onDeleteDoctor(d),
                              ),
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

  Widget _header(BuildContext context) {
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
        children: [
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
                      'Doctor Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage all doctors',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search box
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
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.person_search, color: kPrimary, size: 40),
          SizedBox(height: 10),
          Text('No doctors yet', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'Tap "Add New Doctor" to create your first doctor profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ===================== Models & Cards =====================

class Doctor {
  final String name;
  final String specialty;
  final String? hospital;
  final int patients;
  final double rating;
  final bool active;
  final String? photoUrl;

  Doctor({
    required this.name,
    required this.specialty,
    this.hospital,
    required this.patients,
    required this.rating,
    required this.active,
    this.photoUrl,
  });
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorCard({
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty
                      ? Image.network(
                          doctor.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarFallback(doctor.name),
                        )
                      : _avatarFallback(doctor.name),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    if (doctor.hospital != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospital!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${doctor.patients} patients',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusDot(active: doctor.active),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                icon: const Icon(Icons.more_vert, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEEEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initials = _toInitials(name);
    return Container(
      color: const Color(0xFFEAF3F1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: kPrimaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _toInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2E7D32) : Colors.redAccent;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          active ? 'active' : 'inactive',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.green[50] : Colors.white;
    final border = selected ? Colors.transparent : Colors.grey[300];

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kPrimaryDark : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ===================== Bottom Navigation (clean, aligned) =====================
// class _BottomNavBar extends StatelessWidget {
//   final int selectedIndex; // 0..4
//   final ValueChanged<int>? onTap;

//   const _BottomNavBar({required this.selectedIndex, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     final items = <_NavItemData>[
//       _NavItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
//       _NavItemData(icon: Icons.groups_outlined, label: 'Doctors'),
//       _NavItemData(icon: Icons.calendar_month_outlined, label: 'Appointments'),
//       _NavItemData(icon: Icons.bar_chart_outlined, label: 'Reports'),
//       _NavItemData(icon: Icons.settings_outlined, label: 'Settings'),
//     ];

//     return SafeArea(
//       top: false,
//       child: Container(
//         height: 72,
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 8,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: List.generate(items.length, (i) {
//             final data = items[i];
//             final selected = i == selectedIndex;
//             return Expanded(
//               child: _NavItem(
//                 data: data,
//                 selected: selected,
//                 onTap: () => onTap?.call(i),
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }

// class _NavItemData {
//   final IconData icon;
//   final String label;
//   const _NavItemData({required this.icon, required this.label});
// }

// class _NavItem extends StatelessWidget {
//   final _NavItemData data;
//   final bool selected;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.data,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const selectedBg = Color(0xFFE6F3F2); // soft teal pill behind icon
//     final iconColor = selected ? kPrimaryDark : Colors.grey[500];
//     final labelColor = selected ? kPrimaryDark : Colors.grey[600];

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center, // vertical alignment
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: selected ? selectedBg : Colors.transparent,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(data.icon, color: iconColor, size: 26),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             data.label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
//               color: labelColor,
//               height: 1.2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

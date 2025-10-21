import 'patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:clinic_booking_frontend/brand_colors.dart' hide kPrimaryDark;

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I book an appointment?',
        'a': 'Search for a doctor and tap Book Appointment.',
      },
      {
        'q': 'How can I cancel?',
        'a': 'Go to Visits > Upcoming > select appointment > Cancel.',
      },
      {
        'q': 'How do payments work?',
        'a': 'You can pay online via the Payment Methods section.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: kPrimaryDark,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final f = faqs[i];
          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            iconColor: kPrimaryDark,
            collapsedIconColor: Colors.grey[600],
            title: Text(f['q']!),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(f['a']!),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: faqs.length,
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clinic_booking_frontend/view/Dashboard.dart';
import 'package:clinic_booking_frontend/view/Signinandsignup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: ClinicApp()));
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clinic Booking',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignInAndSignUp(),
    );
  }
}

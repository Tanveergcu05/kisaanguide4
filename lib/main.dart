import 'package:flutter/material.dart';
import 'features/auth/screens/phone_input_screen.dart';

void main() {
  runApp(const KisaanGuideApp());
}

class KisaanGuideApp extends StatelessWidget {
  const KisaanGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisaanGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const PhoneInputScreen(),
    );
  }
}
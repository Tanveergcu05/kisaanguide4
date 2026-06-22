import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import 'user_details_screen.dart';
import '../home/dashboard_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void verifyOTP() async {
    String otp = _controllers.map((controller) => controller.text).join().trim();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('براہ کرم تمام 6 ہندسے درج کریں')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null && mounted) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        SharedPreferences prefs = await SharedPreferences.getInstance();

        setState(() {
          isLoading = false;
        });

        if (userDoc.exists && userDoc.data() != null) {
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()), 
              (route) => false,
            );
          }
        } else {
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const UserDetailsScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('غلط کوڈ یا تصدیق ناکام ہو گئی۔ براہ کرم دوبارہ کوشش کریں۔')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003527)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Agriculture Icon badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF003527),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(Icons.agriculture, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 32),

            // OTP Box Card widget
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'تصدیق',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003527),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ہم نے آپ کے نمبر ${widget.phoneNumber} پر کوڈ بھیجا ہے',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pin Code cells grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 42,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF003527), width: 1.8),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                               _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                               _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Actions resend template
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('کوڈ دوبارہ درخواست کر دیا گیا ہے')),
                      );
                    },
                    icon: const Icon(Icons.rotate_left, size: 18, color: Color(0xFFAC3400)),
                    label: const Text(
                      'دوبارہ کوڈ بھیجیں',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAC3400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit verification step trigger
                  ElevatedButton(
                    onPressed: isLoading ? null : verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003527),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'تصدیق اور آگے بڑھیں',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
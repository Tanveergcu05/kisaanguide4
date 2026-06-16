import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // Local storage ke liye import kiya gaya hai
import '../../core/constants/app_colors.dart';
import 'user_details_screen.dart';
// Agar dashboard screen ka path bilkul yahi hai to theek, warna sahi path set kar lijiye ga.
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
    String otp = _controllers.map((controller) => controller.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
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

      // Firebase Auth se sign in kar rahe hain
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null && mounted) {
        // Firestore mein check kar rahe hain ke user ka data pehle se hai ya nahi
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Local storage (SharedPreferences) initialize ki ja rahi hai
        SharedPreferences prefs = await SharedPreferences.getInstance();

        setState(() {
          isLoading = false;
        });

        // FIXED CONDITION LOGIC WITH LOCAL STORAGE:
        if (userDoc.exists && userDoc.data() != null) {
          // PURANA USER: Local storage me login state true save karein taake agli baar direct dashboard khule
          await prefs.setBool('isLoggedIn', true);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()), 
              (route) => false,
            );
          }
        } else {
          // NAYA USER: Agar details screen par bhi ja raha hai, tab bhi hum login state true kar dete hain 
          // taake registeration ke dauran app restart ho tab bhi user setup poora kar sake ya dashboard par ja sake
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
          const SnackBar(content: Text('Invalid OTP or Verification Failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientBottom,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 48, 177, 55), AppColors.gradientBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      width: double.infinity,
                      child: const Icon(
                        Icons.verified_user_rounded, 
                        size: 90, 
                        color: Colors.white
                      ),
                    ),
                    const SizedBox(height: 45), 
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 40, left: 30, right: 30, bottom: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Verify 6-Digit Code",
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.primaryGreen
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Sent to ${widget.phoneNumber}", 
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)
                        ),
                      ),
                      const SizedBox(height: 35),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) => _buildOTPBox(index)),
                      ),
                      
                      const SizedBox(height: 15),
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Resend OTP", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            elevation: 5,
                            shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), 
                          ),
                          child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Verify & Proceed", 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 44, 
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
      ),
    );
  }
}